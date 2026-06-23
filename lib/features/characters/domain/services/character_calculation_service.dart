import '../../data/models/character_sheet.dart';

class CharacterCalculationService {
  CharacterSheet applyAutomaticValues(CharacterSheet characterSheet) {
    final int calculatedLifeMaximum = calculateLifeMaximum(characterSheet);
    final int calculatedSanityMaximum = calculateSanityMaximum(characterSheet);
    final int calculatedEffortMaximum = calculateEffortMaximum(characterSheet);
    final int calculatedDefense = calculateDefense(characterSheet);

    final int effectiveLifeMaximum = characterSheet.useManualLifeMaximum
        ? _minimumOne(characterSheet.lifeMaximum)
        : calculatedLifeMaximum;
    final int effectiveSanityMaximum = characterSheet.useManualSanityMaximum
        ? _minimumOne(characterSheet.sanityMaximum)
        : calculatedSanityMaximum;
    final int effectiveEffortMaximum = characterSheet.useManualEffortMaximum
        ? _minimumOne(characterSheet.effortMaximum)
        : calculatedEffortMaximum;
    final int effectiveDefense = characterSheet.useManualDefense
        ? characterSheet.defense
        : calculatedDefense;

    return characterSheet.copyWith(
      lifeMaximum: effectiveLifeMaximum,
      lifeCurrent: _clampMinimumAndMaximum(
        characterSheet.lifeCurrent,
        minimum: 0,
        maximum: effectiveLifeMaximum,
      ),
      sanityMaximum: effectiveSanityMaximum,
      sanityCurrent: _clampMinimumAndMaximum(
        characterSheet.sanityCurrent,
        minimum: 0,
        maximum: effectiveSanityMaximum,
      ),
      effortMaximum: effectiveEffortMaximum,
      effortCurrent: _clampMinimumAndMaximum(
        characterSheet.effortCurrent,
        minimum: 0,
        maximum: effectiveEffortMaximum,
      ),
      defense: effectiveDefense,
    );
  }

  int calculateLifeMaximum(CharacterSheet characterSheet) {
    return _minimumOne(
      characterSheet.baseLife +
          characterSheet.attributes.vigor * characterSheet.lifePerVigor +
          characterSheet.lifeManualBonus,
    );
  }

  int calculateSanityMaximum(CharacterSheet characterSheet) {
    return _minimumOne(
      characterSheet.baseSanity +
          characterSheet.attributes.presence *
              characterSheet.sanityPerPresence +
          characterSheet.sanityManualBonus,
    );
  }

  int calculateEffortMaximum(CharacterSheet characterSheet) {
    return _minimumOne(
      characterSheet.baseEffort +
          characterSheet.attributes.presence *
              characterSheet.effortPerPresence +
          characterSheet.effortManualBonus,
    );
  }

  int calculateDefense(CharacterSheet characterSheet) {
    return characterSheet.baseDefense +
        characterSheet.attributes.agility +
        protectionDefenseBonus(characterSheet) +
        characterSheet.defenseManualBonus;
  }

  int protectionDefenseBonus(CharacterSheet characterSheet) {
    return characterSheet.items
        .where((CharacterItem characterItem) => characterItem.isProtection)
        .fold(
          0,
          (int totalDefenseBonus, CharacterItem characterItem) =>
              totalDefenseBonus + characterItem.defenseBonus,
        );
  }

  int _minimumOne(int numericValue) {
    if (numericValue < 1) {
      return 1;
    }

    return numericValue;
  }

  int _clampMinimumAndMaximum(
    int numericValue, {
    required int minimum,
    required int maximum,
  }) {
    if (numericValue < minimum) {
      return minimum;
    }

    if (numericValue > maximum) {
      return maximum;
    }

    return numericValue;
  }
}
