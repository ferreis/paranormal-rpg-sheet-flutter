import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/services/character_calculation_service.dart';
import '../models/character_sheet.dart';

class CharacterRepository {
  CharacterRepository({
    AppDatabase? appDatabase,
    CharacterCalculationService? calculationService,
  }) : _appDatabase = appDatabase ?? AppDatabase.instance,
       _calculationService =
           calculationService ?? CharacterCalculationService();

  final AppDatabase _appDatabase;
  final CharacterCalculationService _calculationService;

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

  Future<CharacterSheet> createCharacter(CharacterSheet characterSheet) async {
    return saveCharacter(characterSheet.copyWith(clearId: true));
  }

  Future<CharacterSheet> saveCharacter(CharacterSheet characterSheet) async {
    final Database database = await _appDatabase.database;
    final DateTime currentDate = DateTime.now();
    final CharacterSheet calculatedSheet = _calculationService
        .applyAutomaticValues(characterSheet.copyWith(updatedAt: currentDate));

    return database.transaction((Transaction transaction) async {
      final int characterId;
      final CharacterSheet sheetForPersistence;

      if (calculatedSheet.id == null) {
        sheetForPersistence = calculatedSheet.copyWith(
          createdAt: currentDate,
          updatedAt: currentDate,
        );
        characterId = await transaction.insert(
          'characters',
          sheetForPersistence.toDatabaseMap()..remove('id'),
        );
      } else {
        sheetForPersistence = calculatedSheet;
        characterId = calculatedSheet.id!;
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

  Future<CharacterSheet> duplicateCharacter(int characterId) async {
    final CharacterSheet? existingCharacter = await getCharacter(characterId);

    if (existingCharacter == null) {
      throw StateError('Ficha nao encontrada para duplicar.');
    }

    return createCharacter(
      existingCharacter.copyWith(
        clearId: true,
        characterName: '${existingCharacter.characterName} - copia',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<String> exportCharacterAsJson(int characterId) async {
    final CharacterSheet? characterSheet = await getCharacter(characterId);

    if (characterSheet == null) {
      throw StateError('Ficha nao encontrada para exportar.');
    }

    return const JsonEncoder.withIndent('  ').convert(characterSheet.toJson());
  }

  Future<CharacterSheet> importCharacterFromJson(String jsonContent) async {
    final Object? decodedJson = jsonDecode(jsonContent);

    if (decodedJson is! Map) {
      throw const FormatException('JSON invalido para ficha.');
    }

    final Map<String, Object?> jsonMap = decodedJson.map(
      (Object? rawKey, Object? rawJsonValue) =>
          MapEntry(rawKey.toString(), rawJsonValue),
    );

    return createCharacter(CharacterSheet.fromJson(jsonMap));
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
