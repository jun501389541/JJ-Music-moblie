package dev.jjmusic.diagnostics.jj_music_mobile

import android.os.SystemClock
import androidx.media3.datasource.DataSource
import androidx.media3.datasource.DataSpec
import java.io.InterruptedIOException

/** Test-only local byte-read gate. Never blocks the platform/control thread. */
class OwnedReadGate {
    private val lock = Object()
    private var allowed = false
    private var cancelled = false
    private var waiting = 0
    private var readers = 0
    private var closes = 0
    private var bytesRead = 0L
    private var waitedMs = 0L

    fun allow() = synchronized(lock) {
        if (!cancelled) allowed = true
        lock.notifyAll()
    }
    fun cancel() = synchronized(lock) {
        cancelled = true
        lock.notifyAll()
    }
    fun snapshot(): Map<String, Any> = synchronized(lock) {
        mapOf("blocked" to (waiting > 0), "readers" to readers,
            "closed" to (closes > 0 && readers == 0), "cancelled" to cancelled,
            "bytesRead" to bytesRead, "waitedMs" to waitedMs)
    }
    fun wrap(upstream: DataSource): DataSource = object : DataSource by upstream {
        private var opened = false
        override fun open(dataSpec: DataSpec): Long {
            val length = upstream.open(dataSpec)
            synchronized(lock) { readers++; opened = true }
            return length
        }
        override fun read(buffer: ByteArray, offset: Int, length: Int): Int {
            if (length == 0) return 0
            synchronized(lock) {
                val started = SystemClock.elapsedRealtime()
                val deadline = started + 15000
                waiting++
                try {
                    while (!allowed && !cancelled) {
                        val remaining = deadline - SystemClock.elapsedRealtime()
                        if (remaining <= 0) {
                            cancelled = true
                            throw InterruptedIOException("owned-gate-time-budget")
                        }
                        lock.wait(remaining)
                    }
                    if (cancelled) throw InterruptedIOException("owned-gate-cancelled")
                } catch (e: InterruptedException) {
                    Thread.currentThread().interrupt()
                    throw InterruptedIOException("owned-gate-interrupted")
                } finally {
                    waiting--
                    waitedMs += SystemClock.elapsedRealtime() - started
                }
            }
            val count = upstream.read(buffer, offset, length)
            if (count > 0) synchronized(lock) { bytesRead += count }
            return count
        }
        override fun close() {
            try { upstream.close() } finally {
                synchronized(lock) {
                    if (opened) { readers--; closes++; opened = false }
                }
            }
        }
    }
}
