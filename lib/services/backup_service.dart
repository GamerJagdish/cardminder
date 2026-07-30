import 'dart:convert';
import 'dart:io';
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
  // 32-character AES-256 Encryption Key for CardMinder offline backups
  static const String _passKey = 'CardMinder_SecureOfflineKey_2026';
  static const String _headerTag = 'CMBK_V1:';

  static enc.Encrypter _getEncrypter() {
    final key = enc.Key.fromUtf8(_passKey);
    return enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
  }

  static enc.IV _getIV() {
    // 16-byte fixed IV for deterministic CBC verification
    return enc.IV.fromUtf8('CM_IV_16_BYTES!!');
  }

  /// Encrypts all card and settings data and prompts the user to save/share the backup file.
  static Future<String?> createAndShareBackup({
    required List<CreditCard> cards,
    required AppSettings settings,
  }) async {
    try {
      final payload = {
        'app': 'CardMinder',
        'version': 1,
        'exportDate': DateTime.now().toIso8601String(),
        'cards': cards.map((c) => c.toJson()).toList(),
        'settings': settings.toJson(),
      };

      final jsonStr = jsonEncode(payload);
      final encrypter = _getEncrypter();
      final iv = _getIV();
      final encrypted = encrypter.encrypt(jsonStr, iv: iv);

      // Prepend header tag for quick format validation
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

  /// Opens file picker, reads and decrypts a .cmbk backup file.
  static Future<BackupData?> pickAndDecryptBackup() async {
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

      final file = File(path);
      final rawContent = (await file.readAsString()).trim();

      if (!rawContent.startsWith(_headerTag)) {
        throw const FormatException('Invalid CardMinder backup format.');
      }

      final base64Encrypted = rawContent.substring(_headerTag.length);
      final encrypter = _getEncrypter();
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
    } catch (e) {
      rethrow;
    }
  }
}
