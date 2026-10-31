package dev.jjmusic.diagnostics.jj_music_mobile

import android.content.ContentProvider
import android.content.ContentValues
import android.database.Cursor
import android.net.Uri
import android.os.ParcelFileDescriptor
import java.io.File
import java.io.FileNotFoundException

/** Private seekable provider for the one owned fixture. No filesystem discovery. */
class FixtureProvider : ContentProvider() {
    override fun onCreate() = true
    override fun getType(uri: Uri) = "audio/wav"
    override fun openFile(uri: Uri, mode: String): ParcelFileDescriptor {
        if (mode != "r" || uri.path != "/tone-long" || LocalHost.revoked) throw FileNotFoundException("fixture-denied")
        return ParcelFileDescriptor.open(File(context!!.cacheDir, "owned-tone-long.wav"), ParcelFileDescriptor.MODE_READ_ONLY)
    }
    override fun query(uri: Uri, projection: Array<out String>?, selection: String?, selectionArgs: Array<out String>?, sortOrder: String?): Cursor? = null
    override fun insert(uri: Uri, values: ContentValues?): Uri? = null
    override fun delete(uri: Uri, selection: String?, selectionArgs: Array<out String>?) = 0
    override fun update(uri: Uri, values: ContentValues?, selection: String?, selectionArgs: Array<out String>?) = 0
}
