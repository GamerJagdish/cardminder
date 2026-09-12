import 'package:intl/intl.dart';

/// Represents parsed release metadata from GitHub releases for updates.
class AppReleaseInfo {
  final String version;
  final String apkUrl;
  final String releaseNotes;
  final String apkFileName;
  final int apkSizeBytes;
  final DateTime? publishedAt;

  AppReleaseInfo({
    required this.version,
    required this.apkUrl,
    required this.releaseNotes,
    required this.apkFileName,
    required this.apkSizeBytes,
    this.publishedAt,
  });

  String get formattedSize {
    if (apkSizeBytes <= 0) return '';
    final mb = apkSizeBytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  String get formattedDate {
    if (publishedAt == null) return '';
    return DateFormat('MMM d, y').format(publishedAt!);
  }

  String get cleanVersion {
    if (version.startsWith('v.') || version.startsWith('V.')) {
      return version.substring(2);
    }
    if (version.startsWith('v') || version.startsWith('V')) {
      return version.substring(1);
    }
    return version;
  }

  String get architecture {
    final name = apkFileName.toLowerCase();
    if (name.contains('arm64-v8a') || name.contains('arm64')) {
      return 'arm64-v8a';
    } else if (name.contains('armeabi-v7a') || name.contains('armv7')) {
      return 'armeabi-v7a';
    } else if (name.contains('x86_64')) {
      return 'x86_64';
    } else if (name.contains('x86')) {
      return 'x86';
    } else if (name.contains('universal') || name.contains('all-devices')) {
      return 'universal';
    }
    return '';
  }

  String get displayTitle {
    final arch = architecture;
    if (arch.isNotEmpty) {
      return 'CardMinder $cleanVersion ($arch)';
    }
    return 'CardMinder $cleanVersion';
  }
}
