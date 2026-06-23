import 'package:flutter/material.dart';

import '../../data/repositories/character_repository.dart';

class CharacterImportExportPage extends StatefulWidget {
  const CharacterImportExportPage({
    required this.repository,
    this.characterId,
    super.key,
  });

  final CharacterRepository repository;
  final int? characterId;

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
      message = 'Nao foi possivel exportar a ficha.';
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
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
            'Nao foi possivel importar do C.R.I.S. Verifique se o link e publico.';
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
        title: Text(isExportMode ? 'Exportar JSON' : 'Importar JSON'),
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
