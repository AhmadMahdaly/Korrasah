import 'dart:convert';
import 'dart:typed_data';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:opration/features/cloud_backup/data/google_auth_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GoogleDriveBackupService {
  GoogleDriveBackupService({required this.sharedPreferences});

  final SharedPreferences sharedPreferences;

  static const String _backupFileName = 'mezanya_backup.json';
  static const List<String> _scopes = [drive.DriveApi.driveAppdataScope];

  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: _scopes);

  Future<GoogleSignInAccount> signIn() async {
    final currentUser = _googleSignIn.currentUser;
    if (currentUser != null) {
      return currentUser;
    }

    final signedInUser = await _googleSignIn.signIn();
    if (signedInUser == null) {
      throw Exception('Google sign-in was cancelled.');
    }

    return signedInUser;
  }

  Future<GoogleSignInAccount?> getCurrentUser() async {
    return _googleSignIn.currentUser;
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  Future<void> uploadLatestBackup() async {
    final account = await signIn();
    final api = await _createDriveApi(account);
    final payload = _buildBackupPayload();
    final encoded = utf8.encode(
      const JsonEncoder.withIndent('  ').convert(payload),
    );

    final existingFile = await _findExistingBackupFile(api);
    final media = drive.Media(
      Stream<List<int>>.value(encoded),
      encoded.length,
      contentType: 'application/json',
    );

    final metadata = drive.File()
      ..name = _backupFileName
      ..parents = ['appDataFolder']
      ..modifiedTime = DateTime.now().toUtc();

    if (existingFile == null) {
      await api.files.create(
        metadata,
        uploadMedia: media,
      );
      return;
    }

    await api.files.update(
      metadata,
      existingFile.id!,
      uploadMedia: media,
    );
  }

  Future<DateTime?> getLatestBackupModifiedTime() async {
    final currentUser = _googleSignIn.currentUser;
    if (currentUser == null) return null;

    final api = await _createDriveApi(currentUser);
    final existingFile = await _findExistingBackupFile(api);
    return existingFile?.modifiedTime?.toLocal();
  }

  Future<void> restoreLatestBackup() async {
    final account = await signIn();
    final api = await _createDriveApi(account);
    final existingFile = await _findExistingBackupFile(api);

    if (existingFile?.id == null) {
      throw Exception('No backup file was found.');
    }

    final media = await api.files.get(
      existingFile!.id!,
      downloadOptions: drive.DownloadOptions.fullMedia,
    ) as drive.Media;

    final bytes = await _readAllBytes(media.stream);
    final payload = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    await _restoreBackupPayload(payload);
  }

  Map<String, dynamic> _buildBackupPayload() {
    final entries = sharedPreferences.getKeys().map((key) {
      final value = sharedPreferences.get(key);
      return {
        'key': key,
        'type': _resolveType(value),
        'value': value,
      };
    }).toList()
      ..sort((left, right) {
        return (left['key']! as String).compareTo(right['key']! as String);
      });

    return {
      'version': 1,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'entries': entries,
    };
  }

  Future<void> _restoreBackupPayload(Map<String, dynamic> payload) async {
    final entries = payload['entries'];
    if (payload['version'] != 1 || entries is! List) {
      throw Exception('Unsupported backup format.');
    }

    await sharedPreferences.clear();

    for (final item in entries.cast<Map<String, dynamic>>()) {
      final key = item['key'] as String?;
      final type = item['type'] as String?;
      final value = item['value'];

      if (key == null || type == null) {
        continue;
      }

      switch (type) {
        case 'String':
          await sharedPreferences.setString(key, value as String);
        case 'int':
          await sharedPreferences.setInt(key, value as int);
        case 'double':
          await sharedPreferences.setDouble(key, (value as num).toDouble());
        case 'bool':
          await sharedPreferences.setBool(key, value as bool);
        case 'List<String>':
          await sharedPreferences.setStringList(
            key,
            (value as List<dynamic>).map((item) => item.toString()).toList(),
          );
        default:
          throw Exception('Unsupported stored type for key: $key');
      }
    }
  }

  Future<drive.DriveApi> _createDriveApi(GoogleSignInAccount account) async {
    final headers = await account.authHeaders;
    final client = GoogleAuthClient(headers);
    return drive.DriveApi(client);
  }

  Future<drive.File?> _findExistingBackupFile(drive.DriveApi api) async {
    final files = await api.files.list(
      spaces: 'appDataFolder',
      q: "name = '$_backupFileName' and 'appDataFolder' in parents and trashed = false",
      $fields: 'files(id,name,modifiedTime)',
      pageSize: 1,
    );

    if (files.files == null || files.files!.isEmpty) {
      return null;
    }

    return files.files!.first;
  }

  Future<Uint8List> _readAllBytes(Stream<List<int>> stream) async {
    final bytes = <int>[];
    await for (final chunk in stream) {
      bytes.addAll(chunk);
    }
    return Uint8List.fromList(bytes);
  }

  String _resolveType(Object? value) {
    if (value is String) return 'String';
    if (value is int) return 'int';
    if (value is double) return 'double';
    if (value is bool) return 'bool';
    if (value is List<String>) return 'List<String>';
    throw Exception('Unsupported value type: ${value.runtimeType}');
  }
}
