import 'dart:io';
import 'package:flutter/services.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class GDriveService {
  static final GDriveService _instance = GDriveService._internal();
  factory GDriveService() => _instance;
  GDriveService._internal();

  drive.DriveApi? _driveApi;
  AutoRefreshingAuthClient? _authClient;

  /* ================= INITIALIZE ================= */

  Future<void> initialize() async {
    if (_driveApi != null) return;

    try {
      final jsonString = await rootBundle.loadString(
        'assets/credentials/service_account.json',
      );

      final credentials = ServiceAccountCredentials.fromJson(jsonString);

      _authClient = await clientViaServiceAccount(
        credentials,
        [drive.DriveApi.driveReadonlyScope],
      );

      _driveApi = drive.DriveApi(_authClient!);
      print('Google Drive API initialized successfully');
    } catch (e) {
      print('Google Drive API initialization error: $e');
    }
  }

  bool get isReady => _driveApi != null;

  /* ================= METADATA ================= */

  Future<drive.File?> getFileMetadata(String fileId) async {
    if (_driveApi == null) await initialize();
    if (_driveApi == null) return null;

    try {
      return await _driveApi!.files.get(
        fileId,
        $fields:
            'id,name,mimeType,size,thumbnailLink,webContentLink,webViewLink',
      ) as drive.File;
    } catch (e) {
      print('Get file metadata error: $e');
      return null;
    }
  }

  /* ================= URL HELPERS ================= */

  String getDirectDownloadUrl(String fileId) =>
      'https://drive.google.com/uc?export=download&id=$fileId';

  String getPreviewUrl(String fileId) =>
      'https://drive.google.com/file/d/$fileId/preview';

  String getEmbedUrl(String fileId) =>
      'https://drive.google.com/file/d/$fileId/preview';

  String getThumbnailUrl(String fileId, {int size = 220}) =>
      'https://drive.google.com/thumbnail?id=$fileId&sz=s$size';

  /* ================= DOWNLOAD FILE (EXISTING) ================= */

  Future<File?> downloadFile(String fileId, String fileName) async {
    if (_driveApi == null) await initialize();
    if (_driveApi == null) return null;

    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$fileName');

      if (await file.exists()) return file;

      final media = await _driveApi!.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final bytes = <int>[];
      await for (final chunk in media.stream) {
        bytes.addAll(chunk);
      }

      await file.writeAsBytes(bytes, flush: true);
      return file;
    } catch (e) {
      print('Download file error: $e');
      return null;
    }
  }

  /* ================= LIST FILES ================= */

  Future<List<drive.File>> listFilesInFolder(String folderId) async {
    if (_driveApi == null) await initialize();
    if (_driveApi == null) return [];

    try {
      final fileList = await _driveApi!.files.list(
        q: "'$folderId' in parents",
        $fields: 'files(id,name,mimeType,size,thumbnailLink,createdTime)',
        orderBy: 'name',
      );
      return fileList.files ?? [];
    } catch (e) {
      print('List files error: $e');
      return [];
    }
  }

  /* ================= PDF BYTES (EXISTING) ================= */

  Future<List<int>?> getPdfBytes(String fileId) async {
    if (_driveApi == null) await initialize();
    if (_driveApi == null) return null;

    try {
      final media = await _driveApi!.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final bytes = <int>[];
      await for (final chunk in media.stream) {
        bytes.addAll(chunk);
      }
      return bytes;
    } catch (e) {
      print('Get PDF bytes error: $e');
      return null;
    }
  }

  Future<List<int>?> getImageBytes(String fileId) async {
    return getPdfBytes(fileId);
  }

  Future<bool> fileExists(String fileId) async {
    final metadata = await getFileMetadata(fileId);
    return metadata != null;
  }

  /* =========================================================
     🔥 NEW — PDF CACHE SUPPORT (UNTUK MODULE DETAIL)
     ========================================================= */

  /// ✅ Ambil PDF dari cache → download jika belum ada
  Future<File> getCachedPdfFile(String fileId) async {
    if (_driveApi == null) await initialize();
    if (_driveApi == null) {
      throw Exception('Google Drive API belum siap');
    }

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileId.pdf');

    // ✅ cache hit
    if (await file.exists()) {
      return file;
    }

    try {
      final meta = await _driveApi!.files.get(
        fileId,
        $fields: 'id,name,mimeType',
      ) as drive.File;

      final bytes = <int>[];

      // 🔥 Google Docs → export PDF
      if (meta.mimeType != null &&
          meta.mimeType!.startsWith('application/vnd.google-apps')) {
        final media = await _driveApi!.files.export(
          fileId,
          'application/pdf',
        ) as drive.Media;

        await for (final chunk in media.stream) {
          bytes.addAll(chunk);
        }
      }
      // 📄 PDF asli
      else {
        final media = await _driveApi!.files.get(
          fileId,
          downloadOptions: drive.DownloadOptions.fullMedia,
        ) as drive.Media;

        await for (final chunk in media.stream) {
          bytes.addAll(chunk);
        }
      }

      if (bytes.isEmpty) {
        throw Exception('PDF hasil download kosong');
      }

      await file.writeAsBytes(bytes, flush: true);
      return file;
    } catch (e) {
      throw Exception('Gagal download PDF: $e');
    }
  }

  Future<Uint8List> getCachedPdfBytes(String fileId) async {
    final file = await getCachedPdfFile(fileId);

    final bytes = await file.readAsBytes();

    if (bytes.isEmpty) {
      throw Exception('PDF bytes kosong setelah cache');
    }

    print('PDF OK → size: ${bytes.length} bytes');
    return bytes;
  }

  /// (Optional) hapus cache PDF
  Future<void> clearCachedPdf(String fileId) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileId.pdf');
    if (await file.exists()) {
      await file.delete();
    }
  }

  /* ================= DISPOSE ================= */

  void dispose() {
    _authClient?.close();
  }
}

/* ================= AUTH CLIENT ================= */

class AuthenticatedClient extends http.BaseClient {
  final http.Client _baseClient;
  final String _accessToken;

  AuthenticatedClient(this._baseClient, this._accessToken);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Authorization'] = 'Bearer $_accessToken';
    return _baseClient.send(request);
  }
}
