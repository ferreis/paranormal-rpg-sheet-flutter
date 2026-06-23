import 'package:flutter/material.dart';

import '../../data/models/character_sheet.dart';
import '../../data/repositories/character_repository.dart';
import 'character_edit_page.dart';
import 'character_import_export_page.dart';

class CharacterDetailPage extends StatefulWidget {
  const CharacterDetailPage({
    required this.repository,
    required this.characterId,
    super.key,
  });

  final CharacterRepository repository;
  final int characterId;

  @override
  State<CharacterDetailPage> createState() => _CharacterDetailPageState();
}

class _CharacterDetailPageState extends State<CharacterDetailPage> {
  late Future<CharacterSheet?> characterFuture;

  @override
  void initState() {
    super.initState();
    characterFuture = widget.repository.getCharacter(widget.characterId);
  }

  void _reload() {
    setState(() {
      characterFuture = widget.repository.getCharacter(widget.characterId);
    });
  }

  Future<void> _deleteCharacter(CharacterSheet characterSheet) async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Excluir ficha'),
        content: Text('Excluir "${characterSheet.characterName}"?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) {
      return;
    }

    await widget.repository.deleteCharacter(widget.characterId);

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _duplicateCharacter() async {
    final CharacterSheet duplicatedCharacter = await widget.repository
        .duplicateCharacter(widget.characterId);

    if (!mounted || duplicatedCharacter.id == null) {
      return;
    }

    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => CharacterDetailPage(
          repository: widget.repository,
          characterId: duplicatedCharacter.id!,
        ),
      ),
    );
  }

  Future<void> _openEditor() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => CharacterEditPage(
          repository: widget.repository,
          characterId: widget.characterId,
        ),
      ),
    );
    _reload();
  }

  void _openExport() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => CharacterImportExportPage(
          repository: widget.repository,
          characterId: widget.characterId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CharacterSheet?>(
      future: characterFuture,
      builder: (BuildContext context, AsyncSnapshot<CharacterSheet?> snapshot) {
        final CharacterSheet? characterSheet = snapshot.data;

        return Scaffold(
          appBar: AppBar(
            title: Text(characterSheet?.characterName ?? 'Ficha'),
            actions: <Widget>[
              IconButton(
                tooltip: 'Editar',
                onPressed: characterSheet == null ? null : _openEditor,
                icon: const Icon(Icons.edit_outlined),
              ),
              PopupMenuButton<String>(
                onSelected: (String action) {
                  if (action == 'duplicate') {
                    _duplicateCharacter();
                  }
                  if (action == 'export') {
                    _openExport();
                  }
                  if (action == 'delete' && characterSheet != null) {
                    _deleteCharacter(characterSheet);
                  }
                },
                itemBuilder: (BuildContext context) =>
                    const <PopupMenuEntry<String>>[
                      PopupMenuItem<String>(
                        value: 'duplicate',
                        child: Text('Duplicar'),
                      ),
                      PopupMenuItem<String>(
                        value: 'export',
                        child: Text('Exportar JSON'),
                      ),
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: Text('Excluir'),
                      ),
                    ],
              ),
            ],
          ),
          body: _buildBody(snapshot),
        );
      },
    );
  }

  Widget _buildBody(AsyncSnapshot<CharacterSheet?> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }

    final CharacterSheet? characterSheet = snapshot.data;

    if (characterSheet == null) {
      return const Center(child: Text('Ficha nao encontrada.'));
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: <Widget>[
        _SummaryCard(characterSheet: characterSheet),
        _SectionTile(
          title: 'Identificacao',
          lines: <String>[
            'Jogador: ${characterSheet.playerName}',
            'Origem: ${characterSheet.origin}',
            'Classe: ${characterSheet.characterClass}',
            'Trilha: ${characterSheet.characterPath}',
            'Patente: ${characterSheet.rank}',
            'NEX: ${characterSheet.exposureLevel}',
          ],
        ),
        _SectionTile(
          title: 'Atributos',
          lines: <String>[
            'Forca: ${characterSheet.attributes.strength}',
            'Agilidade: ${characterSheet.attributes.agility}',
            'Intelecto: ${characterSheet.attributes.intellect}',
            'Presenca: ${characterSheet.attributes.presence}',
            'Vigor: ${characterSheet.attributes.vigor}',
          ],
        ),
        _SectionTile(
          title: 'Colecoes',
          lines: <String>[
            'Pericias: ${characterSheet.skills.length}',
            'Armas: ${characterSheet.weapons.length}',
            'Itens: ${characterSheet.items.length}',
            'Rituais: ${characterSheet.rituals.length}',
            'Poderes e habilidades: ${characterSheet.powers.length}',
            'Notas: ${characterSheet.notes.length}',
          ],
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.characterSheet});

  final CharacterSheet characterSheet;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              characterSheet.characterName,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                _MetricChip(
                  label: 'PV',
                  text:
                      '${characterSheet.lifeCurrent}/${characterSheet.lifeMaximum}',
                ),
                _MetricChip(
                  label: 'SAN',
                  text:
                      '${characterSheet.sanityCurrent}/${characterSheet.sanityMaximum}',
                ),
                _MetricChip(
                  label: 'PE',
                  text:
                      '${characterSheet.effortCurrent}/${characterSheet.effortMaximum}',
                ),
                _MetricChip(
                  label: 'DEF',
                  text: characterSheet.defense.toString(),
                ),
                _MetricChip(
                  label: 'DESL',
                  text: characterSheet.movement.toString(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.text});

  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text('$label $text'));
  }
}

class _SectionTile extends StatelessWidget {
  const _SectionTile({required this.title, required this.lines});

  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        title: Text(title),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        children: lines
            .map(
              (String line) => Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(line),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
