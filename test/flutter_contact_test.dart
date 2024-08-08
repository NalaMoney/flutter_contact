import 'package:flexidate/flexidate.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_contact/contacts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiver/iterables.dart';

import 'mock_contact_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel =
      MethodChannel('github.com/sunnyapp/flutter_unified_contact');

  final mock = ContactsMocks();
  channel.setMockMethodCallHandler(mock.handler);
  channel.setMockMethodCallHandler(mock.handler);
  tearDown(() {
    mock.clear();
  });

  test('should get contacts', () async {
    mock.addContact(Contact(identifier: '1', givenName: "Frank"));
    mock.addContact(Contact(identifier: '2', givenName: "Larry"));
    mock.addContact(Contact(identifier: '3', givenName: "Moe"));

    final List<Contact> contacts = await Contacts.streamContacts().toList();
    expect(contacts.length, 3);
    expect(contacts, everyElement(isInstanceOf<Contact>()));
    expect(contacts.toList()[0].givenName, 'Frank');
    expect(contacts.toList()[1].givenName, 'Larry');
    expect(contacts.toList()[2].givenName, 'Moe');
  });

  test('should stream contacts (paging stream)', () async {
    for (final x in range(0, 100)) {
      mock.addContact(Contact(identifier: '$x', givenName: "Contact$x"));
    }

    final List<Contact> contacts = await Contacts.streamContacts().toList();
    expect(contacts.length, 100);
    expect(contacts, everyElement(isInstanceOf<Contact>()));
    for (int i = 0; i < 100; i++) {
      expect(contacts.toList()[i].givenName, 'Contact$i');
    }
  });

  test('should stream contacts (paging list)', () async {
    for (final x in range(0, 100)) {
      mock.addContact(Contact(identifier: '$x', givenName: "Contact$x"));
    }

    final PagingList<Contact> contacts = Contacts.listContacts();
    var i = 0;
    while (await contacts.moveNext()) {
      final curr = await contacts.current;
      expect(curr?.givenName, 'Contact$i');
      i++;
    }
    expect(i, equals(100));
  });

  test('should get contacts (paged)', () async {
    for (final x in range(0, 100)) {
      mock.addContact(Contact(identifier: '$x', givenName: "Contact$x"));
    }

    final PagingList<Contact> contacts = Contacts.listContacts();
    await contacts.moveNextPage();
    final cpage = await contacts.currentPage;
    expect(cpage, hasLength(20));
    expect(cpage![0].identifier, '0');
  });

  test('should add contact', () async {
    await Contacts.addContact(Contact(
      givenName: 'givenName',
      phones: [Item(label: 'label')],
    ));
    mock.expectMethodCall('addContact');
  });

  test('dates serialize as maps', () async {
    final contact = Contact(
      givenName: 'Bob',
      phones: [Item(label: 'label')],
    );
    final cmap = contact.toMap();
    final dates = cmap["dates"].first["date"];
    expect(dates, isA<Map>());
    expect(dates[kyear], isNull);
    expect(dates[kmonth], 12);
    expect(dates[kday], 28);
  });

  test('null response shoud not raise error', () async {
    final response = await Contacts.getContact("missing");
    mock.expectMethodCall('getContact');
    expect(response, isNull);
  });

  test('should delete contact', () async {
    await Contacts.deleteContact(Contact(
      givenName: 'givenName',
      phones: [Item(label: 'label')],
    ));
    mock.expectMethodCall('deleteContact');
  });

  test('should provide initials for contact', () {
    Contact contact1 =
        Contact(givenName: "givenName", familyName: "familyName");
    Contact contact2 = Contact(givenName: "givenName");
    Contact contact3 = Contact(familyName: "familyName");
    Contact contact4 = Contact();

    expect(contact1.initials(), "GF");
    expect(contact2.initials(), "G");
    expect(contact3.initials(), "F");
    expect(contact4.initials(), "");
  });

  test('should remove duplicates', () {
    Contact contact1 = Contact(
      givenName: "givenName",
      familyName: "familyName",
      emails: [
        Item(label: "home", value: "smartytime@gmail.com"),
        Item(label: "work", value: "smartytime@gmail.com"),
      ],
      phones: [
        PhoneNumber(label: "home", number: "1-480-227-4399"),
        PhoneNumber(label: "work", number: "4802274399"),
      ],
    );

    Contact dedup = contact1.removeDuplicates();
    expect(dedup.phones, hasLength(1));
    expect(dedup.emails, hasLength(1));
    expect(contact1.phones, hasLength(2));
    expect(contact1.emails, hasLength(2));
  });

  test('should update contact', () async {
    mock.addContact(Contact(
      identifier: 'needToUpdate',
      givenName: "Frank",
    ));

    final updated = Contact(
      identifier: 'needToUpdate',
      givenName: 'Francis',
    );

    final savedContact = await Contacts.updateContact(updated);
    mock.expectMethodCall('updateContact');
    expect(savedContact, equals(savedContact));
  });

  test('should show contacts are equal', () {
    Contact contact1 =
        Contact(givenName: "givenName", familyName: "familyName");
    Contact contact2 =
        Contact(givenName: "givenName", familyName: "familyName");
    expect(contact1 == contact2, true);
    expect(contact1.hashCode, contact2.hashCode);
  });

  test('should produce a valid merged contact', () {
    Contact contact1 =
        Contact(givenName: "givenName", familyName: "familyName", emails: [
      Item(label: "Home", value: "home@example.com"),
      Item(label: "Work", value: "work@example.com"),
    ], phones: []);
    Contact contact2 = Contact(familyName: "familyName", phones: [
      Item(label: "Mobile", value: "111-222-3344")
    ], emails: [
      Item(label: "Mobile", value: "mobile@example.com"),
    ]);
    Contact mergedContact =
        Contact(givenName: "givenName", familyName: "familyName", phones: [
      Item(label: "Mobile", value: "111-222-3344")
    ]);

    expect(contact1 + contact2, mergedContact);
  });

  test('should provide a valid merged contact, with no extra info', () {
    Contact contact1 = Contact(familyName: "familyName");
    Contact contact2 = Contact();
    expect(contact1 + contact2, contact1);
  });

  test('Parse intl date', () {
    final date = FlexiDate.parse("6 июля 1983");
    expect(date, isNotNull);
  });

  test('should provide a map of the contact', () {
    Contact contact = Contact(givenName: "givenName", familyName: "familyName");
    expect(contact.toMap(), {
      "givenName": "givenName",
      "familyName": "familyName",
      "otherKeys": {},
      "socialProfiles": [],
      "dates": [],
      "urls": [],
      "emails": [],
      "phones": [],
      "postalAddresses": [],
    });
  });
}

typedef MethodHandler = Future<dynamic> Function(MethodCall call);
typedef RawMethodHandler = Future<dynamic> Function(dynamic call);
