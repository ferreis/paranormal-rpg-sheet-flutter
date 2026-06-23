import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ordem_fichas/core/database/app_database.dart';
import 'package:ordem_fichas/features/characters/data/models/character_sheet.dart';
import 'package:ordem_fichas/features/characters/data/repositories/character_repository.dart';
import 'package:path/path.dart' as path_package;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
  });

  test('salva, reabre, duplica, exporta, importa e exclui ficha', () async {
    final Directory temporaryDirectory = await Directory.systemTemp.createTemp(
      'ordem_repository_test_',
    );
    final String databasePath = path_package.join(
      temporaryDirectory.path,
      'repository_test.db',
    );

    try {
      final AppDatabase firstDatabase = AppDatabase.forTest(
        databasePath: databasePath,
        databaseFactory: databaseFactoryFfi,
      );
      final CharacterRepository firstRepository = CharacterRepository(
        appDatabase: firstDatabase,
      );
      final CharacterSheet savedCharacter = await firstRepository.saveCharacter(
        _filledCharacterSheet(),
      );
      final int savedCharacterId = savedCharacter.id!;

      expect(savedCharacter.characterName, 'Agente Teste');
      expect(savedCharacter.weapons, hasLength(1));
      expect(savedCharacter.items, hasLength(2));
      expect(savedCharacter.rituals, hasLength(1));
      expect(savedCharacter.powers, hasLength(2));
      expect(savedCharacter.notes, hasLength(2));
      expect(savedCharacter.defense, 18);

      await firstDatabase.close();

      final AppDatabase reopenedDatabase = AppDatabase.forTest(
        databasePath: databasePath,
        databaseFactory: databaseFactoryFfi,
      );
      final CharacterRepository reopenedRepository = CharacterRepository(
        appDatabase: reopenedDatabase,
      );
      final CharacterSheet? loadedCharacter = await reopenedRepository
          .getCharacter(savedCharacterId);

      expect(loadedCharacter, isNotNull);
      expect(loadedCharacter!.characterName, 'Agente Teste');
      expect(loadedCharacter.weapons.single.name, 'Revolver');
      expect(loadedCharacter.items.first.name, 'Colete');
      expect(loadedCharacter.rituals.single.name, 'Ritual proprio');
      expect(loadedCharacter.powers.last.category, 'Habilidade');

      final CharacterSheet updatedCharacter = await reopenedRepository
          .saveCharacter(
            loadedCharacter.copyWith(
              characterName: 'Agente Atualizado',
              lifeCurrent: 7,
            ),
          );
      expect(updatedCharacter.characterName, 'Agente Atualizado');
      expect(updatedCharacter.lifeCurrent, 7);

      final List<CharacterSheet> searchResult = await reopenedRepository
          .listCharacters(searchTerm: 'Atualizado');
      expect(searchResult, hasLength(1));

      final CharacterSheet duplicatedCharacter = await reopenedRepository
          .duplicateCharacter(savedCharacterId);
      expect(duplicatedCharacter.id, isNot(savedCharacterId));
      expect(duplicatedCharacter.characterName, contains('copia'));

      final String exportedJson = await reopenedRepository
          .exportCharacterAsJson(savedCharacterId);
      expect(exportedJson, contains('Agente Atualizado'));
      expect(exportedJson, contains('Ritual proprio'));

      final CharacterSheet importedCharacter = await reopenedRepository
          .importCharacterFromJson(exportedJson);
      expect(importedCharacter.id, isNotNull);
      expect(importedCharacter.characterName, 'Agente Atualizado');

      await reopenedRepository.deleteCharacter(savedCharacterId);
      expect(await reopenedRepository.getCharacter(savedCharacterId), isNull);
      await _expectNoDependentRows(reopenedDatabase, savedCharacterId);

      await reopenedDatabase.close();
    } finally {
      await temporaryDirectory.delete(recursive: true);
    }
  });
}

CharacterSheet _filledCharacterSheet() {
  return CharacterSheet.empty().copyWith(
    characterName: 'Agente Teste',
    playerName: 'Jogador Teste',
    origin: 'Origem propria',
    characterClass: 'Classe propria',
    characterPath: 'Trilha propria',
    rank: 'Patente propria',
    exposureLevel: 20,
    attributes: CharacterAttributes.empty().copyWith(
      agility: 2,
      presence: 3,
      vigor: 4,
    ),
    weapons: <CharacterWeapon>[
      CharacterWeapon.empty().copyWith(
        name: 'Revolver',
        attackBonus: 2,
        damage: 'Manual',
      ),
    ],
    items: <CharacterItem>[
      CharacterItem.empty(
        category: 'Protecao',
      ).copyWith(name: 'Colete', defenseBonus: 6),
      CharacterItem.empty().copyWith(name: 'Lanterna'),
    ],
    rituals: <CharacterRitual>[
      CharacterRitual.empty().copyWith(
        name: 'Ritual proprio',
        description: 'Descricao livre do usuario.',
      ),
    ],
    powers: <CharacterPower>[
      CharacterPower.empty().copyWith(
        name: 'Poder proprio',
        description: 'Texto livre.',
      ),
      CharacterPower.empty(
        category: 'Habilidade',
      ).copyWith(name: 'Habilidade propria'),
    ],
    notes: <CharacterNote>[
      CharacterNote.empty(
        category: CharacterNoteCategory.general,
      ).copyWith(title: 'Anotacao', content: 'Conteudo livre.'),
      CharacterNote.empty(
        category: CharacterNoteCategory.history,
      ).copyWith(title: 'Historico', content: 'Historia propria.'),
    ],
  );
}

Future<void> _expectNoDependentRows(
  AppDatabase appDatabase,
  int characterId,
) async {
  final Database database = await appDatabase.database;
  const List<String> dependentTables = <String>[
    'character_attributes',
    'character_skills',
    'character_weapons',
    'character_items',
    'character_rituals',
    'character_powers',
    'character_notes',
  ];

  for (final String tableName in dependentTables) {
    final List<Map<String, Object?>> dependentRows = await database.query(
      tableName,
      where: 'character_id = ?',
      whereArgs: <Object?>[characterId],
    );
    expect(dependentRows, isEmpty, reason: tableName);
  }
}
