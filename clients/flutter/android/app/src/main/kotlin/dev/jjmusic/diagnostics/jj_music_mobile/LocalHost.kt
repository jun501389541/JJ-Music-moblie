package dev.jjmusic.diagnostics.jj_music_mobile

import android.content.Context
import android.content.Intent
import android.media.AudioManager
import android.media.AudioFocusRequest
import android.media.AudioAttributes as SystemAudioAttributes
import android.net.Uri
import android.os.Process
import android.os.SystemClock
import androidx.media3.common.MediaItem
import androidx.media3.common.Player
import androidx.media3.common.AudioAttributes
import androidx.media3.common.C
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.DefaultLoadControl
import androidx.media3.datasource.DataSource
import androidx.media3.datasource.DefaultDataSource
import androidx.media3.exoplayer.source.DefaultMediaSourceFactory
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import java.io.File

/** One process host. No native queue, retry, shuffle or playback business state. */
object LocalHost {
    private var cached: FlutterEngine? = null
    var activity: MainActivity? = null
    lateinit var context: Context
    private val players = linkedMapOf<String, ExoPlayer>()
    private val readGates = linkedMapOf<String, OwnedReadGate>()
    private val pcmStreams = linkedMapOf<String, OwnedPcmState>()
    private val commands = arrayListOf<Map<String, Any>>()
    val instance = "host-${Process.myPid()}-${SystemClock.elapsedRealtime()}"
    var revoked = false
    var launchMode = ""
    var launchToken = ""
    private var failNextPlay = false
    var session: android.media.session.MediaSession? = null
    private var focus: AudioFocusRequest? = null
    private var focusProbe: AudioFocusRequest? = null
    private var focusEpoch = 0L
    private var pendingServiceStarts = 0
    private var serviceRegistrationRequested = false
    private var activeTransportRevision = 0L
    private var currentService: PlaybackService? = null
    private var pendingSafetyPause: Map<String, Any>? = null
    private var lastNativeFailure = ""
    private var capturedFocusCallback: ((Int) -> Unit)? = null
    private var currentFocusCallback: ((Int) -> Unit)? = null
    private val life = arrayListOf<Map<String, Any>>()
    fun timeline(event: String) {
        if (life.size >= 60) life.removeAt(0)
        life.add(mapOf("event" to event, "time" to SystemClock.elapsedRealtime(),
            "pid" to Process.myPid(), "host" to instance,
            "engine" to (cached?.hashCode() ?: 0), "activity" to (activity?.hashCode() ?: 0)))
    }
    fun command(name: String, position: Long = 0) {
        if (commands.size < 32) commands.add(mapOf("command" to name, "position" to position))
    }
    fun engine(input: Context): FlutterEngine {
        cached?.let { return it }
        context = input.applicationContext
        val engine = FlutterEngine(context)
        cached = engine
        MethodChannel(engine.dartExecutor.binaryMessenger, "jj_music/local").setMethodCallHandler { call, result ->
            try {
                val id = call.argument<String>("id")
                when (call.method) {
                    "launchMode" -> { result.success(launchMode); return@setMethodCallHandler }
                    "launchToken" -> { result.success(launchToken); return@setMethodCallHandler }
                    "diagnosticScreen" -> {
                        if (call.argument<Boolean>("keepOn") == true) activity?.window?.addFlags(android.view.WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                        else activity?.window?.clearFlags(android.view.WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                        result.success((context.getSystemService(Context.POWER_SERVICE) as android.os.PowerManager).isInteractive)
                        return@setMethodCallHandler
                    }
                    "diagnosticForeground" -> {
                        val interactive = (context.getSystemService(Context.POWER_SERVICE) as android.os.PowerManager).isInteractive
                        val locked = (context.getSystemService(Context.KEYGUARD_SERVICE) as android.app.KeyguardManager).isKeyguardLocked
                        result.success(interactive && !locked && activity?.hasWindowFocus() == true)
                        return@setMethodCallHandler
                    }
                    "proof" -> android.util.Log.i("JJOwnedProbe", call.argument<String>("json") ?: "{}")
                    "prepare" -> {
                        lastNativeFailure = ""
                        check(players.size < 2 && id != null && !players.containsKey(id))
                        val uri = Uri.parse(call.argument<String>("path")!!)
                        val ownFile = uri.scheme == "file" && (File(uri.path!!).canonicalPath.startsWith(context.cacheDir.canonicalPath + "/") || File(uri.path!!).canonicalPath.startsWith(context.codeCacheDir.canonicalPath + "/"))
                        val ownContent = uri.scheme == "content" && uri.authority == "${context.packageName}.fixture"
                        check(ownFile || ownContent) { "only-owned-fixtures" }
                        val gateMode = uri.getQueryParameter("gate")
                        val rebuffer = ownContent && gateMode == "rebuffer"
                        val gated = ownContent && (gateMode == "initial" || rebuffer)
                        val rawPcm = ownContent && uri.path == "/tone-pcm"
                        val builder = ExoPlayer.Builder(context)
                        if (rawPcm) {
                            check(!gated)
                            if (pcmStreams.size >= 8 && !pcmStreams.containsKey(id)) {
                                val old = pcmStreams.keys.firstOrNull { !players.containsKey(it) }
                                check(old != null) { "owned-pcm-history-full" }
                                pcmStreams.remove(old)
                            }
                            val stream = OwnedPcmState()
                            pcmStreams[id] = stream
                            if (readGates.size >= 8 && !readGates.containsKey(id)) {
                                val old = readGates.keys.firstOrNull { !players.containsKey(it) }
                                check(old != null) { "owned-gate-history-full" }
                                readGates.remove(old)
                            }
                            // Prevent EOF-derived duration before first proof.
                            val gate = OwnedReadGate(64000)
                            readGates[id] = gate
                            builder.setLoadControl(DefaultLoadControl.Builder()
                                .setBufferDurationsMs(500, 1000, 250, 250).build())
                            builder.setMediaSourceFactory(DefaultMediaSourceFactory(
                                DataSource.Factory { gate.wrap(OwnedPcmDataSource(context, stream)) },
                                androidx.media3.extractor.ExtractorsFactory { arrayOf(OwnedPcmExtractor()) }))
                        } else if (gated) {
                            pcmStreams.remove(id)
                            // Only the explicit owned fixture can select the gate.
                            check(uri.path == "/tone-long")
                            // Frozen PCM16 mono/16kHz fixture: header + 2s.
                            val gate = OwnedReadGate(if (rebuffer) 64044L else 0L)
                            if (rebuffer) {
                                // Diagnostic-only, not ordinary playback tuning.
                                builder.setLoadControl(DefaultLoadControl.Builder()
                                    .setBufferDurationsMs(500, 1000, 250, 250).build())
                            }
                            readGates.remove(id)
                            if (readGates.size >= 8) {
                                val old = readGates.keys.firstOrNull { !players.containsKey(it) }
                                check(old != null) { "owned-gate-history-full" }
                                readGates.remove(old)
                            }
                            readGates[id] = gate
                            val upstream = DefaultDataSource.Factory(context)
                            builder.setMediaSourceFactory(DefaultMediaSourceFactory(context)
                                .setDataSourceFactory(DataSource.Factory { gate.wrap(upstream.createDataSource()) }))
                        } else {
                            readGates.remove(id)
                            pcmStreams.remove(id)
                        }
                        val player = builder.build()
                        player.setAudioAttributes(AudioAttributes.Builder().setUsage(C.USAGE_MEDIA).setContentType(C.AUDIO_CONTENT_TYPE_MUSIC).build(), false)
                        player.repeatMode = Player.REPEAT_MODE_OFF
                        player.shuffleModeEnabled = false
                        player.volume = 0.35f
                        players[id] = player
                        player.setMediaItem(MediaItem.fromUri(uri)); player.prepare()
                        timeline("prepare-$id")
                    }
                    "play" -> {
                        // Hard switch only; old physical resource is closed by shared release.
                        players.filterKeys { it != id }.values.forEach { it.pause() }
                        if (failNextPlay) { failNextPlay=false; error("owned-injected-play-failure") }
                        activeTransportRevision = call.argument<Number>("transportRevision")!!.toLong()
                        startPlaybackService()
                        try {
                            requestFocus(call.argument<Number>("transportRevision")!!.toLong())
                            players.getValue(id!!).play()
                        } catch (e: Exception) {
                            abandonFocus()
                            stopPlaybackService()
                            throw e
                        }
                    }
                    "pause" -> {
                        players.values.forEach { it.pause() }
                        abandonFocus()
                    }
                    "failNextPlay" -> failNextPlay=true
                    // Owned diagnostic focus contender. Requests actual OS focus,
                    // emits no sound and never changes device/global settings.
                    "focusProbe" -> {
                        check(focusProbe == null) { "probe-already-active" }
                        val manager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
                        val probe = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT)
                            .setAudioAttributes(SystemAudioAttributes.Builder().setUsage(SystemAudioAttributes.USAGE_MEDIA).build())
                            .setOnAudioFocusChangeListener { change -> timeline("probe-focus-$change") }.build()
                        val granted = manager.requestAudioFocus(probe) == AudioManager.AUDIOFOCUS_REQUEST_GRANTED
                        if (granted) focusProbe = probe
                        result.success(granted); return@setMethodCallHandler
                    }
                    "releaseFocusProbe" -> {
                        focusProbe?.let { (context.getSystemService(Context.AUDIO_SERVICE) as AudioManager).abandonAudioFocusRequest(it) }
                        focusProbe = null
                    }
                    // Explicit fault injection, NOT an OS focus event. Retains
                    // only one callback for a stale-listener regression test.
                    "captureFocusCallback" -> capturedFocusCallback = currentFocusCallback
                    "deliverCapturedFocusLoss" -> {
                        val callback = capturedFocusCallback ?: error("no-captured-callback")
                        capturedFocusCallback = null
                        callback(AudioManager.AUDIOFOCUS_LOSS)
                    }
                    "stop" -> {
                        players.values.forEach { it.stop() }
                        stopPlaybackService()
                        abandonFocus()
                    }
                    "seek" -> {
                        val player = players.getValue(id!!)
                        if (!player.isCurrentMediaItemSeekable) throw UnsupportedOperationException("seek-unsupported")
                        player.seekTo(call.argument<Number>("position")!!.toLong())
                    }
                    "release" -> {
                        readGates[id]?.cancel()
                        players.remove(id)?.release(); timeline("released-$id")
                        if (players.isEmpty()) {
                            abandonFocus()
                            stopPlaybackService()
                        }
                    }
                    "unknownPcmFixtureUri" -> {
                        result.success("content://${context.packageName}.fixture/tone-pcm")
                        return@setMethodCallHandler
                    }
                    "fixtureUri", "gatedFixtureUri", "rebufferFixtureUri" -> {
                        val target = File(context.cacheDir, "owned-tone-long.wav")
                        context.assets.open("flutter_assets/fixtures/local_playback/tone-long.wav").use { source -> target.outputStream().use { source.copyTo(it) } }
                        val query = when (call.method) {
                            "gatedFixtureUri" -> "?gate=initial"
                            "rebufferFixtureUri" -> "?gate=rebuffer"
                            else -> ""
                        }
                        result.success("content://${context.packageName}.fixture/tone-long$query"); return@setMethodCallHandler
                    }
                    "allowOwnedRead" -> readGates[id]?.allow()
                    "serviceRegistrationProbe" -> {
                        repeat(3) { startPlaybackService() }
                        stopPlaybackService()
                    }
                    // Explicit lifecycle probe: real Service.onDestroy, not an
                    // OS eviction/process-kill simulation or a transport stop.
                    "destroyServiceProbe" -> {
                        result.success(context.stopService(Intent(context, PlaybackService::class.java)))
                        return@setMethodCallHandler
                    }
                    "restartServiceProbe" -> {
                        stopPlaybackService()
                        startPlaybackService()
                    }
                    "destroyServiceFullQueueProbe" -> {
                        repeat(32) { command("seek", 3000) }
                        result.success(context.stopService(Intent(context, PlaybackService::class.java)))
                        return@setMethodCallHandler
                    }
                    "revokeFixture" -> revoked = call.argument<Boolean>("revoked") == true
                    "recreateActivity" -> activity?.recreate()
                    "backgroundActivity" -> activity?.moveTaskToBack(true)
                    "showActivity" -> context.startActivity(Intent(context, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP))
                    "osCommand" -> {
                        val controls = session?.controller?.transportControls ?: error("no-session")
                        when (call.argument<String>("command")) {
                            "pause" -> controls.pause()
                            "play" -> controls.play()
                            "seek" -> controls.seekTo(3000)
                            "next" -> controls.skipToNext()
                            "stop" -> controls.stop()
                        }
                    }
                    "mirror" -> {
                        val status = call.argument<String>("status")
                        val state = if (status == "playing") android.media.session.PlaybackState.STATE_PLAYING else if (status == "paused") android.media.session.PlaybackState.STATE_PAUSED else android.media.session.PlaybackState.STATE_STOPPED
                        session?.setPlaybackState(android.media.session.PlaybackState.Builder()
                            .setActions(android.media.session.PlaybackState.ACTION_PLAY or android.media.session.PlaybackState.ACTION_PAUSE or android.media.session.PlaybackState.ACTION_STOP or android.media.session.PlaybackState.ACTION_SEEK_TO or android.media.session.PlaybackState.ACTION_SKIP_TO_NEXT or android.media.session.PlaybackState.ACTION_SKIP_TO_PREVIOUS)
                            .setState(state, call.argument<Number>("position")!!.toLong(), if (state == android.media.session.PlaybackState.STATE_PLAYING) 1f else 0f).build())
                        session?.setMetadata(android.media.MediaMetadata.Builder()
                            .putString(android.media.MediaMetadata.METADATA_KEY_TITLE, call.argument<String>("title"))
                            .putLong(android.media.MediaMetadata.METADATA_KEY_DURATION, call.argument<Number>("duration")!!.toLong()).build())
                    }
                    "poll" -> {
                        val samples = players.map { (key, p) -> mapOf(
                            "id" to key, "platform" to "android", "state" to p.playbackState,
                            "ready" to (p.playbackState == Player.STATE_READY), "nativePlaying" to p.isPlaying,
                            "playWhenReady" to p.playWhenReady, "suppression" to p.playbackSuppressionReason,
                            "canSeek" to p.isCurrentMediaItemSeekable, "nativeDuration" to p.duration,
                            "position" to p.currentPosition, "duration" to if (p.duration == C.TIME_UNSET) 0L else p.duration,
                            "ended" to (p.playbackState == Player.STATE_ENDED), "error" to (p.playerError != null)) }
                        // Safety pause has a bounded independent slot; a full
                        // ordinary-command queue must not lose service loss.
                        val allCommands = commands.toList() + listOfNotNull(pendingSafetyPause)
                        val validCommands = allCommands.filter { it["focusEpoch"] == null || it["focusEpoch"] == focusEpoch }
                        result.success(mapOf("samples" to samples, "commands" to validCommands, "lifecycle" to life.toList(), "host" to instance, "pid" to Process.myPid(), "focusHeld" to (focus != null), "focusEpoch" to focusEpoch, "readGates" to readGates.mapValues { it.value.snapshot() }, "pcmStreams" to pcmStreams.mapValues { it.value.snapshot() }, "pendingServiceStarts" to pendingServiceStarts, "servicePresent" to (session != null), "lastNativeError" to lastNativeFailure, "screenInteractive" to (context.getSystemService(Context.POWER_SERVICE) as android.os.PowerManager).isInteractive))
                        commands.clear(); pendingSafetyPause = null; return@setMethodCallHandler
                    }
                    else -> { result.notImplemented(); return@setMethodCallHandler }
                }
                result.success(null)
            } catch (e: Exception) {
                // Whitelisted stage/class, never dump paths, URIs or sources.
                lastNativeFailure = "${call.method}:${e.javaClass.simpleName}" + if (e.message == "focus-denied") ":focus-denied" else ""
                result.error("android-local", e.javaClass.simpleName, null)
            }
        }
        engine.dartExecutor.executeDartEntrypoint(DartExecutor.DartEntrypoint.createDefault())
        timeline("engine-create")
        return engine
    }
    private fun startPlaybackService() {
        // Registration bookkeeping only; playback intent remains in Dart.
        serviceRegistrationRequested = true
        pendingServiceStarts++
        try {
            context.startForegroundService(Intent(context, PlaybackService::class.java))
        } catch (e: Exception) {
            pendingServiceStarts--
            serviceRegistrationRequested = false
            throw e
        }
    }
    private fun stopPlaybackService() {
        serviceRegistrationRequested = false
        // Never tear down a just-requested FGS before it has promoted itself.
        if (pendingServiceStarts == 0) {
            currentService?.expectStop()
            context.stopService(Intent(context, PlaybackService::class.java))
        }
    }
    fun serviceCreated(service: PlaybackService) { currentService = service }
    fun serviceStartAcknowledged(service: PlaybackService, startId: Int) {
        if (pendingServiceStarts > 0) pendingServiceStarts--
        timeline("service-start-ack")
        if (pendingServiceStarts == 0 && !serviceRegistrationRequested) {
            service.expectStop()
            service.stopSelf(startId)
        }
    }
    fun serviceDestroyed(service: PlaybackService) {
        // An explicit transport Stop/release already owns its desired state.
        // Only an unrequested service loss needs this safety pause. It is NOT
        // an OS audio-focus callback and never restarts a service or playback.
        if (currentService !== service) return
        currentService = null
        // Expected stop belongs to THIS instance, not the latest start request.
        // A newer registration may already be waiting for its own onCreate.
        if (service.expectedStop) return
        serviceRegistrationRequested = false
        players.values.forEach { it.pause() }
        abandonFocus()
        if (players.isNotEmpty()) pendingSafetyPause = mapOf(
            "command" to "pause", "position" to 0L,
            // Reuse the existing focus/transport fence: a newer intent or
            // focus request invalidates this queued physical-safety command.
            "focusEpoch" to focusEpoch, "transportRevision" to activeTransportRevision,
            "cause" to "service-destroy")
        timeline("service-loss-paused")
    }
    private fun requestFocus(transportRevision: Long) {
        // A fresh request fences callbacks belonging to a released/paused track.
        abandonFocus()
        val manager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
        val epoch = ++focusEpoch
        lateinit var request: AudioFocusRequest
        var lossDelivered = false
        val callback: (Int) -> Unit = { change ->
            if (focus !== request || focusEpoch != epoch) {
                timeline("focus-stale-ignored")
            } else if (change < 0 && !lossDelivered) {
                lossDelivered = true
                // Immediate physical safety; shared Dart remains the only
                // authority that commits the paused intent. Gain never plays.
                players.values.forEach { it.pause() }
                if (commands.size < 32) commands.add(mapOf("command" to "pause", "position" to 0L, "focusEpoch" to epoch, "transportRevision" to transportRevision))
                timeline("focus-$change")
            }
        }
        request = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN)
            .setAudioAttributes(SystemAudioAttributes.Builder().setUsage(SystemAudioAttributes.USAGE_MEDIA).build())
            .setOnAudioFocusChangeListener(callback, android.os.Handler(android.os.Looper.getMainLooper())).build()
        focus = request
        currentFocusCallback = callback
        if (manager.requestAudioFocus(request) != AudioManager.AUDIOFOCUS_REQUEST_GRANTED) {
            abandonFocus()
            error("focus-denied")
        }
        timeline("focus-acquired")
    }
    private fun abandonFocus() {
        val previous = focus
        // Invalidate before calling the OS, which may schedule a late callback.
        focus = null
        currentFocusCallback = null
        ++focusEpoch
        if (previous != null) {
            (context.getSystemService(Context.AUDIO_SERVICE) as AudioManager).abandonAudioFocusRequest(previous)
            timeline("focus-abandoned")
        }
    }
}

