import 'package:ordem_fichas/core/database/app_database.dart';
import 'package:ordem_fichas/features/characters/domain/entities/character_sheet.dart';
import 'package:sqflite/sqflite.dart';

class CharacterLocalDatasource {
  CharacterLocalDatasource({AppDatabase? appDatabase})
    : _appDatabase = appDatabase ?? AppDatabase.instance;

  final AppDatabase _appDatabase;

  Future<List<CharacterSheet>> listCharacters({String searchTerm = ''}) async {
    final Database database = await _appDatabase.database;
    final String normalizedSearch = searchTerm.trim();
    final List<Map<String, Object?>> characterRows = await database.query(
      'characters',
      where: normalizedSearch.isEmpty ? null : 'character_name LIKE ?',
      whereArgs: normalizedSearch.isEmpty
          ? null
          : <Object?>['%$normalizedSearch%'],
      orderBy: 'updated_at DESC',
    );

    final List<CharacterSheet> characterSheets = <CharacterSheet>[];

    for (final Map<String, Object?> characterRow in characterRows) {
      final int characterId = characterRow['id'] as int;
      final CharacterSheet? characterSheet = await getCharacter(characterId);

      if (characterSheet != null) {
        characterSheets.add(characterSheet);
      }
    }

    return characterSheets;
  }

  Future<CharacterSheet?> getCharacter(int characterId) async {
    final Database database = await _appDatabase.database;
    final List<Map<String, Object?>> characterRows = await database.query(
      'characters',
      where: 'id = ?',
      whereArgs: <Object?>[characterId],
      limit: 1,
    );

    if (characterRows.isEmpty) {
      return null;
    }

    final Map<String, Object?> characterRow = characterRows.first;

    final List<Map<String, Object?>> attributeRows = await database.query(
      'character_attributes',
      where: 'character_id = ?',
      whereArgs: <Object?>[characterId],
      limit: 1,
    );

    return CharacterSheet.fromDatabase(
      characterRow: characterRow,
      attributes: attributeRows.isEmpty
          ? CharacterAttributes.empty()
          : CharacterAttributes.fromDatabase(attributeRows.first),
      skills: await _loadChildren(
        tableName: 'character_skills',
        characterId: characterId,
        parser: CharacterSkill.fromDatabase,
      ),
      weapons: await _loadChildren(
        tableName: 'character_weapons',
        characterId: characterId,
        parser: CharacterWeapon.fromDatabase,
      ),
      items: await _loadChildren(
        tableName: 'character_items',
        characterId: characterId,
        parser: CharacterItem.fromDatabase,
      ),
      rituals: await _loadChildren(
        tableName: 'character_rituals',
        characterId: characterId,
        parser: CharacterRitual.fromDatabase,
      ),
      powers: await _loadChildren(
        tableName: 'character_powers',
        characterId: characterId,
        parser: CharacterPower.fromDatabase,
      ),
      notes: await _loadChildren(
        tableName: 'character_notes',
        characterId: characterId,
        parser: CharacterNote.fromDatabase,
      ),
    );
  }

  Future<CharacterSheet> saveCharacter(CharacterSheet characterSheet) async {
    final Database database = await _appDatabase.database;

    return database.transaction((Transaction transaction) async {
      final int characterId;
      final CharacterSheet sheetForPersistence;

      if (characterSheet.id == null) {
        sheetForPersistence = characterSheet;
        characterId = await transaction.insert(
          'characters',
          sheetForPersistence.toDatabaseMap()..remove('id'),
        );
      } else {
        sheetForPersistence = characterSheet;
        characterId = characterSheet.id!;
        await transaction.update(
          'characters',
          sheetForPersistence.toDatabaseMap()..remove('id'),
          where: 'id = ?',
          whereArgs: <Object?>[characterId],
        );
      }

      await _replaceChildren(
        transaction: transaction,
        tableName: 'character_attributes',
        characterId: characterId,
        rows: <Map<String, Object?>>[
          sheetForPersistence.attributes.toDatabaseMap(characterId)
            ..remove('id'),
        ],
      );
      await _replaceChildren(
        transaction: transaction,
        tableName: 'character_skills',
        characterId: characterId,
        rows: sheetForPersistence.skills
            .map((CharacterSkill skill) => skill.toDatabaseMap(characterId))
            .map(_removeDatabaseId)
            .toList(),
      );
      await _replaceChildren(
        transaction: transaction,
        tableName: 'character_weapons',
        characterId: characterId,
        rows: sheetForPersistence.weapons
            .map((CharacterWeapon weapon) => weapon.toDatabaseMap(characterId))
            .map(_removeDatabaseId)
            .toList(),
      );
      await _replaceChildren(
        transaction: transaction,
        tableName: 'character_items',
        characterId: characterId,
        rows: sheetForPersistence.items
            .map(
              (CharacterItem characterItem) =>
                  characterItem.toDatabaseMap(characterId),
            )
            .map(_removeDatabaseId)
            .toList(),
      );
      await _replaceChildren(
        transaction: transaction,
        tableName: 'character_rituals',
        characterId: characterId,
        rows: sheetForPersistence.rituals
            .map((CharacterRitual ritual) => ritual.toDatabaseMap(characterId))
            .map(_removeDatabaseId)
            .toList(),
      );
      await _replaceChildren(
        transaction: transaction,
        tableName: 'character_powers',
        characterId: characterId,
        rows: sheetForPersistence.powers
            .map((CharacterPower power) => power.toDatabaseMap(characterId))
            .map(_removeDatabaseId)
            .toList(),
      );
      await _replaceChildren(
        transaction: transaction,
        tableName: 'character_notes',
        characterId: characterId,
        rows: sheetForPersistence.notes
            .map((CharacterNote note) => note.toDatabaseMap(characterId))
            .map(_removeDatabaseId)
            .toList(),
      );

      return sheetForPersistence.copyWith(id: characterId);
    });
  }

  Future<void> deleteCharacter(int characterId) async {
    final Database database = await _appDatabase.database;
    await database.delete(
      'characters',
      where: 'id = ?',
      whereArgs: <Object?>[characterId],
    );
  }

  Future<List<ChildModel>> _loadChildren<ChildModel>({
    required String tableName,
    required int characterId,
    required ChildModel Function(Map<String, Object?> databaseRow) parser,
  }) async {
    final Database database = await _appDatabase.database;
    final List<Map<String, Object?>> childRows = await database.query(
      tableName,
      where: 'character_id = ?',
      whereArgs: <Object?>[characterId],
      orderBy: 'id ASC',
    );

    return childRows.map(parser).toList();
  }

  Future<void> _replaceChildren({
    required Transaction transaction,
    required String tableName,
    required int characterId,
    required List<Map<String, Object?>> rows,
  }) async {
    await transaction.delete(
      tableName,
      where: 'character_id = ?',
      whereArgs: <Object?>[characterId],
    );

    for (final Map<String, Object?> childRow in rows) {
      await transaction.insert(tableName, childRow);
    }
  }

  Map<String, Object?> _removeDatabaseId(Map<String, Object?> databaseMap) {
    return Map<String, Object?>.from(databaseMap)..remove('id');
  }
}
