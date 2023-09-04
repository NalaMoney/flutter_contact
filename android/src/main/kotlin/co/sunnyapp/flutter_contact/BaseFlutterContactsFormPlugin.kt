@file:Suppress("NAME_SHADOWING")

package co.sunnyapp.flutter_contact

import android.content.ContentValues
import android.content.Intent
import android.provider.ContactsContract
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry

/**
 * Base class that facilitates edit/add contacts.
 *
 * There will be two modes.
 * for embedding v1 - FlutterContactFormsPluginOld which handles the starting of the intent with registrar.
 * for embedding v2 - FlutterContactFormsPlugin which handles the starting of the intent with ActivityPluginBinding.
 */
abstract class BaseFlutterContactForms(private val plugin: BaseFlutterContactPlugin) : PluginRegistry.ActivityResultListener {
    companion object {
        const val REQUEST_OPEN_CONTACT_FORM = 52941
        const val REQUEST_OPEN_EXISTING_CONTACT = 52942
        const val REQUEST_OPEN_CONTACT_PICKER = 52943
        const val REQUEST_INSERT_OR_UPDATE_CONTACT = 52944
    }

    var result: MethodChannel.Result? = null
        private set

    abstract fun startIntent(intent: Intent, request: Int)

    override fun onActivityResult(requestCode: Int, resultCode: Int, intent: Intent?): Boolean {
        val success = when (requestCode) {
            REQUEST_OPEN_EXISTING_CONTACT, REQUEST_OPEN_CONTACT_FORM, REQUEST_INSERT_OR_UPDATE_CONTACT -> when (val uri = intent?.data) {
                null -> {
                    result?.success(mapOf("success" to false, "code" to ErrorCodes.FORM_OPERATION_CANCELED))
                    false
                }
                else -> when (val contactIdString = uri.lastPathSegment) {
                    null -> {
                        result?.success(mapOf("success" to false, "code" to ErrorCodes.FORM_OPERATION_CANCELED))
                        false
                    }
                    else -> {
                        try {
                            result?.success(mapOf(
                                    "success" to true,
                                    "contact" to plugin.getContact(ContactKeys(plugin.mode, contactIdString.toLong()),
                                            withThumbnails = false, photoHighResolution = false)))
                        } catch (e: MethodCallException) {
                            result?.success(mapOf("success" to false, "code" to e.code))
                        }
                        true
                    }
                }
            }
            REQUEST_OPEN_CONTACT_PICKER -> when (val uri = intent?.data) {
                null -> {
                    result?.success(mapOf("success" to false, "code" to ErrorCodes.PICKER_OPERATION_CANCELED))
                    false
                }
                else -> when (val contactIdString = uri.lastPathSegment) {
                    null -> {
                        result?.success(mapOf("success" to false, "code" to ErrorCodes.PICKER_OPERATION_CANCELED))
                        false
                    }
                    else -> {
                        try {
                            result?.success(mapOf(
                                    "success" to true,
                                    "contact" to plugin.getContact(ContactKeys(plugin.mode, contactIdString.toLong()),
                                            withThumbnails = false, photoHighResolution = false)))
                        } catch (e: MethodCallException) {
                            result?.success(mapOf("success" to false, "code" to e.code))
                        }
                        true
                    }
                }
            }
            else -> {
                result?.success(ErrorCodes.FORM_COULD_NOT_BE_OPENED)
                false
            }
        }
        result = null
        return success
    }

    fun openContactEditForm(result: MethodChannel.Result, contactId: ContactKeys) {
        this.result = result
        try {
            val lookupUri = contactId.mode.lookupUri(plugin.resolver, contactId)
//            val contact = plugin.getContactRecord(contactId, withThumbnails = false, photoHighResolution = false)
            val intent = Intent(Intent.ACTION_EDIT)
            intent.setDataAndTypeAndNormalize(lookupUri, ContactsContract.Contacts.CONTENT_ITEM_TYPE)
            intent.putExtra("finishActivityOnSaveCompleted", true)
            startIntent(intent, REQUEST_OPEN_EXISTING_CONTACT)
        } catch (e: MethodCallException) {
            result.error(e.code, "Error with ${e.method}: ${e.error}", e.error)
            this.result = null
        } catch (e: Exception) {
            result.error(ErrorCodes.UNKNOWN_ERROR, "Unable to open form", e.toString())
            this.result = null
        }
    }

    fun openContactInsertForm(result: MethodChannel.Result, mode: ContactMode, contact: Contact) {
        try {
            this.result = result
            val intent = Intent(Intent.ACTION_INSERT, mode.contentUri)
            contact.applyToIntent(mode, intent)
            intent.putExtra("finishActivityOnSaveCompleted", true)
            startIntent(intent, REQUEST_OPEN_CONTACT_FORM)
        } catch (e: MethodCallException) {
            result.error(e.code, "Error with ${e.method}: ${e.error}", e.error)
            this.result = null
        } catch (e: Exception) {
            result.error(ErrorCodes.UNKNOWN_ERROR, "Problem opening contact form", "$e")
            this.result = null
        }
    }

    fun openContactPicker(result: MethodChannel.Result, mode: ContactMode) {
        try {
            this.result = result
            val intent = Intent(Intent.ACTION_PICK)
            intent.type = ContactsContract.Contacts.CONTENT_TYPE
            startIntent(intent, REQUEST_OPEN_CONTACT_PICKER)
        } catch (e: MethodCallException) {
            result.error(e.code, "Error with ${e.method}: ${e.error}", e.error)
            this.result = null
        } catch (e: Exception) {
            result.error(ErrorCodes.UNKNOWN_ERROR, "Problem opening contact picker", "$e")
            this.result = null
        }
    }

    fun insertOrUpdateContactViaPicker(result: MethodChannel.Result, mode: ContactMode, contact: Contact) {
        try {
            this.result = result
            val intentInsertEdit = Intent(Intent.ACTION_INSERT_OR_EDIT)
            intentInsertEdit.type = ContactsContract.Contacts.CONTENT_ITEM_TYPE
            contact.applyToIntent(mode, intentInsertEdit)
            intentInsertEdit.putExtra("finishActivityOnSaveCompleted", true)
            startIntent(intentInsertEdit, REQUEST_INSERT_OR_UPDATE_CONTACT)
        } catch (e: MethodCallException) {
            result.error(e.code, "Error with ${e.method}: ${e.error}", e.error)
            this.result = null
        } catch (e: Exception) {
            result.error(ErrorCodes.UNKNOWN_ERROR, "Problem opening contact picker", "$e")
            this.result = null
        }
    }
}

/// For now, only copies basic properties
fun Contact.applyToIntent(mode: ContactMode, intent: Intent) {
    val contact = this

    val inboundData = ArrayList<ContentValues>()

    inboundData += contentValues(ContactsContract.CommonDataKinds.StructuredName.CONTENT_ITEM_TYPE)
            .withValue(ContactsContract.CommonDataKinds.StructuredName.GIVEN_NAME, contact.givenName)
            .withValue(ContactsContract.CommonDataKinds.StructuredName.MIDDLE_NAME, contact.middleName)
            .withValue(ContactsContract.CommonDataKinds.StructuredName.FAMILY_NAME, contact.familyName)
            .withValue(ContactsContract.CommonDataKinds.StructuredName.PREFIX, contact.prefix)
            .withValue(ContactsContract.CommonDataKinds.StructuredName.SUFFIX, contact.suffix)

    //Phones
    for (phone in contact.phones) {
        inboundData += contentValues(ContactsContract.CommonDataKinds.Phone.CONTENT_ITEM_TYPE)
                .withValue(ContactsContract.CommonDataKinds.Phone.NUMBER, phone.value)
                .withTypeAndLabel(ItemType.phone, phone.label)
    }

    intent.apply {
        putExtra(ContactsContract.Intents.Insert.PHONE, phones.firstOrNull()?.value)
        putExtra(ContactsContract.Intents.Insert.NAME, listOfNotNull(contact.givenName, contact.familyName).let {
            when {
                it.isNotEmpty() -> it
                else -> listOfNotNull(contact.displayName)
            }
        }.joinToString(" "))
        putParcelableArrayListExtra(ContactsContract.Intents.Insert.DATA, inboundData)
    }

}

fun ContentValues.withValue(key: String, value: String?) = apply {
    val value = value ?: return@apply
    put(key, value)
}

fun ContentValues.withValue(key: String, value: Int?) = apply {
    val value = value ?: return@apply
    put(key, value)
}

fun ContentValues.withTypeAndLabel(type: ItemType, labelString: String?) = apply {
    val label = labelString ?: return@apply
    return when (val typeInt = type.calculateTypeInt(label)) {
        type.otherType -> withValue(type.typeField, typeInt)
                .withValue(type.labelField, label)
        else -> withValue(type.typeField, typeInt)
    }

}

fun contentValues(mimeType: String, vararg values: Pair<String, String?>) = ContentValues().apply {
    put(ContactsContract.Data.MIMETYPE, mimeType)
    for ((k, v) in values) {
        if (v != null) {
            put(k, v)
        }
    }
}