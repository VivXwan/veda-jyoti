import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/ephemeris_manager.dart';

class EphemerisSettingsPage extends ConsumerStatefulWidget {
  const EphemerisSettingsPage({super.key});

  @override
  ConsumerState<EphemerisSettingsPage> createState() => _EphemerisSettingsPageState();
}

class _EphemerisSettingsPageState extends ConsumerState<EphemerisSettingsPage> {
  final Map<String, double> _downloadProgress = {};
  final Map<String, DownloadStatus> _downloadStatuses = {};

  @override
  Widget build(BuildContext context) {
    final fileStatusesAsync = ref.watch(ephemerisFileStatusesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ephemeris Files'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: fileStatusesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading ephemeris files',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(ephemerisFileStatusesProvider);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (fileStatuses) => _buildFileList(context, fileStatuses),
      ),
    );
  }

  Widget _buildFileList(BuildContext context, List<EphemerisFileStatus> fileStatuses) {
    // Group files by type
    final Map<String, List<EphemerisFileStatus>> groupedFiles = {};
    for (final status in fileStatuses) {
      final type = status.file.type;
      groupedFiles.putIfAbsent(type, () => []).add(status);
    }

    // Sort groups by priority
    final sortedGroups = groupedFiles.entries.toList()
      ..sort((a, b) {
        const typePriority = {
          'planets': 0,
          'moon': 1,
          'supplementary': 2,
        };
        return (typePriority[a.key] ?? 999).compareTo(typePriority[b.key] ?? 999);
      });

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(ephemerisFileStatusesProvider);
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sortedGroups.length,
        itemBuilder: (context, groupIndex) {
          final groupEntry = sortedGroups[groupIndex];
          final groupName = groupEntry.key;
          final files = groupEntry.value;

          // Sort files within group by year
          files.sort((a, b) => a.file.yearStart.compareTo(b.file.yearStart));

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (groupIndex > 0) const SizedBox(height: 24),
              _buildGroupHeader(context, groupName, files),
              const SizedBox(height: 8),
              ...files.map((status) => _buildFileCard(context, status)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGroupHeader(BuildContext context, String groupName, List<EphemerisFileStatus> files) {
    final downloadedCount = files.where((f) => f.isDownloaded).length;
    final totalCount = files.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              _getGroupIcon(groupName),
              size: 32,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getGroupDisplayName(groupName),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  Text(
                    '$downloadedCount of $totalCount files downloaded',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (downloadedCount < totalCount)
              TextButton(
                onPressed: () => _downloadAllInGroup(files),
                child: const Text('Download All'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileCard(BuildContext context, EphemerisFileStatus status) {
    final currentStatus = _downloadStatuses[status.file.fileName] ?? status.downloadStatus;
    final progress = _downloadProgress[status.file.fileName] ?? 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: _buildFileIcon(status, currentStatus),
        title: Text(
          status.file.fileName,
          style: const TextStyle(fontFamily: 'monospace'),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(status.file.description),
            Text(
              '${status.file.dateRange} • ${status.file.sizeDisplay}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (currentStatus == DownloadStatus.downloading)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
              ),
          ],
        ),
        trailing: _buildActionButton(context, status, currentStatus),
        isThreeLine: currentStatus == DownloadStatus.downloading,
      ),
    );
  }

  Widget _buildFileIcon(EphemerisFileStatus status, DownloadStatus currentStatus) {
    if (currentStatus == DownloadStatus.downloading) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (status.isDownloaded) {
      return Icon(
        status.isDefault ? Icons.check_circle : Icons.download_done,
        color: Colors.green,
      );
    }

    return Icon(
      status.isDefault ? Icons.priority_high : Icons.cloud_download,
      color: status.isDefault ? Colors.orange : Colors.grey,
    );
  }

  Widget _buildActionButton(BuildContext context, EphemerisFileStatus status, DownloadStatus currentStatus) {
    if (currentStatus == DownloadStatus.downloading) {
      return IconButton(
        icon: const Icon(Icons.cancel),
        onPressed: () {
          // Cancel download (implementation needed)
        },
      );
    }

    if (status.isDownloaded) {
      if (status.isDefault) {
        return const Icon(Icons.lock, color: Colors.grey);
      }
      return IconButton(
        icon: const Icon(Icons.delete),
        onPressed: () => _deleteFile(status.file),
      );
    }

    return IconButton(
      icon: const Icon(Icons.download),
      onPressed: () => _downloadFile(status.file),
    );
  }

  Future<void> _downloadFile(EphemerisFile file) async {
    setState(() {
      _downloadStatuses[file.fileName] = DownloadStatus.downloading;
      _downloadProgress[file.fileName] = 0.0;
    });

    try {
      final manager = ref.read(ephemerisManagerProvider);
      await manager.downloadFile(
        file,
        onProgress: (progress) {
          setState(() {
            _downloadProgress[file.fileName] = progress;
          });
        },
      );

      setState(() {
        _downloadStatuses[file.fileName] = DownloadStatus.completed;
      });

      // Refresh the file list
      ref.invalidate(ephemerisFileStatusesProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Downloaded ${file.fileName}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _downloadStatuses[file.fileName] = DownloadStatus.error;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download ${file.fileName}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteFile(EphemerisFile file) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete File'),
        content: Text('Are you sure you want to delete ${file.fileName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final manager = ref.read(ephemerisManagerProvider);
        await manager.deleteFile(file.fileName);

        // Refresh the file list
        ref.invalidate(ephemerisFileStatusesProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Deleted ${file.fileName}'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete ${file.fileName}: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _downloadAllInGroup(List<EphemerisFileStatus> files) async {
    final filesToDownload = files
        .where((status) => !status.isDownloaded)
        .map((status) => status.file)
        .toList();

    for (final file in filesToDownload) {
      await _downloadFile(file);
    }
  }

  IconData _getGroupIcon(String groupName) {
    switch (groupName) {
      case 'planets':
        return Icons.public;
      case 'moon':
        return Icons.brightness_3;
      case 'supplementary':
        return Icons.star;
      default:
        return Icons.folder;
    }
  }

  String _getGroupDisplayName(String groupName) {
    switch (groupName) {
      case 'planets':
        return 'Planetary Data';
      case 'moon':
        return 'Lunar Data';
      case 'supplementary':
        return 'Supplementary Files';
      default:
        return groupName.toUpperCase();
    }
  }
}