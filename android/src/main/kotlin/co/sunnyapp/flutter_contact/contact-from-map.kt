@file:Suppress("UNCHECKED_CAST")

package co.sunnyapp.flutter_contact

import org.joda.time.format.DateTimeFormatter
import org.joda.time.format.ISODateTimeFormat
import java.util.*

typealias StructList = List<Struct>
typealias Struct = Map<String, Any>


val isoDateParser: DateTimeFormatter = ISODateTimeFormat.dateOptionalTimeParser()
fun StructList?.toItemList(): MutableList<Item> = this.orEmpty().map { Item.fromMap(it) }.toMutableList()

fun Contact.Companion.fromMap(mode: ContactMode, map: Map<String, *>): Contact {
    return Contact(
            keys = contactKeyOf(mode = mode,
                    value = mapOf(
                            "unifiedContactId" to map["unifiedContactId"],
                            "singleContactId" to map["singleContactId"],
                            "lookupKey" to (map["otherKeys"].orEmptyMap()["lookupKey"] as String?),
                            "identifier" to map["identifier"])),

            givenName = map["givenName"] as String?,
            middleName = map["middleName"] as String?,
            familyName = map["familyName"] as String?,
            prefix = map["prefix"] as String?,
            suffix = map["suffix"] as String?,
            avatar = (map["avatar"] as? ByteArray?),
            linkedContactIds = map["linkedContactIds"].orEmptyList<String>().toMutableList(),
            phones = (map["phones"] as? StructList?).toItemList(),
            emails = (map["emails"] as? StructList?).toItemList(),
    )
}

fun Item.Companion.fromMap(map: Map<String, *>): Item {
    return Item(map["label"] as? String?, map["value"] as? String?)
}
