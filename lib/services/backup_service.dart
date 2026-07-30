import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/credit_card.dart';
import '../models/app_settings.dart';

class BackupData {
  final List<CreditCard> cards;
  final AppSettings settings;
  final DateTime exportDate;

  BackupData({
    required this.cards,
    required this.settings,
    required this.exportDate,
  });
}

class BackupService {
  static const String _headerTag = 'CMBK_V2:';

  static enc.Encrypter _getEncrypterForPin(String pin) {
    // Derive 256-bit (32-byte) AES key using SHA-256 hash of pin + salt
    final keyBytes =
        sha256.convert(utf8.encode('$pin:CardMinder_Salt_2026!')).bytes;
    final key = enc.Key(Uint8List.fromList(keyBytes));
    return enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
  }

  static enc.IV _getIV() {
    return enc.IV.fromUtf8('CM_IV_16_BYTES!!');
  }

  /// Encrypts all card and settings data with the user's PIN and prompts to share/save.
  static Future<String?> createAndShareBackup({
    required List<CreditCard> cards,
    required AppSettings settings,
    required String userPin,
  }) async {
    try {
      final payload = {
        'app': 'CardMinder',
        'version': 2,
        'exportDate': DateTime.now().toIso8601String(),
        'cards': cards.map((c) => c.toJson()).toList(),
        'settings': settings.toJson(),
      };

      final jsonStr = jsonEncode(payload);
      final encrypter = _getEncrypterForPin(userPin);
      final iv = _getIV();
      final encrypted = encrypter.encrypt(jsonStr, iv: iv);

      final backupContent = '$_headerTag${encrypted.base64}';

      final tempDir = await getTemporaryDirectory();
      final timeStampStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'CardMinder_Backup_$timeStampStr.cmbk';
      final file = File('${tempDir.path}/$fileName');

      await file.writeAsString(backupContent);

      final xFile = XFile(file.path);
      // ignore: deprecated_member_use
      await Share.shareXFiles(
        [xFile],
        subject: 'CardMinder Backup ($fileName)',
        text: 'CardMinder Backup file',
      );

      return null;
    } catch (e) {
      return e.toString().replaceAll('FormatException: ', '');
    }
  }

  /// Opens file picker to let user pick a .cmbk file. Returns the picked File or null.
  static Future<File?> pickBackupFile() async {
    try {
      final pickerResult = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (pickerResult == null || pickerResult.files.isEmpty) {
        return null;
      }

      final path = pickerResult.files.single.path;
      if (path == null) return null;

      return File(path);
    } catch (e) {
      return null;
    }
  }

  /// Decrypts a backup file given the user's PIN.
  static Future<BackupData> decryptBackupFile({
    required File file,
    required String userPin,
  }) async {
    final rawContent = (await file.readAsString()).trim();

    if (!rawContent.startsWith(_headerTag)) {
      throw const FormatException('Invalid or unrecognized backup file format.');
    }

    final base64Encrypted = rawContent.substring(_headerTag.length);
    final encrypter = _getEncrypterForPin(userPin);
    final iv = _getIV();

    final decryptedJsonStr = encrypter.decrypt64(base64Encrypted, iv: iv);
    final Map<String, dynamic> dataMap = jsonDecode(decryptedJsonStr);

    if (dataMap['app'] != 'CardMinder') {
      throw const FormatException('Unrecognized backup payload.');
    }

    final List<dynamic> cardsListRaw = dataMap['cards'] ?? [];
    final List<CreditCard> restoredCards = cardsListRaw
        .map((item) => CreditCard.fromJson(Map<String, dynamic>.from(item)))
        .toList();

    final settingsRaw = Map<String, dynamic>.from(dataMap['settings'] ?? {});
    final restoredSettings = AppSettings.fromJson(settingsRaw);

    final exportDateStr = dataMap['exportDate'] as String?;
    final exportDate = exportDateStr != null
        ? DateTime.parse(exportDateStr)
        : DateTime.now();

    return BackupData(
      cards: restoredCards,
      settings: restoredSettings,
      exportDate: exportDate,
    );
  }
}
