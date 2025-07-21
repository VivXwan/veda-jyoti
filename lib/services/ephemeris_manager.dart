import 'dart:convert';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Manages downloading and local storage of ephemeris files
class EphemerisManager {
  static const String _manifestUrl = 'https://us-central1-veda-jyoti.cloudfunctions.net/get_ephemeris_manifest';
  static const String _storageBasePath = 'ephe';
  
  /// Get the manifest of available ephemeris files from the server
  Future<EphemerisManifest> getManifest() async {
    try {
      final response = await http.get(Uri.parse(_manifestUrl));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return EphemerisManifest.fromJson(data);
      } else {
        throw Exception('Failed to fetch manifest: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching manifest: $e');
    }
  }

  /// Get the local ephemeris directory path
  Future<Directory> getEphemerisDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final epheDir = Directory('${appDir.path}/ephe');
    
    if (!await epheDir.exists()) {
      await epheDir.create(recursive: true);
    }
    
    return epheDir;
  }

  /// Check which files are already downloaded locally
  Future<Set<String>> getDownloadedFiles() async {
    try {
      final epheDir = await getEphemerisDirectory();
      final files = await epheDir.list().toList();
      
      return files
          .where((file) => file is File && file.path.endsWith('.se1'))
          .map((file) => file.path.split('/').last)
          .toSet();
    } catch (e) {
      return <String>{};
    }
  }

  /// Get the current status of all ephemeris files
  Future<List<EphemerisFileStatus>> getFileStatuses() async {
    try {
      final manifest = await getManifest();
      final downloadedFiles = await getDownloadedFiles();
      
      return manifest.files.map((file) {
        final isDownloaded = downloadedFiles.contains(file.fileName);
        final isDefault = manifest.defaultFiles.contains(file.fileName);
        
        return EphemerisFileStatus(
          file: file,
          isDownloaded: isDownloaded,
          isDefault: isDefault,
          downloadStatus: DownloadStatus.idle,
        );
      }).toList();
    } catch (e) {
      throw Exception('Error getting file statuses: $e');
    }
  }

  /// Download a specific ephemeris file
  Future<bool> downloadFile(EphemerisFile file, {
    Function(double progress)? onProgress,
  }) async {
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('$_storageBasePath/${file.fileName}');
      
      final epheDir = await getEphemerisDirectory();
      final localFile = File('${epheDir.path}/${file.fileName}');
      
      // If file already exists, return true
      if (await localFile.exists()) {
        return true;
      }
      
      // Download the file
      final downloadTask = storageRef.writeToFile(localFile);
      
      // Monitor progress if callback provided
      if (onProgress != null) {
        downloadTask.snapshotEvents.listen((taskSnapshot) {
          final progress = taskSnapshot.bytesTransferred / taskSnapshot.totalBytes;
          onProgress(progress);
        });
      }
      
      await downloadTask;
      return true;
    } catch (e) {
      throw Exception('Failed to download ${file.fileName}: $e');
    }
  }

  /// Delete a downloaded ephemeris file
  Future<bool> deleteFile(String fileName) async {
    try {
      final epheDir = await getEphemerisDirectory();
      final file = File('${epheDir.path}/$fileName');
      
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      
      return false;
    } catch (e) {
      throw Exception('Failed to delete $fileName: $e');
    }
  }

  /// Copy bundled ephemeris files to local storage on first run
  Future<void> copyBundledFiles(List<String> bundledAssets) async {
    try {
      final epheDir = await getEphemerisDirectory();
      
      for (final assetPath in bundledAssets) {
        final fileName = assetPath.split('/').last;
        final localFile = File('${epheDir.path}/$fileName');
        
        // Only copy if file doesn't exist locally
        if (!await localFile.exists()) {
          // Note: This would require implementing asset copying
          // For now, we'll assume the files are provided through the download mechanism
        }
      }
    } catch (e) {
      throw Exception('Failed to copy bundled files: $e');
    }
  }
}

/// Data models for ephemeris management

class EphemerisManifest {
  final String version;
  final DateTime lastUpdated;
  final List<String> defaultFiles;
  final List<EphemerisFile> files;

  EphemerisManifest({
    required this.version,
    required this.lastUpdated,
    required this.defaultFiles,
    required this.files,
  });

  factory EphemerisManifest.fromJson(Map<String, dynamic> json) {
    return EphemerisManifest(
      version: json['version'] ?? '1.0.0',
      lastUpdated: DateTime.parse(json['lastUpdated'] ?? DateTime.now().toIso8601String()),
      defaultFiles: List<String>.from(json['defaultFiles'] ?? []),
      files: (json['files'] as List<dynamic>)
          .map((fileJson) => EphemerisFile.fromJson(fileJson))
          .toList(),
    );
  }
}

class EphemerisFile {
  final String fileName;
  final int yearStart;
  final int yearEnd;
  final String description;
  final int size;
  final String type;
  final String priority;

  EphemerisFile({
    required this.fileName,
    required this.yearStart,
    required this.yearEnd,
    required this.description,
    required this.size,
    required this.type,
    required this.priority,
  });

  factory EphemerisFile.fromJson(Map<String, dynamic> json) {
    return EphemerisFile(
      fileName: json['fileName'],
      yearStart: json['yearStart'],
      yearEnd: json['yearEnd'],
      description: json['description'],
      size: json['size'],
      type: json['type'],
      priority: json['priority'],
    );
  }

  String get sizeDisplay {
    if (size < 1024) return '${size}B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)}KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  String get dateRange => '$yearStart-$yearEnd';
}

enum DownloadStatus {
  idle,
  downloading,
  completed,
  error,
}

class EphemerisFileStatus {
  final EphemerisFile file;
  final bool isDownloaded;
  final bool isDefault;
  final DownloadStatus downloadStatus;
  final double downloadProgress;

  EphemerisFileStatus({
    required this.file,
    required this.isDownloaded,
    required this.isDefault,
    required this.downloadStatus,
    this.downloadProgress = 0.0,
  });

  EphemerisFileStatus copyWith({
    EphemerisFile? file,
    bool? isDownloaded,
    bool? isDefault,
    DownloadStatus? downloadStatus,
    double? downloadProgress,
  }) {
    return EphemerisFileStatus(
      file: file ?? this.file,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      isDefault: isDefault ?? this.isDefault,
      downloadStatus: downloadStatus ?? this.downloadStatus,
      downloadProgress: downloadProgress ?? this.downloadProgress,
    );
  }
}

/// Riverpod providers for ephemeris management

final ephemerisManagerProvider = Provider<EphemerisManager>((ref) {
  return EphemerisManager();
});

final ephemerisFileStatusesProvider = FutureProvider<List<EphemerisFileStatus>>((ref) async {
  final manager = ref.read(ephemerisManagerProvider);
  return await manager.getFileStatuses();
});

final downloadedFilesProvider = FutureProvider<Set<String>>((ref) async {
  final manager = ref.read(ephemerisManagerProvider);
  return await manager.getDownloadedFiles();
});