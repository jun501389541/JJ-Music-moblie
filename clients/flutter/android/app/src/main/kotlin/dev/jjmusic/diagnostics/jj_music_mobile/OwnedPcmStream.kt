package dev.jjmusic.diagnostics.jj_music_mobile

import android.content.Context
import android.net.Uri
import androidx.media3.common.C
import androidx.media3.common.Format
import androidx.media3.common.MimeTypes
import androidx.media3.common.util.ParsableByteArray
import androidx.media3.datasource.BaseDataSource
import androidx.media3.datasource.DataSpec
import androidx.media3.extractor.*
import java.io.DataInputStream
import java.io.InputStream
import java.io.IOException

/** Bounded diagnostic metrics, not filesystem/OS-handle inspection. */
class OwnedPcmState {
    private var opens = 0
    private var closes = 0
    private var closeErrors = 0
    private var active = 0
    private var bytesRead = 0L
    @Synchronized fun opened() { opens++; active++ }
    @Synchronized fun read(count: Int) { bytesRead += count }
    @Synchronized fun closed() { closes++; active-- }
    @Synchronized fun closeFailed() { closeErrors++ }
    @Synchronized fun snapshot(): Map<String, Any> = mapOf(
        "opens" to opens, "closes" to closes, "closeErrors" to closeErrors,
        "active" to active, "bytesRead" to bytesRead, "declaredLength" to C.LENGTH_UNSET)
}

/** Only headerless samples of the frozen owned fixture; no general file support. */
class OwnedPcmDataSource(private val context: Context, private val state: OwnedPcmState) : BaseDataSource(false) {
    private var input: InputStream? = null
    private var uri: Uri? = null
    override fun open(dataSpec: DataSpec): Long {
        if (input != null || dataSpec.position != 0L || dataSpec.length != C.LENGTH_UNSET.toLong() ||
            dataSpec.uri.scheme != "content" || dataSpec.uri.authority != "${context.packageName}.fixture" ||
            dataSpec.uri.path != "/tone-pcm") throw IOException("owned-pcm-sequential-only")
        transferInitializing(dataSpec)
        val candidate = context.assets.open("flutter_assets/fixtures/local_playback/tone-long.wav")
        try {
            val header = ByteArray(44)
            DataInputStream(candidate).readFully(header)
            val canonical = byteArrayOf(1,0,1,0,128.toByte(),62,0,0,0,125,0,0,2,0,16,0)
            if (String(header,0,4,Charsets.US_ASCII) != "RIFF" ||
                String(header,8,4,Charsets.US_ASCII) != "WAVE" ||
                String(header,12,4,Charsets.US_ASCII) != "fmt " || header[16] != 16.toByte() ||
                !header.copyOfRange(20,36).contentEquals(canonical) ||
                String(header,36,4,Charsets.US_ASCII) != "data") throw IOException("owned-pcm-format")
            // Header/length never reach the extractor. Only real EOF ends it.
            input = candidate; uri = dataSpec.uri
            state.opened(); transferStarted(dataSpec)
            return C.LENGTH_UNSET.toLong()
        } catch (e: Exception) { candidate.close(); input = null; uri = null; throw e }
    }
    override fun read(buffer: ByteArray, offset: Int, length: Int): Int {
        if (length == 0) return 0
        val count = (input ?: throw IOException("owned-pcm-closed")).read(buffer, offset, length)
        if (count > 0) { state.read(count); bytesTransferred(count) }
        return count
    }
    override fun getUri(): Uri? = uri
    override fun close() {
        val current = input ?: return
        input = null; uri = null
        try { current.close(); state.closed() }
        catch (e: IOException) { state.closeFailed(); throw e }
        finally { transferEnded() }
    }
}

/** PCM framing for the existing Media3 renderer. No decoder/queue/retry policy. */
class OwnedPcmExtractor : Extractor {
    private lateinit var track: TrackOutput
    private val sample = ByteArray(3200)
    private var filled = 0
    private var bytesEmitted = 0L
    override fun sniff(input: ExtractorInput) = true // Factory only for /tone-pcm.
    override fun init(output: ExtractorOutput) {
        track = output.track(0, C.TRACK_TYPE_AUDIO)
        track.format(Format.Builder().setSampleMimeType(MimeTypes.AUDIO_RAW)
            .setSampleRate(16000).setChannelCount(1).setPcmEncoding(C.ENCODING_PCM_16BIT).build())
        output.endTracks()
        output.seekMap(SeekMap.Unseekable(C.TIME_UNSET))
    }
    override fun read(input: ExtractorInput, seekPosition: PositionHolder): Int {
        val count = input.read(sample, filled, sample.size - filled)
        if (count == C.RESULT_END_OF_INPUT) {
            if (filled > 0) emitSample()
            return Extractor.RESULT_END_OF_INPUT
        }
        filled += count
        if (filled == sample.size) emitSample()
        return Extractor.RESULT_CONTINUE
    }
    private fun emitSample() {
        if (filled % 2 != 0) throw IOException("owned-pcm-partial-frame")
        track.sampleData(ParsableByteArray(sample), filled)
        track.sampleMetadata(bytesEmitted * 1000000L / 32000L, C.BUFFER_FLAG_KEY_FRAME, filled, 0, null)
        bytesEmitted += filled; filled = 0
    }
    override fun seek(position: Long, timeUs: Long) {
        if (position != 0L || timeUs != 0L) throw IllegalArgumentException("owned-pcm-unseekable")
        filled = 0; bytesEmitted = 0
    }
    override fun release() { filled = 0 }
}
