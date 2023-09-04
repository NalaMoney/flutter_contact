@file:Suppress("MoveVariableDeclarationIntoWhen")
@file:SuppressLint("DefaultLocale")

package co.sunnyapp.flutter_contact

import android.annotation.SuppressLint
import android.content.ContentProviderOperation
import android.database.Cursor
import android.provider.ContactsContract.CommonDataKinds.*

/***
 * Represents an object which has a label and a value
 * such as an email or a phone
 */
data class Item(val label: String?, val value: String?) {
    companion object
}


sealed class ItemType(val otherType: Int, val labelField: String, val typeField: String) {
    abstract fun calculateTypeInt(type: String?): Int
    abstract fun calculateTypeValue(type: Int): String?
    fun getTypeValue(cursor: Cursor): String {
        val type = cursor.getInt(cursor.getColumnIndex(typeField))
        val fromTypeInt = if (type == otherType) null else calculateTypeValue(type)
        val fromLabelField = cursor.string(labelField)
        return fromTypeInt ?: fromLabelField?.toLowerCase() ?: "other"
    }

    companion object {
        val phone = PhoneType()
    }
}

class PhoneType : ItemType(otherType = Phone.TYPE_CUSTOM, labelField = Phone.LABEL, typeField = Phone.TYPE) {
    override fun calculateTypeInt(type: String?) = when (type?.toLowerCase()) {
        "home" -> Phone.TYPE_HOME
        "work" -> Phone.TYPE_WORK
        "mobile" -> Phone.TYPE_MOBILE
        "fax work" -> Phone.TYPE_FAX_WORK
        "fax home" -> Phone.TYPE_FAX_HOME
        "main" -> Phone.TYPE_MAIN
        "company" -> Phone.TYPE_COMPANY_MAIN
        "pager" -> Phone.TYPE_PAGER
        else -> Phone.TYPE_CUSTOM
    }

    override fun calculateTypeValue(type: Int) = when (type) {
        Phone.TYPE_HOME -> "home"
        Phone.TYPE_WORK -> "work"
        Phone.TYPE_MOBILE -> "mobile"
        Phone.TYPE_FAX_WORK -> "fax work"
        Phone.TYPE_FAX_HOME -> "fax home"
        Phone.TYPE_MAIN -> "main"
        Phone.TYPE_COMPANY_MAIN -> "company"
        Phone.TYPE_PAGER -> "pager"
        else -> null
    }
}

fun Cursor.getPhoneLabel() = ItemType.phone.getTypeValue(this)
