import 'dart:async';
import 'package:telephony/telephony.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

String normalizePhone(String number) {
  final digits = number.replaceAll(RegExp(r'[^0-9]'), '');
  return digits.length > 10 ? digits.substring(digits.length - 10) : digits;
}

void backgroundMessageHandler(SmsMessage message) async {}

class SmsService {
  SmsService._privateConstructor();
  static final SmsService instance = SmsService._privateConstructor();

  final Telephony telephony = Telephony.instance;
  final StreamController<SmsMessage> _incoming = StreamController.broadcast();

  Stream<SmsMessage> get onMessage => _incoming.stream;
  Map<String, String> contactMap = {};

  Future<void> init() async {
    bool permissionsGranted =
        await telephony.requestPhoneAndSmsPermissions ?? false;
    if (!permissionsGranted) return;

    telephony.listenIncomingSms(
      onNewMessage: (SmsMessage message) => _incoming.add(message),
      onBackgroundMessage: backgroundMessageHandler,
    );

    if (await FlutterContacts.requestPermission()) {
      final contacts = await FlutterContacts.getContacts(withProperties: true);
      for (final c in contacts) {
        for (final p in c.phones) {
          final key = normalizePhone(p.number ?? '');
          if (key.isNotEmpty && !contactMap.containsKey(key))
            contactMap[key] = c.displayName;
        }
      }
    }
  }

  Future<List<SmsMessage>> fetchInbox() async => await telephony.getInboxSms(
    columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
  );

  String lookupName(String phone) => contactMap[normalizePhone(phone)] ?? phone;
  void dispose() => _incoming.close();
}
