import 'package:flutter/material.dart';
import 'package:opration/core/di.dart';
import 'package:opration/core/responsive/responsive_config.dart';
import 'package:opration/core/shared_widgets/page_header.dart';
import 'package:opration/core/theme/colors.dart';
import 'package:opration/features/cloud_backup/data/google_drive_backup_service.dart';
import 'package:opration/features/cloud_backup/presentation/app_state_reloader.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CloudBackupScreen extends StatefulWidget {
  const CloudBackupScreen({super.key});

  @override
  State<CloudBackupScreen> createState() => _CloudBackupScreenState();
}

class _CloudBackupScreenState extends State<CloudBackupScreen> {
  late final GoogleDriveBackupService _service;
  bool _isBusy = false;
  String? _accountEmail;
  DateTime? _lastBackupAt;

  @override
  void initState() {
    super.initState();
    _service = GoogleDriveBackupService(
      sharedPreferences: getIt<SharedPreferences>(),
    );
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final user = await _service.getCurrentUser();
    final lastBackupAt = await _service.getLatestBackupModifiedTime();
    if (!mounted) return;
    setState(() {
      _accountEmail = user?.email;
      _lastBackupAt = lastBackupAt;
    });
  }

  Future<void> _runAction(Future<void> Function() action) async {
    setState(() => _isBusy = true);
    try {
      await action();
      await _loadStatus();
    } catch (error) {
      if (!mounted) return;
      _showMessage(error.toString());
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  Future<void> _connectGoogle() async {
    await _runAction(() async {
      final user = await _service.signIn();
      _showMessage('Connected as ${user.email}');
    });
  }

  Future<void> _uploadBackup() async {
    await _runAction(() async {
      await _service.uploadLatestBackup();
      _showMessage('Backup uploaded to Google Drive.');
    });
  }

  Future<void> _restoreBackup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Restore latest backup'),
          content: const Text(
            'This replaces the current local data with the latest backup from Google Drive.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Restore'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await _runAction(() async {
      await _service.restoreLatestBackup();
      if (!mounted) return;
      await AppStateReloader.reloadAll(context);
      _showMessage('Backup restored from Google Drive.');
    });
  }

  Future<void> _disconnectGoogle() async {
    await _runAction(() async {
      await _service.signOut();
      if (!mounted) return;
      setState(() {
        _accountEmail = null;
        _lastBackupAt = null;
      });
      _showMessage('Google account disconnected.');
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final lastBackupText = _lastBackupAt == null
        ? 'No backup uploaded yet'
        : '${_lastBackupAt!.year}-${_lastBackupAt!.month.toString().padLeft(2, '0')}-${_lastBackupAt!.day.toString().padLeft(2, '0')} ${_lastBackupAt!.hour.toString().padLeft(2, '0')}:${_lastBackupAt!.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: const PageHeader(
        isLeading: true,
        title: 'Cloud Backup',
      ),
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.all(16.r),
            children: [
              _InfoCard(
                title: 'Google account',
                body: _accountEmail ?? 'Not connected',
              ),
              12.verticalSpace,
              _InfoCard(
                title: 'Latest backup on Drive',
                body: lastBackupText,
              ),
              20.verticalSpace,
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isBusy ? null : _connectGoogle,
                  icon: const Icon(Icons.account_circle_outlined),
                  label: Text(
                    _accountEmail == null ? 'Connect Google account' : 'Reconnect Google account',
                  ),
                ),
              ),
              12.verticalSpace,
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isBusy ? null : _uploadBackup,
                  icon: const Icon(Icons.cloud_upload_outlined),
                  label: const Text('Upload latest backup'),
                ),
              ),
              12.verticalSpace,
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isBusy ? null : _restoreBackup,
                  icon: const Icon(Icons.cloud_download_outlined),
                  label: const Text('Restore latest backup'),
                ),
              ),
              12.verticalSpace,
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isBusy || _accountEmail == null
                      ? null
                      : _disconnectGoogle,
                  icon: const Icon(Icons.logout),
                  label: const Text('Disconnect Google account'),
                ),
              ),
              20.verticalSpace,
              Text(
                'This feature stores one manual backup file inside your Google Drive app data folder.',
                style: TextStyle(
                  color: AppColors.textGreyColor,
                  fontSize: 12.sp,
                  height: 1.5,
                ),
              ),
            ],
          ),
          if (_isBusy)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withAlpha(25),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.black.withAlpha(12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14.sp,
            ),
          ),
          8.verticalSpace,
          Text(
            body,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 13.sp,
            ),
          ),
        ],
      ),
    );
  }
}
