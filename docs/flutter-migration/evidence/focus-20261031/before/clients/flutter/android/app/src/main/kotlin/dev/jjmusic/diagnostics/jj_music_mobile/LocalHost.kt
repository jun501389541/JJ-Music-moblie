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
    private val commands = arrayListOf<Map<String, Any>>()
    val instance = "host-${Process.myPid()}-${SystemClock.elapsedRealtime()}"
    var revoked = false
    var launchMode = ""
    var launchToken = ""
    private var failNextPlay = false
    var session: android.media.session.MediaSession? = null
    private var focus: AudioFocusRequest? = null
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
                    "proof" -> android.util.Log.i("JJOwnedProbe", call.argument<String>("json") ?: "{}")
                    "prepare" -> {
                        check(players.size < 2 && id != null && !players.containsKey(id))
                        val uri = Uri.parse(call.argument<String>("path")!!)
                        val ownFile = uri.scheme == "file" && (File(uri.path!!).canonicalPath.startsWith(context.cacheDir.canonicalPath + "/") || File(uri.path!!).canonicalPath.startsWith(context.codeCacheDir.canonicalPath + "/"))
                        val ownContent = uri.scheme == "content" && uri.authority == "${context.packageName}.fixture"
                        check(ownFile || ownContent) { "only-owned-fixtures" }
                        val player = ExoPlayer.Builder(context).build()
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
                        requestFocus()
                        val intent = Intent(context, PlaybackService::class.java)
                        context.startForegroundService(intent)
                        players.getValue(id!!).play()
                    }
                    "pause" -> players.values.forEach { it.pause() }
                    "failNextPlay" -> failNextPlay=true
                    "stop" -> {
                        players.values.forEach { it.stop() }
                        context.stopService(Intent(context, PlaybackService::class.java))
                        focus?.let { (context.getSystemService(Context.AUDIO_SERVICE) as AudioManager).abandonAudioFocusRequest(it) }
                    }
                    "seek" -> players.getValue(id!!).seekTo(call.argument<Number>("position")!!.toLong())
                    "release" -> {
                        players.remove(id)?.release(); timeline("released-$id")
                        if (players.isEmpty()) context.stopService(Intent(context, PlaybackService::class.java))
                    }
                    "fixtureUri" -> {
                        val target = File(context.cacheDir, "owned-tone-long.wav")
                        context.assets.open("flutter_assets/fixtures/local_playback/tone-long.wav").use { source -> target.outputStream().use { source.copyTo(it) } }
                        result.success("content://${context.packageName}.fixture/tone-long"); return@setMethodCallHandler
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
                            "position" to p.currentPosition, "duration" to if (p.duration == C.TIME_UNSET) 0L else p.duration,
                            "ended" to (p.playbackState == Player.STATE_ENDED), "error" to (p.playerError != null)) }
                        result.success(mapOf("samples" to samples, "commands" to commands.toList(), "lifecycle" to life.toList(), "host" to instance, "pid" to Process.myPid(), "screenInteractive" to (context.getSystemService(Context.POWER_SERVICE) as android.os.PowerManager).isInteractive))
                        commands.clear(); return@setMethodCallHandler
                    }
                    else -> { result.notImplemented(); return@setMethodCallHandler }
                }
                result.success(null)
            } catch (e: Exception) { result.error("android-local", e.javaClass.simpleName, null) }
        }
        engine.dartExecutor.executeDartEntrypoint(DartExecutor.DartEntrypoint.createDefault())
        timeline("engine-create")
        return engine
    }
    private fun requestFocus() {
        val manager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
        if (focus == null) focus = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN)
            .setAudioAttributes(SystemAudioAttributes.Builder().setUsage(SystemAudioAttributes.USAGE_MEDIA).build())
            .setOnAudioFocusChangeListener { change ->
                // Safety suppress immediately, business paused intent goes through Dart.
                if (change < 0) { players.values.forEach { it.pause() }; command("pause"); timeline("focus-$change") }
            }.build()
        check(manager.requestAudioFocus(focus!!) == AudioManager.AUDIOFOCUS_REQUEST_GRANTED) { "focus-denied" }
    }
}
