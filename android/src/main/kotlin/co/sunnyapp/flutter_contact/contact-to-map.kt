package co.sunnyapp.flutter_contact

fun Contact.toMap() = mutableMapOf(
        "identifier" to identifier?.toString(),
        "displayName" to displayName,
        "givenName" to givenName,
        "middleName" to middleName,
        "familyName" to familyName,
        "prefix" to prefix,
        "suffix" to suffix,
        "avatar" to avatar,
        "phones" to phones.toItemMap(),
        "emails" to emails.toItemMap(),
        "unifiedContactId" to unifiedContactId?.toString(),
        "singleContactId" to singleContactId?.toString(),
        "otherKeys" to mapOf("lookupKey" to keys?.lookupKey).filterValuesNotNull(),
        "linkedContactIds" to linkedContactIds,
).filterValuesNotNull()

fun DateComponents.toMap(): Map<String, Int> {
    val result = mutableMapOf<String, Int>()
    if (year != null) result["year"] = year
    if (month != null) result["month"] = month
    if (day != null) result["day"] = day
    return result
}

fun Item.toMap(): Map<String, String?> {
    return mutableMapOf(
            "label" to label,
            "value" to value)
}


fun MutableList<Item>.toItemMap() = map { it.toMap() }