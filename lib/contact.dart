import 'dart:async';
import 'dart:typed_data';

import 'package:collection/collection.dart' hide IterableExtension, IterableNullableExtension;
import 'package:dartxx/dartxx.dart';
import 'package:equatable/equatable.dart';
import 'package:flexidate/flexidate.dart';
import 'package:flutter_contact/single_contacts.dart';
import 'package:flutter_contact/unified_contacts.dart';
import 'package:logging/logging.dart';

final flutterContactLog = Logger('flutterContact');

enum ContactMode { single, unified }

ContactMode? contactModeOf(dyn) {
  if (dyn == null) return null;
  switch (dyn.toString()) {
    case 'single':
      return ContactMode.single;
    case 'unified':
      return ContactMode.unified;
    default:
      return null;
  }
}

///
/// Because you can be dealing with linked contacts (unified) or individual contacts,
/// we use this object to be able to track what sort of contact you're dealing with,
/// and what keys can be used to find, reference, or update it.
// ignore: must_be_immutable
class ContactKeys extends Equatable {
  ContactMode? mode;
  String? identifier;
  String? singleContactId;
  String? unifiedContactId;
  Map<String, String> otherKeys;

  factory ContactKeys({
    required ContactMode? mode,
    String? identifier,
    String? singleContactId,
    String? unifiedContactId,
    Map<String, String>? otherKeys,
  }) {
    assert(
        mode != null || identifier == null, "You must provide a mode if you provide an identifier");
    if (mode == null) {
      return ContactKeys._(
          identifier: null,
          mode: null,
          unifiedContactId: unifiedContactId,
          singleContactId: singleContactId,
          otherKeys: otherKeys);
    }
    switch (mode) {
      case ContactMode.single:
        assert(identifier == null || singleContactId == null || identifier == singleContactId);
        return ContactKeys._(
          mode: mode,
          identifier: identifier ?? singleContactId,
          singleContactId: identifier ?? singleContactId,
          unifiedContactId: unifiedContactId,
          otherKeys: otherKeys,
        );
      case ContactMode.unified:
        assert(identifier == null || unifiedContactId == null || identifier == unifiedContactId);
        return ContactKeys._(
          mode: mode,
          identifier: identifier ?? unifiedContactId,
          singleContactId: singleContactId,
          unifiedContactId: identifier ?? unifiedContactId,
          otherKeys: otherKeys,
        );

      default:
        return (throw "This can't happen");
    }
  }

  ContactKeys.empty(this.mode)
      : identifier = null,
        unifiedContactId = null,
        singleContactId = null,
        otherKeys = <String, String>{};

  ContactKeys._({
    required this.mode,
    required this.identifier,
    required this.singleContactId,
    required this.unifiedContactId,
    Map<String, String>? otherKeys,
  }) : otherKeys = otherKeys ?? <String, String>{};

  factory ContactKeys.of(ContactMode mode, dyn) {
    if (dyn == null) {
      return ContactKeys.empty(mode);
    } else if (dyn is ContactKeys) {
      return dyn;
    } else if (dyn is Map) {
      return ContactKeys.fromMap(mode, dyn);
    } else if (dyn is String) {
      return ContactKeys.id(mode, dyn);
    } else {
      return (throw "Invalid input for ContactKeys");
    }
  }

  factory ContactKeys.fromMap(ContactMode mode, Map map) {
    final otherKeys = (map[_kotherKeys] ?? {}) as Map;
    return ContactKeys(
      mode: mode,
      identifier: map[_kidentifier]?.toString(),
      singleContactId: map[_ksingleContactId]?.toString(),
      unifiedContactId: map[_kunifiedContactId]?.toString(),
      otherKeys: {
        for (final e in otherKeys.entries)
          if (e.value != null) "${e.key}": "${e.value}",
      },
    );
  }

  Map<String, dynamic> toMap() {
    // ignore: unnecessary_cast
    return {
      'identifier': this.identifier,
      'singleContactId': this.singleContactId,
      'unifiedContactId': this.unifiedContactId,
      'otherKeys': this.otherKeys,
    } as Map<String, dynamic>;
  }

  @override
  List<Object?> get props => [mode, singleContactId, unifiedContactId, otherKeys];

  /// Contact keys that is based on the logic PK for the mode
  factory ContactKeys.id(ContactMode mode, String identifier) {
    return ContactKeys(
      mode: mode,
      identifier: identifier,
      singleContactId: null,
      unifiedContactId: null,
      otherKeys: <String, String>{},
    );
  }
}

class Contact {
  Contact({
    this.givenName,
    this.identifier,
    this.keys,
    this.middleName,
    this.displayName,
    this.prefix,
    this.suffix,
    this.familyName,
    List<Item>? phones,
    this.avatar,
  }) : _phones = [...?phones];

  final ContactKeys? keys;

  String? identifier;
  String? displayName;
  String? givenName;
  String? middleName;
  String? prefix;
  String? suffix;
  String? familyName;

  final List<Item> _phones;

  Uint8List? avatar;

  /// If the avatar is already loaded, uses it.  Otherwise, fetches the avatar from the server,
  /// but does not cache the result in memory.
  ///
  /// May be null.
  FutureOr<Uint8List?> getOrFetchAvatar() {
    if (avatar != null) return avatar;

    if (keys?.unifiedContactId == keys?.singleContactId) {
      return UnifiedContacts.getContactImage(this.identifier);
    } else {
      return SingleContacts.getContactImage(this.identifier);
    }
  }

  List<Item> get phones => _phones;

  set phones(List<Item>? value) {
    _phones.clear();
    phones.addAll([...?value]);
  }

  bool get hasAvatar => avatar?.isNotEmpty == true;

  String initials() {
    return ((this.givenName?.isNotEmpty == true ? this.givenName![0] : "") +
            (this.familyName?.isNotEmpty == true ? this.familyName![0] : ""))
        .toUpperCase();
  }

  static Contact? of(final dyn, ContactMode mode) {
    if (dyn == null) {
      return null;
    } else if (dyn is Contact) {
      return dyn;
    } else {
      return Contact.fromMap(dyn, mode);
    }
  }

  factory Contact.fromMap(final dyn, ContactMode? mode) {
    mode ??= contactModeOf(dyn["mode"])!;
    return Contact(
      identifier: dyn[_kidentifier] as String?,
      displayName: dyn[_kdisplayName] as String?,
      givenName: dyn[_kgivenName] as String?,
      middleName: dyn[_kmiddleName] as String?,
      familyName: dyn[_kfamilyName] as String?,
      prefix: dyn[_kprefix] as String?,
      keys: ContactKeys.of(mode, dyn),
      suffix: dyn[_ksuffix] as String?,
      phones: [for (final m in _iterableKey(dyn, _kphones)) Item.fromMap(m)].notNullList(),
      avatar: dyn[_kavatar] as Uint8List?,
    );
  }

  Map<String, dynamic> toMap() {
    final _ = _contactToMap(this);
    return _;
  }

  /// The [+] operator fills in this contact's empty fields with the fields from [other]
  Contact operator +(Contact other) => Contact(
      keys: this.keys ?? other.keys,
      identifier: this.identifier ?? other.identifier,
      displayName: this.displayName ?? other.displayName,
      givenName: this.givenName ?? other.givenName,
      middleName: this.middleName ?? other.middleName,
      prefix: this.prefix ?? other.prefix,
      suffix: this.suffix ?? other.suffix,
      familyName: this.familyName ?? other.familyName,
      phones: {...this.phones, ...other.phones}.toList(),
      avatar: this.avatar ?? other.avatar);

  /// Removes duplicates from the collections.  Duplicates are defined as having the exact same value
  Contact removeDuplicates() {
    return this + Contact();
  }

  /// Returns true if all items in this contact are identical.
  @override
  bool operator ==(Object other) {
    return other is Contact &&
        this.keys == other.keys &&
        this.identifier == other.identifier &&
        this.displayName == other.displayName &&
        this.givenName == other.givenName &&
        this.familyName == other.familyName &&
        this.middleName == other.middleName &&
        this.prefix == other.prefix &&
        this.suffix == other.suffix &&
        DeepCollectionEquality.unordered().equals(this.phones, other.phones);
  }

  @override
  int get hashCode {
    return hashOf(
      identifier,
      keys,
      displayName,
      givenName,
      familyName,
      middleName,
      prefix,
      suffix,
    );
  }
}

/// Item class used for contact fields which only have a [label] and
/// a [value], such as emails and phone numbers
// ignore: must_be_immutable
class Item extends Equatable {
  Item({this.label, this.value});

  String? label, value;

  static Item? fromMap(final dyn) {
    if (dyn is Map) {
      return Item(
        value: dyn["value"] as String?,
        label: dyn["label"] as String?,
      );
    } else {
      return null;
    }
  }

  String? get equalsValue => value;

  @override
  List get props => [equalsValue];
}

// ignore: must_be_immutable
class PhoneNumber extends Item {
  final String _unformattedNumber;

  PhoneNumber({String? label, String? number})
      : _unformattedNumber = _sanitizer(number),
        super(label: label, value: number);

  @override
  String get equalsValue {
    return _unformattedNumber;
  }

  static PhoneNumberSanitizer _sanitizer = defaultPhoneNumberSanitizer;

  static set sanitizer(PhoneNumberSanitizer sanitizer) {
    _sanitizer = sanitizer;
  }
}

extension ItemToMap on Item? {
  Map<String, String>? toMap() {
    if (this == null) {
      return null;
    } else {
      if (this?.value?.isNotEmpty != true) return null;
      return {
        "label": this!.label,
        "value": this!.value,
      }.valuesNotNull();
    }
  }
}

extension ItemListsToMap on Iterable<Item> {
  List<Map<String, String>> toJson() {
    return [
      for (var i in this) i.toMap(),
    ].notNullList();
  }
}

Iterable _iterableKey(map, String key) {
  if (map == null) return [];
  return map[key] as Iterable? ?? [];
}

Map<String, dynamic> _contactToMap(Contact contact) {
  return {
    _kidentifier: contact.identifier,
    _kdisplayName: contact.displayName,
    _kgivenName: contact.givenName,
    _kmiddleName: contact.middleName,
    _kfamilyName: contact.familyName,
    _kunifiedContactId: contact.unifiedContactId,
    _ksingleContactId: contact.singleContactId,
    _kotherKeys: contact.otherKeys,
    _kprefix: contact.prefix,
    _ksuffix: contact.suffix,
    _kphones: contact.phones.toJson(),
    _kavatar: contact.avatar,
  }.valuesNotNull();
}

bool Function(T item) notNullList<T>() => (item) => item != null;

typedef PhoneNumberSanitizer = String Function(String?);

String defaultPhoneNumberSanitizer(String? input) {
  String out = "";

  for (var i = 0; i < input!.length; ++i) {
    var char = input[i];
    if (_isNumeric((char))) {
      out += char;
    }
  }

  if (out.length == 10 && !out.startsWith("0") && !out.startsWith("1")) {
    return "1$out";
  } else {
    return out;
  }
}

bool _isNumeric(String? str) {
  if (str == null) {
    return false;
  }
  return double.tryParse(str) != null;
}

DateTime? parseDateTime(final dyn) {
  if (dyn is DateTime) return dyn;
  if (dyn == null) return null;
  return DateTime.tryParse(dyn.toString());
}

const _kgivenName = "givenName";
const _kidentifier = "identifier";
const _kmiddleName = "middleName";
const _kdisplayName = "displayName";
const _kprefix = "prefix";
const _ksuffix = "suffix";
const _kfamilyName = "familyName";
const _kunifiedContactId = "unifiedContactId";
const _ksingleContactId = "singleContactId";
const _kotherKeys = "otherKeys";
const _kphones = "phones";
const _kavatar = "avatar";

extension FlexiDateToMap on FlexiDate {
  Map<String, int?>? toDateMap() {
    if (this is FlexiDateData && this.isValid) {
      return (this as FlexiDateData).toMap();
    } else {
      return null;
    }
  }
}

extension ContactKeyAccessExt on Contact {
  ContactMode? get mode {
    return keys?.mode;
  }

  bool get isAggregate {
    return keys?.mode == ContactMode.unified;
  }

  String? get unifiedContactId {
    return keys?.unifiedContactId;
  }

  String? get singleContactId {
    return keys?.singleContactId;
  }

  Map<String, String> get otherKeys {
    return keys?.otherKeys ?? const {};
  }

  String? getKey(String name) {
    switch (name) {
      case _kunifiedContactId:
        return keys?.unifiedContactId;
      case _ksingleContactId:
        return keys?.singleContactId;
      case _kidentifier:
        return identifier;
      default:
        if (keys?.otherKeys == null) return null;
        return keys!.otherKeys[name];
    }
  }
}
