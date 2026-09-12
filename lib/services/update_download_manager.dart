import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'notification_service.dart';
import 'update_service.dart';

/// Manages downloading GitHub release APKs with progress reporting and cancellation.
class UpdateDownloadManager extends ChangeNotifier {
  static final UpdateDownloadManager instance = UpdateDownloadManager._();
  UpdateDownloadManager._();

  AppReleaseInfo? currentRelease;
  bool isDownloading = false;
  double progress = 0.0;
  String statusText = '';
  String? downloadedApkPath;
  HttpClient? _currentClient;
  bool _isCancelled = false;
  DateTime _lastNotificationTime = DateTime.fromMillisecondsSinceEpoch(0);

  Future<void> startDownload(AppReleaseInfo release) async {
    if (isDownloading) return;

    currentRelease = release;
    isDownloading = true;
    progress = 0.0;
    statusText = 'Preparing download...';
    downloadedApkPath = null;
    _isCancelled = false;
    notifyListeners();

    IOSink? sink;
    File? partialFile;

    try {
      final extDir = await getExternalStorageDirectory();
      if (extDir == null) {
        throw Exception('Storage directory not available');
      }

      await UpdateService.cleanupOldApksExcept(release.apkFileName);

      final finalFilePath = '${extDir.path}/${release.apkFileName}';
      final tempFilePath = '$finalFilePath.download';
      partialFile = File(tempFilePath);
      if (await partialFile.exists()) {
        await partialFile.delete();
      }

      _currentClient = HttpClient();
      _currentClient!.userAgent = 'CardMinder-App';
      final uri = Uri.parse(release.apkUrl);
      final request = await _currentClient!.getUrl(uri);
      request.headers.set(HttpHeaders.acceptHeader, 'application/octet-stream');
      final response = await request.close();

      if (response.statusCode != 200 &&
          response.statusCode != 302 &&
          response.statusCode != 206) {
        throw Exception('Server returned HTTP ${response.statusCode}');
      }

      final contentLength = response.contentLength > 0
          ? response.contentLength
          : release.apkSizeBytes;

      sink = partialFile.openWrite();
      int receivedBytes = 0;

      await for (final chunk in response) {
        if (_isCancelled) {
          break;
        }
        sink.add(chunk);
        receivedBytes += chunk.length;

        if (contentLength > 0) {
          progress = receivedBytes / contentLength;
          final percent = (progress * 100).toInt().clamp(0, 100);
          final receivedMb = (receivedBytes / (1024 * 1024)).toStringAsFixed(1);
          final totalMb = (contentLength / (1024 * 1024)).toStringAsFixed(1);
          statusText = '$percent% ($receivedMb / $totalMb MB)';

          final now = DateTime.now();
          if (now.difference(_lastNotificationTime).inMilliseconds >= 600) {
            _lastNotificationTime = now;
            NotificationService.showDownloadProgressNotification(
              versionName: release.version,
              progressPercent: percent,
              progressText: '$percent% ($receivedMb / $totalMb MB)',
            );
          }
        } else {
          final receivedMb = (receivedBytes / (1024 * 1024)).toStringAsFixed(1);
          statusText = '$receivedMb MB downloaded';
        }
        notifyListeners();
      }

      await sink.flush();
      await sink.close();
      sink = null;

      if (_isCancelled) {
        if (await partialFile.exists()) {
          await partialFile.delete();
        }
        statusText = 'Download cancelled';
        isDownloading = false;
        notifyListeners();
        await NotificationService.cancelUpdateNotification();
        return;
      }

      final finalFile = File(finalFilePath);
      if (await finalFile.exists()) {
        await finalFile.delete();
      }
      await partialFile.rename(finalFilePath);

      downloadedApkPath = finalFilePath;
      isDownloading = false;
      progress = 1.0;
      statusText = 'Download complete';
      notifyListeners();

      await NotificationService.showDownloadCompleteNotification(
        versionName: release.version,
        filePath: finalFilePath,
      );
    } catch (e) {
      if (sink != null) {
        try {
          await sink.close();
        } catch (_) {}
      }
      if (partialFile != null && await partialFile.exists()) {
        try {
          await partialFile.delete();
        } catch (_) {}
      }
      isDownloading = false;
      statusText = 'Download error: $e';
      notifyListeners();
      await NotificationService.cancelUpdateNotification();
    } finally {
      _currentClient?.close(force: true);
      _currentClient = null;
    }
  }

  void cancelDownload() {
    if (!isDownloading) return;
    _isCancelled = true;
    isDownloading = false;
    _currentClient?.close(force: true);
    _currentClient = null;
    notifyListeners();
    NotificationService.cancelUpdateNotification();
  }
}
