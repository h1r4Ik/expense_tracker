import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

class UpdateInfo {
  final String currentVersion;
  final String latestVersion;
  final String downloadUrl;
  final String fileName;
  final String releaseNotes;

  const UpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.downloadUrl,
    required this.fileName,
    required this.releaseNotes,
  });

  Map<String, dynamic> toJson() => {
        'currentVersion': currentVersion,
        'latestVersion': latestVersion,
        'downloadUrl': downloadUrl,
        'fileName': fileName,
        'releaseNotes': releaseNotes,
      };

  factory UpdateInfo.fromJson(Map<String, dynamic> json) => UpdateInfo(
        currentVersion: json['currentVersion']?.toString() ?? '1.0.0',
        latestVersion: json['latestVersion']?.toString() ?? '',
        downloadUrl: json['downloadUrl']?.toString() ?? '',
        fileName: json['fileName']?.toString() ?? 'app-release.apk',
        releaseNotes: json['releaseNotes']?.toString() ?? '',
      );
}

class UpdateService {
  // Global download state notifiers
  static final ValueNotifier<bool> isDownloading = ValueNotifier<bool>(false);
  static final ValueNotifier<double> downloadProgress = ValueNotifier<double>(0.0);
  static final ValueNotifier<String?> downloadStatus = ValueNotifier<String?>(null);
  static String? downloadedFilePath;
  static UpdateInfo? currentUpdateInfo;

  // GitHub repository details (can be customized via environment or config)
  static String githubOwner = 'h1r4Ik';
  static String githubRepo = 'expense_tracker';

  // Optional GitHub token
  static String githubToken = '';

  // Optional fallback URL (e.g. raw Gist)
  static String? fallbackGistUrl;

  /// Checks if a valid update file is already downloaded and cached on disk
  static Future<String?> getExistingDownloadedFilePath(UpdateInfo updateInfo) async {
    try {
      if (downloadedFilePath != null && await File(downloadedFilePath!).exists()) {
        final f = File(downloadedFilePath!);
        if (await f.length() >= 1024 * 50) {
          return downloadedFilePath;
        }
      }

      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/${updateInfo.fileName}';
      final file = File(filePath);

      if (await file.exists()) {
        final fileSize = await file.length();
        if (fileSize >= 1024 * 50) {
          final raf = await file.open(mode: FileMode.read);
          final signature = await raf.read(4);
          await raf.close();

          final isZipContainer = signature.length >= 4 &&
              signature[0] == 0x50 &&
              signature[1] == 0x4B &&
              signature[2] == 0x03 &&
              signature[3] == 0x04;

          final isExeHeader = signature.length >= 2 &&
              signature[0] == 0x4D &&
              signature[1] == 0x5A;

          if (isZipContainer || isExeHeader) {
            debugPrint('Valid existing update file found on disk: $filePath ($fileSize bytes)');
            downloadedFilePath = filePath;
            return filePath;
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking existing update file: $e');
    }
    return null;
  }

  /// Checks GitHub API for latest release with optional Gist fallback
  static Future<UpdateInfo?> checkForUpdates({
    String? owner,
    String? repo,
    String? token,
    String? customGistUrl,
  }) async {
    final effectiveOwner = owner ?? githubOwner;
    final effectiveRepo = repo ?? githubRepo;
    final effectiveToken = token ?? githubToken;
    final effectiveGist = customGistUrl ?? fallbackGistUrl;

    try {
      final headers = <String, String>{
        'Accept': 'application/vnd.github.v3+json',
        'Cache-Control': 'no-cache, no-store, must-revalidate',
        'Pragma': 'no-cache',
        'User-Agent': 'Hermes-ExpenseTracker-App/1.0',
      };

      if (effectiveToken.isNotEmpty) {
        headers['Authorization'] = 'token $effectiveToken';
      }

      final apiUrl =
          'https://api.github.com/repos/$effectiveOwner/$effectiveRepo/releases/latest?t=${DateTime.now().millisecondsSinceEpoch}';
      debugPrint('Checking Primary Update URL: $apiUrl');

      final response = await http
          .get(Uri.parse(apiUrl), headers: headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final tagName = (json['tag_name'] ?? '').toString();
        final latestVersion = tagName.replaceFirst(RegExp(r'^[vV]'), '').trim();

        if (latestVersion.isEmpty) {
          if (effectiveGist != null) return await _checkGistFallback(effectiveGist);
          return null;
        }

        final currentVersion = await getCurrentAppVersion();
        final isNewer = isNewerVersion(latestVersion, currentVersion);

        if (isNewer) {
          final assetData = _getAssetData(json);
          if (assetData == null) {
            if (effectiveGist != null) return await _checkGistFallback(effectiveGist);
            return null;
          }

          return UpdateInfo(
            currentVersion: currentVersion,
            latestVersion: latestVersion,
            downloadUrl: assetData['downloadUrl']!,
            fileName: assetData['fileName']!,
            releaseNotes: (json['body'] ?? 'New version available').toString(),
          );
        }
        return null;
      } else if (effectiveGist != null) {
        return await _checkGistFallback(effectiveGist);
      } else {
        throw HttpException(
          'GitHub release check failed with HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Update check error: $e');
      if (effectiveGist != null) {
        return await _checkGistFallback(effectiveGist);
      }
      rethrow;
    }
  }

  /// Fallback check via raw Gist
  static Future<UpdateInfo?> _checkGistFallback(String gistUrl) async {
    try {
      final url = Uri.parse('$gistUrl?t=${DateTime.now().millisecondsSinceEpoch}');
      final response = await http.get(url, headers: {
        'Cache-Control': 'no-cache, no-store, must-revalidate',
        'User-Agent': 'Hermes-ExpenseTracker-App/1.0',
      }).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final latestVersion = (json['version'] ?? '')
            .toString()
            .replaceFirst(RegExp(r'^[vV]'), '')
            .trim();

        if (latestVersion.isEmpty) return null;

        final currentVersion = await getCurrentAppVersion();
        final isNewer = isNewerVersion(latestVersion, currentVersion);

        if (isNewer) {
          final downloadUrl = Platform.isWindows
              ? json['windows_url']?.toString()
              : json['android_url']?.toString();

          if (downloadUrl == null || downloadUrl.isEmpty) return null;

          final defaultFileName =
              Platform.isWindows ? 'expense_tracker_setup.exe' : 'app-release.apk';
          final fileName = (Platform.isWindows
                  ? json['windows_filename']
                  : json['android_filename'])
              ?.toString() ?? defaultFileName;

          return UpdateInfo(
            currentVersion: currentVersion,
            latestVersion: latestVersion,
            downloadUrl: downloadUrl,
            fileName: fileName,
            releaseNotes: (json['release_notes'] ?? 'New version available').toString(),
          );
        }
      }
    } catch (e) {
      debugPrint('Fallback gist check error: $e');
    }
    return null;
  }

  /// Compares semantic versions (e.g., "1.2.0" vs "1.1.9")
  static bool isNewerVersion(String latest, String current) {
    try {
      final cleanLatest = latest
          .replaceFirst(RegExp(r'^[vV]'), '')
          .split('+')
          .first
          .split('-')
          .first
          .trim();
      final cleanCurrent = current
          .replaceFirst(RegExp(r'^[vV]'), '')
          .split('+')
          .first
          .split('-')
          .first
          .trim();

      final latestParts = cleanLatest.split('.').map((p) => int.tryParse(p.trim()) ?? 0).toList();
      final currentParts = cleanCurrent.split('.').map((p) => int.tryParse(p.trim()) ?? 0).toList();

      final maxLength = latestParts.length > currentParts.length
          ? latestParts.length
          : currentParts.length;

      while (latestParts.length < maxLength) {
        latestParts.add(0);
      }
      while (currentParts.length < maxLength) {
        currentParts.add(0);
      }

      for (int i = 0; i < maxLength; i++) {
        if (latestParts[i] > currentParts[i]) return true;
        if (latestParts[i] < currentParts[i]) return false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Extracts target platform installer asset
  static Map<String, String>? _getAssetData(Map<String, dynamic> releaseJson) {
    try {
      final assets = releaseJson['assets'] as List<dynamic>?;
      if (assets == null || assets.isEmpty) return null;

      dynamic matchedAsset;
      if (Platform.isAndroid) {
        matchedAsset = assets.firstWhere(
          (a) => a['name'].toString().toLowerCase().endsWith('.apk'),
          orElse: () => null,
        );
      } else if (Platform.isWindows) {
        matchedAsset = assets.firstWhere(
          (a) {
            final name = a['name'].toString().toLowerCase();
            return name.endsWith('.exe') ||
                name.endsWith('.zip') ||
                name.contains('setup') ||
                name.contains('windows');
          },
          orElse: () => null,
        );
      }

      if (matchedAsset == null) return null;

      final originalName = matchedAsset['name']?.toString() ?? '';
      final String downloadUrl = matchedAsset['browser_download_url']?.toString() ??
          matchedAsset['url']?.toString() ??
          '';

      String fileName = originalName;
      if (fileName.isEmpty) {
        fileName = Platform.isAndroid ? 'app-release.apk' : 'expense_tracker_setup.exe';
      }

      return {
        'downloadUrl': downloadUrl,
        'fileName': fileName,
      };
    } catch (_) {
      return null;
    }
  }

  /// Downloads update file with resume support & signature validation
  static Future<String?> downloadUpdate(
    String downloadUrl,
    String targetFileName, {
    Function(int received, int total)? onProgress,
    int maxNetworkRetries = 3,
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final filePath = '${dir.path}/$targetFileName';
    final file = File(filePath);

    int attempt = 0;
    while (attempt < maxNetworkRetries) {
      attempt++;
      http.Client? client;
      try {
        final existingBytes = await file.exists() ? await file.length() : 0;
        final request = http.Request('GET', Uri.parse(downloadUrl))..followRedirects = true;
        request.headers['User-Agent'] = 'Hermes-ExpenseTracker-App/1.0';
        request.headers['Accept'] = '*/*';

        if (existingBytes > 0) {
          request.headers['Range'] = 'bytes=$existingBytes-';
        }

        client = http.Client();
        final response = await client.send(request).timeout(const Duration(seconds: 15));

        final isPartial = response.statusCode == 206;
        final isSuccess = response.statusCode == 200 || isPartial;

        if (!isSuccess) {
          throw Exception('Download failed with HTTP ${response.statusCode}');
        }

        int knownTotalBytes = 0;
        final contentLengthHeader = response.headers['content-length'];
        if (contentLengthHeader != null) {
          final parsed = int.tryParse(contentLengthHeader) ?? 0;
          if (parsed > 0) {
            knownTotalBytes = isPartial ? existingBytes + parsed : parsed;
          }
        }

        var currentBytes = isPartial ? existingBytes : 0;
        final sink = file.openWrite(mode: isPartial ? FileMode.append : FileMode.write);

        await response.stream.listen((chunk) {
          currentBytes += chunk.length;
          if (onProgress != null) {
            onProgress(currentBytes, knownTotalBytes);
          }
          sink.add(chunk);
        }).asFuture();

        await sink.close();
        client.close();

        final fileSize = await file.length();
        if (fileSize < 1024 * 50) {
          throw Exception('Downloaded file too small: $fileSize bytes');
        }

        downloadedFilePath = filePath;
        return filePath;
      } catch (e) {
        client?.close();
        debugPrint('Download error on attempt $attempt: $e');
        if (attempt >= maxNetworkRetries) return null;
        await Future.delayed(const Duration(seconds: 2));
      }
    }
    return null;
  }

  /// Installs update across Android and Windows
  static Future<void> installUpdate(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('Update file not found: $filePath');
    }

    if (Platform.isAndroid) {
      const platform = MethodChannel('com.example.expense/update');
      try {
        final result = await platform.invokeMethod<bool>('installApk', {'path': filePath});
        if (result != true) {
          debugPrint('installApk platform channel returned false or null');
        }
      } catch (e) {
        debugPrint('Platform channel installApk error: $e');
      }
    } else if (Platform.isWindows) {
      if (filePath.toLowerCase().endsWith('.zip')) {
        final documentsDir = await getApplicationDocumentsDirectory();
        final appDataDir = documentsDir.parent;
        final extractDir = '${appDataDir.path}\\ExpenseTracker-Update';
        await Directory(extractDir).create(recursive: true);

        final exeFile = _findExecutableSync(extractDir) ??
            '${Directory.current.path}\\expense_tracker.exe';
        final tempDir = await getTemporaryDirectory();
        final batPath = '${tempDir.path}\\run_update.bat';
        final batFile = File(batPath);

        final scriptContent = '''
@echo off
timeout /t 2 /nobreak > NUL
powershell -Command "Expand-Archive -Path '$filePath' -DestinationPath '$extractDir' -Force"
if exist "$exeFile" (
  start "" "$exeFile"
)
del "%~f0"
''';
        await batFile.writeAsString(scriptContent);
        await Process.start('cmd.exe', ['/c', batPath], runInShell: true);
        await Future.delayed(const Duration(milliseconds: 500));
        exit(0);
      } else {
        try {
          await Process.start(
            filePath,
            ['/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART'],
            runInShell: true,
          );
        } catch (e) {
          debugPrint('Process start installer error: $e');
        }
        await Future.delayed(const Duration(milliseconds: 1500));
        exit(0);
      }
    }
  }

  static String? _findExecutableSync(String dirPath) {
    try {
      final dir = Directory(dirPath);
      if (!dir.existsSync()) return null;

      final entities = dir.listSync(recursive: true);
      for (var entity in entities) {
        if (entity is File && entity.path.toLowerCase().endsWith('.exe')) {
          return entity.path;
        }
      }
    } catch (_) {}
    return null;
  }

  static Future<String> getCurrentAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.version;
    } catch (_) {
      return '1.0.0';
    }
  }
}
