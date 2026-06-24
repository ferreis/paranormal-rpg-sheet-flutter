import 'dart:io';
import 'dart:typed_data';

import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/character_sheet.dart';
import 'character_pdf_export_service.dart';

class CharacterFileExportService {
  CharacterFileExportService({CharacterPdfExportService? pdfExportService})
    : _pdfExportService = pdfExportService ?? CharacterPdfExportService();

  final CharacterPdfExportService _pdfExportService;

  Future<File> createEditablePdfFile(CharacterSheet characterSheet) async {
    final Uint8List pdfBytes = await _pdfExportService.buildEditablePdf(
      characterSheet,
    );
    final Directory exportDirectory = await _exportDirectory();
    final String fileName =
        '${_safeFileName(characterSheet.characterName)}-ficha-editável.pdf';
    final File pdfFile = File(path.join(exportDirectory.path, fileName));

    return pdfFile.writeAsBytes(pdfBytes, flush: true);
  }

  Future<File> createShareableCharacterFile({
    required String characterName,
    required String jsonContent,
  }) async {
    final Directory exportDirectory = await _exportDirectory();
    final String fileName = '${_safeFileName(characterName)}.ordemficha';
    final File characterFile = File(path.join(exportDirectory.path, fileName));

    return characterFile.writeAsString(jsonContent, flush: true);
  }

  Future<void> shareFile({
    required File file,
    required String subject,
    String? text,
  }) async {
    await SharePlus.instance.share(
      ShareParams(
        files: <XFile>[XFile(file.path)],
        subject: subject,
        text: text,
      ),
    );
  }

  Future<OpenResult> openFile(File file) {
    return OpenFilex.open(file.path);
  }

  Future<Directory> _exportDirectory() async {
    final Directory temporaryDirectory = await getTemporaryDirectory();
    final Directory exportDirectory = Directory(
      path.join(temporaryDirectory.path, 'ordem_fichas_exports'),
    );

    if (!await exportDirectory.exists()) {
      await exportDirectory.create(recursive: true);
    }

    return exportDirectory;
  }

  String _safeFileName(String value) {
    final String normalizedValue = value.trim().isEmpty
        ? 'personagem'
        : value.trim();
    final String safeFileName = normalizedValue
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_-]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');

    return safeFileName.isEmpty ? 'personagem' : safeFileName;
  }
}
