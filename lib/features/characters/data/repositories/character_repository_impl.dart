import 'dart:convert';

import 'package:ordem_fichas/core/database/app_database.dart';
import 'package:ordem_fichas/features/characters/data/datasources/character_local_datasource.dart';
import 'package:ordem_fichas/features/characters/data/services/cris_import_service.dart';
import 'package:ordem_fichas/features/characters/domain/entities/character_sheet.dart';
import 'package:ordem_fichas/features/characters/domain/repositories/character_repository.dart';
import 'package:ordem_fichas/features/characters/domain/services/character_calculation_service.dart';

class CharacterRepositoryImpl implements CharacterRepository {
  CharacterRepositoryImpl({
    AppDatabase? appDatabase,
    CharacterLocalDatasource? localDatasource,
    CharacterCalculationService? calculationService,
    CrisImportService? crisImportService,
  }) : _localDatasource =
           localDatasource ??
           CharacterLocalDatasource(
             appDatabase: appDatabase ?? AppDatabase.instance,
           ),
       _calculationService =
           calculationService ?? CharacterCalculationService(),
       _crisImportService = crisImportService ?? CrisImportService();

  final CharacterLocalDatasource _localDatasource;
  final CharacterCalculationService _calculationService;
  final CrisImportService _crisImportService;

  @override
  Future<List<CharacterSheet>> listCharacters({String searchTerm = ''}) async {
    return _localDatasource.listCharacters(searchTerm: searchTerm);
  }

  @override
  Future<CharacterSheet?> getCharacter(int characterId) async {
    return _localDatasource.getCharacter(characterId);
  }

  @override
  Future<CharacterSheet> createCharacter(CharacterSheet characterSheet) async {
    return saveCharacter(characterSheet.copyWith(clearId: true));
  }

  @override
  Future<CharacterSheet> saveCharacter(CharacterSheet characterSheet) async {
    final DateTime currentDate = DateTime.now();
    final CharacterSheet calculatedSheet = _calculationService
        .applyAutomaticValues(characterSheet.copyWith(updatedAt: currentDate));

    final CharacterSheet sheetForPersistence = calculatedSheet.id == null
        ? calculatedSheet.copyWith(
            createdAt: currentDate,
            updatedAt: currentDate,
          )
        : calculatedSheet;

    return _localDatasource.saveCharacter(sheetForPersistence);
  }

  @override
  Future<void> deleteCharacter(int characterId) async {
    await _localDatasource.deleteCharacter(characterId);
  }

  @override
  Future<CharacterSheet> duplicateCharacter(int characterId) async {
    final CharacterSheet? existingCharacter = await getCharacter(characterId);

    if (existingCharacter == null) {
      throw StateError('Ficha não encontrada para duplicar.');
    }

    return createCharacter(
      existingCharacter.copyWith(
        clearId: true,
        characterName: '${existingCharacter.characterName} - cópia',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<String> exportCharacterAsJson(int characterId) async {
    final CharacterSheet? characterSheet = await getCharacter(characterId);

    if (characterSheet == null) {
      throw StateError('Ficha não encontrada para exportar.');
    }

    return const JsonEncoder.withIndent('  ').convert(characterSheet.toJson());
  }

  @override
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

  @override
  Future<CharacterSheet> importCharacterFromCrisUrl(String crisUrl) async {
    final CharacterSheet importedCharacter = await _crisImportService
        .importFromUrl(crisUrl);

    return createCharacter(importedCharacter);
  }
}
