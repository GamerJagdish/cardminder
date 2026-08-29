import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
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

class BackupResult {
  final bool success;
  final String? filePath;
  final String? fileName;
  final String? errorMessage;
  final File? file;

  BackupResult({
    required this.success,
    this.filePath,
    this.fileName,
    this.errorMessage,
    this.file,
  });
}

class BackupService {
  static const String _headerTag = 'CMBK_V2:';
  static const MethodChannel _channel =
      MethodChannel('com.gamerjagdish.cardminder/file_utils');

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

  /// Resolves the default persistent backup directory (public Documents/CardMinder on Android)
  static Future<String> getDefaultBackupDirectory() async {
    try {
      if (Platform.isAndroid) {
        // 1. Target public user-accessible Documents/CardMinder
        final publicDocs =
            Directory('/storage/emulated/0/Documents/CardMinder');
        try {
          if (!await publicDocs.exists()) {
            await publicDocs.create(recursive: true);
          }
          return publicDocs.path;
        } catch (_) {
          // 2. Fallback to public Download/CardMinder if Documents has permission restrictions
          try {
            final publicDownloads =
                Directory('/storage/emulated/0/Download/CardMinder');
            if (!await publicDownloads.exists()) {
              await publicDownloads.create(recursive: true);
            }
            return publicDownloads.path;
          } catch (_) {
            // 3. Fallback to app external storage
          }
        }

        final ext = await getExternalStorageDirectory();
        if (ext != null) {
          final cardMinderBackups = Directory('${ext.path}/CardMinder');
          if (!await cardMinderBackups.exists()) {
            await cardMinderBackups.create(recursive: true);
          }
          return cardMinderBackups.path;
        }
      }

      final docs = await getApplicationDocumentsDirectory();
      final backups = Directory('${docs.path}/CardMinder');
      if (!await backups.exists()) {
        await backups.create(recursive: true);
      }
      return backups.path;
    } catch (_) {
      final temp = await getTemporaryDirectory();
      return temp.path;
    }
  }

  /// Returns the configured backup directory or fallback to default
  static Future<String> getEffectiveBackupDirectory(AppSettings settings) async {
    if (settings.backupPath.isNotEmpty) {
      final dir = Directory(settings.backupPath);
      if (await dir.exists()) {
        return settings.backupPath;
      }
      try {
        await dir.create(recursive: true);
        return settings.backupPath;
      } catch (_) {
        // Fallback to default if custom path is inaccessible
      }
    }
    return getDefaultBackupDirectory();
  }

  /// Encrypts all card and settings data and saves directly to the backup folder.
  static Future<BackupResult> createLocalBackup({
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

      final targetDirPath = await getEffectiveBackupDirectory(settings);
      final targetDir = Directory(targetDirPath);
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }

      final timeStampStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'CardMinder_Backup_$timeStampStr.cmbk';
      final file = File('${targetDir.path}/$fileName');

      await file.writeAsString(backupContent);

      return BackupResult(
        success: true,
        filePath: file.path,
        fileName: fileName,
        file: file,
      );
    } catch (e) {
      return BackupResult(
        success: false,
        errorMessage: e.toString().replaceAll('FormatException: ', ''),
      );
    }
  }

  /// Shares an existing backup file
  static Future<void> shareBackupFile({
    required File file,
    required String fileName,
  }) async {
    final xFile = XFile(file.path);
    await SharePlus.instance.share(
      ShareParams(
        files: [xFile],
        subject: 'CardMinder Backup ($fileName)',
        text: 'CardMinder Backup file',
      ),
    );
  }

  /// Opens the backup folder in the native Android file manager
  static Future<bool> openBackupFolder(String folderPath) async {
    try {
      if (Platform.isAndroid) {
        final res = await _channel.invokeMethod<bool>(
          'openFolder',
          {'path': folderPath},
        );
        return res ?? false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Opens file picker to let user pick a .cmbk file. Returns the picked File or null.
  static Future<File?> pickBackupFile({String? initialDirectory}) async {
    try {
      final picked = await FilePicker.pickFile(
        type: FileType.any,
        initialDirectory: initialDirectory,
      );

      if (picked == null || picked.path == null) {
        return null;
      }

      return File(picked.path!);
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
