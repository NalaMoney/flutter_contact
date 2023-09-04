package co.sunnyapp.flutter_contact

import android.annotation.SuppressLint
import android.annotation.TargetApi
import android.database.Cursor
import android.os.Build
import android.provider.ContactsContract
import android.provider.ContactsContract.CommonDataKinds.StructuredPostal
import java.util.*

fun Cursor.string(index: String): String? {
    return getString(getColumnIndex(index))
}

fun Cursor.long(index: String): Long? {
    return getLong(getColumnIndex(index))
}

fun Cursor.int(index: String): Int? {
    return getInt(getColumnIndex(index))
}

fun Cursor.getLabel(): String {
    val cursor = this;
    when (cursor.getInt(cursor.getColumnIndex(StructuredPostal.TYPE))) {
        StructuredPostal.TYPE_HOME -> return "home"
        StructuredPostal.TYPE_WORK -> return "work"
        StructuredPostal.TYPE_CUSTOM -> {
            val label = cursor.getString(cursor.getColumnIndex(StructuredPostal.LABEL))
            return label ?: ""
        }
    }
    return "other"
}
