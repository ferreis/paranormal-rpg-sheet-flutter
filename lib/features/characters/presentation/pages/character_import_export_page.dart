import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../../data/models/character_sheet.dart';
import '../../data/repositories/character_repository.dart';
import '../../data/services/character_file_export_service.dart';

class CharacterImportExportPage extends StatefulWidget {
  CharacterImportExportPage({
    required this.repository,
    this.characterId,
    CharacterFileExportService? fileExportService,
    super.key,
  }) : fileExportService = fileExportService ?? CharacterFileExportService();

  final CharacterRepository repository;
  final int? characterId;
  final CharacterFileExportService fileExportService;

  @override
  State<CharacterImportExportPage> createState() =>
      _CharacterImportExportPageState();
}

class _CharacterImportExportPageState extends State<CharacterImportExportPage> {
  final TextEditingController jsonController = TextEditingController();
  final TextEditingController crisUrlController = TextEditingController();
  bool isLoading = false;
  String? message;

  @override
  void initState() {
    super.initState();
    _loadExport();
  }

  @override
  void dispose() {
    jsonController.dispose();
    crisUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadExport() async {
    final int? characterId = widget.characterId;

    if (characterId == null) {
      return;
    }

    setState(() {
      isLoading = true;
      message = null;
    });

    try {
      jsonController.text = await widget.repository.exportCharacterAsJson(
        characterId,
      );
    } catch (exception) {
      message = 'Não foi possível exportar a ficha.';
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<CharacterSheet> _loadCurrentCharacter() async {
    final int? characterId = widget.characterId;

    if (characterId == null) {
      throw StateError('Ficha não informada.');
    }

    final CharacterSheet? characterSheet = await widget.repository.getCharacter(
      characterId,
    );

    if (characterSheet == null) {
      throw StateError('Ficha não encontrada.');
    }

    return characterSheet;
  }

  Future<void> _importJson() async {
    setState(() {
      isLoading = true;
      message = null;
    });

    try {
      await widget.repository.importCharacterFromJson(jsonController.text);

      if (!mounted) {
        return;
      }

      setState(() {
        message = 'Ficha importada.';
      });
    } catch (exception) {
      if (!mounted) {
        return;
      }

      setState(() {
        message = 'JSON invalido ou incompleto.';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _importFile() async {
    setState(() {
      isLoading = true;
      message = null;
    });

    try {
      const XTypeGroup characterFileType = XTypeGroup(
        label: 'Ficha Ordem',
        extensions: <String>['ordemficha', 'json'],
      );
      final XFile? selectedFile = await openFile(
        acceptedTypeGroups: <XTypeGroup>[characterFileType],
      );

      if (selectedFile == null) {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
        return;
      }

      final String jsonContent = await selectedFile.readAsString();
      await widget.repository.importCharacterFromJson(jsonContent);

      if (!mounted) {
        return;
      }

      setState(() {
        message = 'Arquivo importado.';
      });
    } catch (exception) {
      if (!mounted) {
        return;
      }

      setState(() {
        message = 'Não foi possível importar o arquivo.';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _importCrisUrl() async {
    setState(() {
      isLoading = true;
      message = null;
    });

    try {
      await widget.repository.importCharacterFromCrisUrl(
        crisUrlController.text,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        message = 'Ficha C.R.I.S. importada.';
      });
    } catch (exception) {
      if (!mounted) {
        return;
      }

      setState(() {
        message =
            'Não foi possível importar do C.R.I.S. Verifique se o link é público.';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _openEditablePdf() async {
    await _createPdf(shareAfterCreate: false);
  }

  Future<void> _shareEditablePdf() async {
    await _createPdf(shareAfterCreate: true);
  }

  Future<void> _createPdf({required bool shareAfterCreate}) async {
    setState(() {
      isLoading = true;
      message = null;
    });

    try {
      final CharacterSheet characterSheet = await _loadCurrentCharacter();
      final File pdfFile = await widget.fileExportService.createEditablePdfFile(
        characterSheet,
      );

      if (shareAfterCreate) {
        await widget.fileExportService.shareFile(
          file: pdfFile,
          subject: 'Ficha ${characterSheet.characterName}',
          text: 'Ficha editável em PDF.',
        );
      } else {
        await widget.fileExportService.openFile(pdfFile);
      }

      if (!mounted) {
        return;
      }

      setState(() {
        message = shareAfterCreate
            ? 'PDF pronto para compartilhar.'
            : 'PDF editável gerado.';
      });
    } catch (exception) {
      if (!mounted) {
        return;
      }

      setState(() {
        message = 'Não foi possível gerar o PDF.';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _shareCharacterFile() async {
    setState(() {
      isLoading = true;
      message = null;
    });

    try {
      final CharacterSheet characterSheet = await _loadCurrentCharacter();
      final String jsonContent = jsonController.text.trim().isEmpty
          ? await widget.repository.exportCharacterAsJson(widget.characterId!)
          : jsonController.text;
      final File characterFile = await widget.fileExportService
          .createShareableCharacterFile(
            characterName: characterSheet.characterName,
            jsonContent: jsonContent,
          );

      await widget.fileExportService.shareFile(
        file: characterFile,
        subject: 'Ficha ${characterSheet.characterName}',
        text: 'Arquivo para importar no app Fichas Ordem.',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        message = 'Ficha pronta para compartilhar.';
      });
    } catch (exception) {
      if (!mounted) {
        return;
      }

      setState(() {
        message = 'Não foi possível compartilhar a ficha.';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isExportMode = widget.characterId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isExportMode ? 'Exportar ficha' : 'Importar ficha'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: <Widget>[
            if (isLoading) const LinearProgressIndicator(),
            if (message != null) ...<Widget>[
              Text(message!),
              const SizedBox(height: 8),
            ],
            if (!isExportMode) ...<Widget>[
              TextField(
                controller: crisUrlController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Link da ficha C.R.I.S.',
                  hintText: 'https://crisordemparanormal.com/agente/...',
                ),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: isLoading ? null : _importCrisUrl,
                icon: const Icon(Icons.link),
                label: const Text('Importar do C.R.I.S.'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: isLoading ? null : _importFile,
                icon: const Icon(Icons.file_open_outlined),
                label: const Text('Importar arquivo recebido'),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
            ],
            if (isExportMode) ...<Widget>[
              FilledButton.icon(
                onPressed: isLoading ? null : _openEditablePdf,
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: const Text('Gerar PDF editável'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: isLoading ? null : _shareEditablePdf,
                icon: const Icon(Icons.ios_share_outlined),
                label: const Text('Compartilhar PDF'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: isLoading ? null : _shareCharacterFile,
                icon: const Icon(Icons.bluetooth_outlined),
                label: const Text('Compartilhar ficha do app'),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
            ],
            TextField(
              controller: jsonController,
              minLines: 16,
              maxLines: 28,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'JSON da ficha',
              ),
            ),
            const SizedBox(height: 12),
            if (!isExportMode)
              FilledButton.icon(
                onPressed: isLoading ? null : _importJson,
                icon: const Icon(Icons.upload_file_outlined),
                label: const Text('Importar ficha'),
              ),
          ],
        ),
      ),
    );
  }
}
