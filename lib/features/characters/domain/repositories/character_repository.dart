import 'package:ordem_fichas/features/characters/domain/entities/character_sheet.dart';

abstract class CharacterRepository {
  Future<List<CharacterSheet>> listCharacters({String searchTerm = ''});

  Future<CharacterSheet?> getCharacter(int characterId);

  Future<CharacterSheet> createCharacter(CharacterSheet characterSheet);

  Future<CharacterSheet> saveCharacter(CharacterSheet characterSheet);

  Future<void> deleteCharacter(int characterId);

  Future<CharacterSheet> duplicateCharacter(int characterId);

  Future<String> exportCharacterAsJson(int characterId);

  Future<CharacterSheet> importCharacterFromJson(String jsonContent);

  Future<CharacterSheet> importCharacterFromCrisUrl(String crisUrl);
}
