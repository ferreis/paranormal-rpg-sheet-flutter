import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:ordem_fichas/features/characters/data/services/sheet_file_service.dart';
import 'package:ordem_fichas/features/characters/data/services/sheet_qr_service.dart';
import 'package:ordem_fichas/features/characters/domain/entities/character_sheet.dart';
import 'package:ordem_fichas/features/characters/domain/repositories/character_repository.dart';
import 'package:qr_flutter/qr_flutter.dart';

enum _CharacterShareOption { bluetooth, qrCode, whatsApp, email }

class SheetTransferPage extends StatefulWidget {
  SheetTransferPage({
    required this.repository,
    this.characterId,
    SheetFileService? fileExportService,
    SheetQrService? qrService,
    super.key,
  }) : fileExportService = fileExportService ?? SheetFileService(),
       qrService = qrService ?? SheetQrService();

  final CharacterRepository repository;
  final int? characterId;
  final SheetFileService fileExportService;
  final SheetQrService qrService;

  @override
  State<SheetTransferPage> createState() => _SheetTransferPageState();
}

class _SheetTransferPageState extends State<SheetTransferPage> {
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

  Future<void> _importQrCode() async {
    final String? qrPayload = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (BuildContext context) =>
            _SheetQrScannerPage(qrService: widget.qrService),
      ),
    );

    if (!mounted || qrPayload == null) {
      return;
    }

    setState(() {
      isLoading = true;
      message = null;
    });

    try {
      final String jsonContent = widget.qrService.decodePayload(qrPayload);
      await widget.repository.importCharacterFromJson(jsonContent);

      if (!mounted) {
        return;
      }

      jsonController.text = jsonContent;
      setState(() {
        message = 'Ficha importada por QR Code.';
      });
    } catch (exception) {
      if (!mounted) {
        return;
      }

      setState(() {
        message = 'QR Code inválido ou incompleto.';
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

  Future<String> _currentJsonContent() async {
    final int? characterId = widget.characterId;

    if (characterId == null) {
      throw StateError('Ficha não informada.');
    }

    final String currentJsonContent = jsonController.text.trim();

    if (currentJsonContent.isNotEmpty) {
      return currentJsonContent;
    }

    return widget.repository.exportCharacterAsJson(characterId);
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

  Future<void> _openCharacterShareOptions() async {
    final _CharacterShareOption? selectedShareOption =
        await showModalBottomSheet<_CharacterShareOption>(
          context: context,
          builder: (BuildContext bottomSheetContext) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  ListTile(
                    leading: const Icon(Icons.bluetooth_outlined),
                    title: const Text('Bluetooth'),
                    onTap: () => Navigator.of(
                      bottomSheetContext,
                    ).pop(_CharacterShareOption.bluetooth),
                  ),
                  ListTile(
                    leading: const Icon(Icons.qr_code_2_outlined),
                    title: const Text('QR Code'),
                    onTap: () => Navigator.of(
                      bottomSheetContext,
                    ).pop(_CharacterShareOption.qrCode),
                  ),
                  ListTile(
                    leading: const Icon(Icons.chat_outlined),
                    title: const Text('WhatsApp'),
                    onTap: () => Navigator.of(
                      bottomSheetContext,
                    ).pop(_CharacterShareOption.whatsApp),
                  ),
                  ListTile(
                    leading: const Icon(Icons.email_outlined),
                    title: const Text('E-mail'),
                    onTap: () => Navigator.of(
                      bottomSheetContext,
                    ).pop(_CharacterShareOption.email),
                  ),
                ],
              ),
            );
          },
        );

    if (!mounted || selectedShareOption == null) {
      return;
    }

    if (selectedShareOption == _CharacterShareOption.qrCode) {
      await _showCharacterQrCode();
      return;
    }

    await _shareCharacterFile(selectedShareOption);
  }

  Future<void> _shareCharacterFile(
    _CharacterShareOption selectedShareOption,
  ) async {
    setState(() {
      isLoading = true;
      message = null;
    });

    try {
      final CharacterSheet characterSheet = await _loadCurrentCharacter();
      final String jsonContent = _compactJsonContent(
        await _currentJsonContent(),
      );
      final File characterFile = await widget.fileExportService
          .createShareableCharacterFile(
            characterName: characterSheet.characterName,
            jsonContent: jsonContent,
          );

      await widget.fileExportService.shareFile(
        file: characterFile,
        subject: 'Ficha ${characterSheet.characterName}',
        text: _shareTextFor(selectedShareOption),
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

  String _compactJsonContent(String jsonContent) {
    try {
      return jsonEncode(jsonDecode(jsonContent));
    } on FormatException {
      return jsonContent;
    }
  }

  Future<void> _showCharacterQrCode() async {
    bool shouldResetLoading = true;

    setState(() {
      isLoading = true;
      message = null;
    });

    try {
      final CharacterSheet characterSheet = await _loadCurrentCharacter();
      final List<String> qrPayloads = widget.qrService.encodeJsonParts(
        await _currentJsonContent(),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        isLoading = false;
        message = 'QR Code pronto para compartilhar.';
      });
      shouldResetLoading = false;

      await showDialog<void>(
        context: context,
        builder: (BuildContext dialogContext) {
          return _CharacterQrCodeDialog(
            characterName: characterSheet.characterName,
            qrPayloads: qrPayloads,
          );
        },
      );
    } catch (exception) {
      if (!mounted) {
        return;
      }

      setState(() {
        message = 'Não foi possível gerar o QR Code.';
      });
    } finally {
      if (mounted && shouldResetLoading) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  String _shareTextFor(_CharacterShareOption selectedShareOption) {
    return switch (selectedShareOption) {
      _CharacterShareOption.bluetooth =>
        'Arquivo para importar no app Fichas Ordem.',
      _CharacterShareOption.whatsApp =>
        'Ficha para importar no app Fichas Ordem.',
      _CharacterShareOption.email =>
        'Segue a ficha para importar no app Fichas Ordem.',
      _CharacterShareOption.qrCode =>
        'Ficha para importar no app Fichas Ordem.',
    };
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
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: isLoading ? null : _importQrCode,
                icon: const Icon(Icons.qr_code_scanner_outlined),
                label: const Text('Ler QR Code'),
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
                onPressed: isLoading ? null : _openCharacterShareOptions,
                icon: const Icon(Icons.share_outlined),
                label: const Text('Compartilhar'),
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

class _CharacterQrCodeDialog extends StatelessWidget {
  const _CharacterQrCodeDialog({
    required this.characterName,
    required this.qrPayloads,
  });

  final String characterName;
  final List<String> qrPayloads;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: _CharacterQrCodeContent(
        characterName: characterName,
        qrPayloads: qrPayloads,
      ),
    );
  }
}

class _CharacterQrCodeContent extends StatefulWidget {
  const _CharacterQrCodeContent({
    required this.characterName,
    required this.qrPayloads,
  });

  final String characterName;
  final List<String> qrPayloads;

  @override
  State<_CharacterQrCodeContent> createState() =>
      _CharacterQrCodeContentState();
}

class _CharacterQrCodeContentState extends State<_CharacterQrCodeContent> {
  int currentPayloadIndex = 0;

  bool get hasMultipleParts => widget.qrPayloads.length > 1;

  void _showPreviousPart() {
    if (currentPayloadIndex == 0) {
      return;
    }

    setState(() {
      currentPayloadIndex -= 1;
    });
  }

  void _showNextPart() {
    if (currentPayloadIndex == widget.qrPayloads.length - 1) {
      return;
    }

    setState(() {
      currentPayloadIndex += 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final int currentPart = currentPayloadIndex + 1;
    final int partCount = widget.qrPayloads.length;

    return SizedBox(
      width: 320,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'QR Code da ficha',
                style: theme.textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.characterName,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            if (hasMultipleParts) ...<Widget>[
              const SizedBox(height: 6),
              Text(
                'Parte $currentPart de $partCount',
                style: theme.textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 12),
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SizedBox.square(
                dimension: 260,
                child: QrImageView(
                  data: widget.qrPayloads[currentPayloadIndex],
                  version: QrVersions.auto,
                  errorCorrectionLevel: QrErrorCorrectLevel.L,
                  size: 260,
                  padding: const EdgeInsets.all(12),
                  backgroundColor: Colors.white,
                  semanticsLabel:
                      'QR Code da ficha ${widget.characterName}, parte $currentPart de $partCount',
                  errorStateBuilder:
                      (BuildContext errorContext, Object? qrException) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'Esta parte ficou grande demais para QR Code.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      },
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (hasMultipleParts)
              Row(
                children: <Widget>[
                  IconButton(
                    onPressed: currentPayloadIndex == 0
                        ? null
                        : _showPreviousPart,
                    icon: const Icon(Icons.chevron_left),
                    tooltip: 'Parte anterior',
                  ),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: currentPart / partCount,
                    ),
                  ),
                  IconButton(
                    onPressed: currentPayloadIndex == partCount - 1
                        ? null
                        : _showNextPart,
                    icon: const Icon(Icons.chevron_right),
                    tooltip: 'Próxima parte',
                  ),
                ],
              ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Fechar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetQrScannerPage extends StatefulWidget {
  const _SheetQrScannerPage({required this.qrService});

  final SheetQrService qrService;

  @override
  State<_SheetQrScannerPage> createState() => _SheetQrScannerPageState();
}

class _SheetQrScannerPageState extends State<_SheetQrScannerPage> {
  final MobileScannerController scannerController = MobileScannerController(
    formats: <BarcodeFormat>[BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  final Map<int, String> scannedPayloadsByIndex = <int, String>{};

  bool scanHandled = false;
  String? scannedPayloadId;
  int? expectedPartCount;
  String scanMessage = 'Aponte a câmera para o QR Code da ficha.';

  @override
  void dispose() {
    scannerController.dispose();
    super.dispose();
  }

  void _handleDetect(BarcodeCapture barcodeCapture) {
    if (scanHandled) {
      return;
    }

    for (final Barcode barcode in barcodeCapture.barcodes) {
      final String? qrPayload = barcode.rawValue;

      if (qrPayload == null || qrPayload.trim().isEmpty) {
        continue;
      }

      _handlePayload(qrPayload);
      return;
    }
  }

  void _handlePayload(String qrPayload) {
    final SheetQrPart? qrPart;

    try {
      qrPart = widget.qrService.parsePart(qrPayload);
    } on FormatException {
      setState(() {
        scanMessage = 'QR Code inválido para ficha.';
      });
      return;
    }

    if (qrPart == null) {
      scanHandled = true;
      scannerController.stop();
      Navigator.of(context).pop(qrPayload);
      return;
    }

    final SheetQrPart qrPartValue = qrPart;

    if (scannedPayloadId != null && scannedPayloadId != qrPartValue.payloadId) {
      scannedPayloadsByIndex.clear();
    }

    scannedPayloadId = qrPartValue.payloadId;
    expectedPartCount = qrPartValue.partCount;
    scannedPayloadsByIndex[qrPartValue.partIndex] = qrPayload;

    if (scannedPayloadsByIndex.length == qrPartValue.partCount) {
      scanHandled = true;
      scannerController.stop();
      final String joinedPayload = widget.qrService.joinPayloadParts(
        scannedPayloadsByIndex.values,
      );
      Navigator.of(context).pop(joinedPayload);
      return;
    }

    setState(() {
      scanMessage =
          'Parte ${qrPartValue.partIndex} de ${qrPartValue.partCount} lida. Faltam ${qrPartValue.partCount - scannedPayloadsByIndex.length}.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ler QR Code')),
      body: Stack(
        children: <Widget>[
          MobileScanner(controller: scannerController, onDetect: _handleDetect),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(scanMessage, textAlign: TextAlign.center),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
