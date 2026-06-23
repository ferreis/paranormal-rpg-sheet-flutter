import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/models/character_sheet.dart';
import '../../data/repositories/character_repository.dart';
import 'character_detail_page.dart';
import 'character_form_page.dart';
import 'character_import_export_page.dart';

class CharacterListPage extends StatefulWidget {
  const CharacterListPage({required this.repository, super.key});

  final CharacterRepository repository;

  @override
  State<CharacterListPage> createState() => _CharacterListPageState();
}

class _CharacterListPageState extends State<CharacterListPage> {
  final TextEditingController searchController = TextEditingController();
  List<CharacterSheet> characterSheets = <CharacterSheet>[];
  bool isLoading = true;
  String? errorMessage;
  Timer? searchTimer;

  @override
  void initState() {
    super.initState();
    _loadCharacters();
  }

  @override
  void dispose() {
    searchTimer?.cancel();
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCharacters() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final List<CharacterSheet> loadedCharacters = await widget.repository
          .listCharacters(searchTerm: searchController.text);

      if (!mounted) {
        return;
      }

      setState(() {
        characterSheets = loadedCharacters;
      });
    } catch (exception) {
      if (!mounted) {
        return;
      }

      setState(() {
        errorMessage = 'Nao foi possivel carregar as fichas.';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _scheduleSearch() {
    searchTimer?.cancel();
    searchTimer = Timer(const Duration(milliseconds: 300), _loadCharacters);
  }

  Future<void> _openNewCharacter() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) =>
            CharacterFormPage(repository: widget.repository),
      ),
    );
    _loadCharacters();
  }

  Future<void> _openCharacter(CharacterSheet characterSheet) async {
    final int? characterId = characterSheet.id;

    if (characterId == null) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => CharacterDetailPage(
          repository: widget.repository,
          characterId: characterId,
        ),
      ),
    );
    _loadCharacters();
  }

  Future<void> _openImportPage() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) =>
            CharacterImportExportPage(repository: widget.repository),
      ),
    );
    _loadCharacters();
  }

  Future<void> _deleteCharacter(CharacterSheet characterSheet) async {
    final int? characterId = characterSheet.id;

    if (characterId == null) {
      return;
    }

    await widget.repository.deleteCharacter(characterId);
    _loadCharacters();
  }

  Future<void> _duplicateCharacter(CharacterSheet characterSheet) async {
    final int? characterId = characterSheet.id;

    if (characterId == null) {
      return;
    }

    await widget.repository.duplicateCharacter(characterId);
    _loadCharacters();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fichas Ordem'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Importar JSON',
            onPressed: _openImportPage,
            icon: const Icon(Icons.upload_file_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openNewCharacter,
        icon: const Icon(Icons.add),
        label: const Text('Nova ficha'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadCharacters,
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: <Widget>[
              TextField(
                controller: searchController,
                decoration: const InputDecoration(
                  labelText: 'Buscar personagem',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (String text) => _scheduleSearch(),
              ),
              const SizedBox(height: 12),
              if (isLoading) const LinearProgressIndicator(),
              if (errorMessage != null) ...<Widget>[
                Text(errorMessage!),
                const SizedBox(height: 12),
              ],
              if (!isLoading && characterSheets.isEmpty)
                const _EmptyCharacterList(),
              ...characterSheets.map(
                (CharacterSheet characterSheet) => _CharacterListTile(
                  characterSheet: characterSheet,
                  onOpen: () => _openCharacter(characterSheet),
                  onDuplicate: () => _duplicateCharacter(characterSheet),
                  onDelete: () => _deleteCharacter(characterSheet),
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyCharacterList extends StatelessWidget {
  const _EmptyCharacterList();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(18),
        child: Text('Nenhuma ficha salva. Toque em Nova ficha para comecar.'),
      ),
    );
  }
}

class _CharacterListTile extends StatelessWidget {
  const _CharacterListTile({
    required this.characterSheet,
    required this.onOpen,
    required this.onDuplicate,
    required this.onDelete,
  });

  final CharacterSheet characterSheet;
  final VoidCallback onOpen;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onOpen,
        title: Text(characterSheet.characterName),
        subtitle: Text(
          [
            characterSheet.characterClass,
            characterSheet.characterPath,
            'NEX ${characterSheet.exposureLevel}',
          ].where((String text) => text.trim().isNotEmpty).join(' - '),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (String action) {
            if (action == 'duplicate') {
              onDuplicate();
            }
            if (action == 'delete') {
              onDelete();
            }
          },
          itemBuilder: (BuildContext context) => const <PopupMenuEntry<String>>[
            PopupMenuItem<String>(value: 'duplicate', child: Text('Duplicar')),
            PopupMenuItem<String>(value: 'delete', child: Text('Excluir')),
          ],
        ),
      ),
    );
  }
}
