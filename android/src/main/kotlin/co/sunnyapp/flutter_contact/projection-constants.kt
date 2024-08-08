package co.sunnyapp.flutter_contact

import android.content.ContentResolver
import android.net.Uri
import android.provider.ContactsContract.*

typealias GetLookupUri = (ContentResolver, ContactKeys) -> Uri

/**
 * This enum provides most of the implementation variations between working with Contact vs RawContact
 */
enum class ContactMode(val contentUri: Uri,
                       val contactIdRef: String,
                       val contentType: String,
                       val lookupUri: GetLookupUri,
                       val photoRef: String,
                       val nameRef: String,
                       val projections: Array<String>,
                       val projectionsIdsOnly: Array<String>) {


    UNIFIED(
            contentUri = Contacts.CONTENT_URI,
            contentType = Contacts.CONTENT_ITEM_TYPE,
            contactIdRef = Data.CONTACT_ID,
            lookupUri = { resolver, keys ->
                Contacts.getLookupUri(resolver, keys.contactUri)
            },
            nameRef = CommonDataKinds.StructuredName.DISPLAY_NAME,
            photoRef = Contacts.Photo.CONTENT_DIRECTORY,
            projections = contactProjections,
            projectionsIdsOnly = contactProjectionsIdOnly),
    SINGLE(contentUri = RawContacts.CONTENT_URI,
            contentType = RawContacts.CONTENT_ITEM_TYPE,
            contactIdRef = Data.RAW_CONTACT_ID,
            lookupUri = { resolver, keys ->
                RawContacts.getContactLookupUri(resolver, keys.contactUri)
            },
            nameRef = CommonDataKinds.StructuredName.DISPLAY_NAME,
            photoRef = RawContacts.DisplayPhoto.CONTENT_DIRECTORY,
            projections = contactProjections,
            projectionsIdsOnly = contactProjectionsIdOnly);

}

private val contactProjectionsIdOnly: Array<String> = arrayOf(
        Data.CONTACT_ID,
        Profile.DISPLAY_NAME)

private val contactProjections: Array<String> = arrayOf(
        Profile.DISPLAY_NAME,
        Data.MIMETYPE,
        CommonDataKinds.StructuredName.DISPLAY_NAME,
        CommonDataKinds.StructuredName.GIVEN_NAME,
        CommonDataKinds.StructuredName.MIDDLE_NAME,
        CommonDataKinds.StructuredName.FAMILY_NAME,
        CommonDataKinds.StructuredName.PREFIX,
        CommonDataKinds.StructuredName.SUFFIX,
        CommonDataKinds.Identity.RAW_CONTACT_ID,
        CommonDataKinds.Identity.CONTACT_ID,
        CommonDataKinds.Identity.LOOKUP_KEY,

        /// Phone
        CommonDataKinds.Phone.NUMBER,
        CommonDataKinds.Phone.TYPE,
        CommonDataKinds.Phone.LABEL,

        /// Email
        CommonDataKinds.Email.DATA,
        CommonDataKinds.Email.ADDRESS,
        CommonDataKinds.Email.TYPE,
        CommonDataKinds.Email.LABEL,

        Data.DATA1,
        Data.DATA2,
        Data.DATA3)