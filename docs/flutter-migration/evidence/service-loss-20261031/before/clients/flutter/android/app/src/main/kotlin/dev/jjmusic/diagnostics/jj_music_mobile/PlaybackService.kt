package dev.jjmusic.diagnostics.jj_music_mobile

import android.app.*
import android.content.Intent
import android.media.session.MediaSession
import android.os.IBinder

class PlaybackService : Service() {
    override fun onBind(intent: Intent?): IBinder? = null
    override fun onCreate() {
        super.onCreate()
        LocalHost.timeline("service-create")
        val manager = getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(NotificationChannel("owned_playback", "自有样本技术诊断", NotificationManager.IMPORTANCE_LOW))
        val session = MediaSession(this, "JJ-Music-owned-diagnostic")
        session.setCallback(object : MediaSession.Callback() {
            override fun onPlay() = LocalHost.command("play")
            override fun onPause() = LocalHost.command("pause")
            override fun onStop() = LocalHost.command("stop")
            override fun onSeekTo(pos: Long) = LocalHost.command("seek", pos)
            override fun onSkipToNext() = LocalHost.command("next")
            override fun onSkipToPrevious() = LocalHost.command("previous")
        })
        session.isActive = true
        LocalHost.session = session
        promote()
    }
    private fun promote() {
        val session = LocalHost.session ?: error("owned-service-session-missing")
        val launch = PendingIntent.getActivity(this, 0, Intent(this, MainActivity::class.java), PendingIntent.FLAG_IMMUTABLE)
        startForeground(41, Notification.Builder(this,"owned_playback")
            .setSmallIcon(android.R.drawable.ic_media_play).setContentTitle("JJ-Music 自有样本诊断")
            .setContentText("仅本地测试媒体").setContentIntent(launch)
            .setStyle(Notification.MediaStyle().setMediaSession(session.sessionToken)).build())
    }
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // A reused service must also acknowledge each new foreground request.
        promote()
        LocalHost.serviceStartAcknowledged(this, startId)
        return START_NOT_STICKY
    }
    override fun onDestroy() {
        LocalHost.timeline("service-destroy")
        LocalHost.session?.release(); LocalHost.session = null
        stopForeground(STOP_FOREGROUND_REMOVE)
        super.onDestroy()
    }
}
