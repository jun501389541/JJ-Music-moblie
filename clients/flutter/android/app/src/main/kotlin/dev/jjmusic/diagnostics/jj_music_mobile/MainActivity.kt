package dev.jjmusic.diagnostics.jj_music_mobile

import io.flutter.embedding.android.FlutterActivity
import android.content.Context
import android.os.Bundle
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor

class MainActivity : FlutterActivity() {
    override fun provideFlutterEngine(context: Context): FlutterEngine {
        LocalHost.launchMode = intent?.getStringExtra("p1Mode") ?: ""
        LocalHost.launchToken = intent?.getStringExtra("p1Token") ?: ""
        return LocalHost.engine(context)
    }
    override fun shouldDestroyEngineWithHost() = false
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        LocalHost.activity = this
        LocalHost.timeline("activity-create")
    }
    override fun onDestroy() {
        LocalHost.timeline("activity-destroy")
        if (LocalHost.activity === this) LocalHost.activity = null
        super.onDestroy()
    }
}
