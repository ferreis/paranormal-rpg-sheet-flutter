import 'package:flutter_test/flutter_test.dart';
import 'package:ordem_fichas/features/characters/data/models/character_sheet.dart';
import 'package:ordem_fichas/features/characters/domain/services/character_calculation_service.dart';

void main() {
  test('atualiza vida, sanidade, esforco e defesa automaticamente', () {
    final CharacterCalculationService calculationService =
        CharacterCalculationService();

    final CharacterSheet characterSheet = CharacterSheet.empty().copyWith(
      attributes: CharacterAttributes.empty().copyWith(
        agility: 3,
        presence: 2,
        vigor: 4,
      ),
      baseLife: 10,
      lifePerVigor: 5,
      lifeManualBonus: 2,
      baseSanity: 8,
      sanityPerPresence: 3,
      sanityManualBonus: 1,
      baseEffort: 1,
      effortPerPresence: 2,
      effortManualBonus: 3,
      baseDefense: 10,
      defenseManualBonus: 2,
      items: <CharacterItem>[
        CharacterItem.empty(category: 'Protecao').copyWith(defenseBonus: 4),
      ],
    );

    final CharacterSheet calculatedSheet = calculationService
        .applyAutomaticValues(characterSheet);

    expect(calculatedSheet.lifeMaximum, 32);
    expect(calculatedSheet.sanityMaximum, 15);
    expect(calculatedSheet.effortMaximum, 8);
    expect(calculatedSheet.defense, 19);
  });

  test('respeita valor manual quando override esta ativo', () {
    final CharacterCalculationService calculationService =
        CharacterCalculationService();

    final CharacterSheet characterSheet = CharacterSheet.empty().copyWith(
      lifeMaximum: 99,
      useManualLifeMaximum: true,
      defense: 33,
      useManualDefense: true,
    );

    final CharacterSheet calculatedSheet = calculationService
        .applyAutomaticValues(characterSheet);

    expect(calculatedSheet.lifeMaximum, 99);
    expect(calculatedSheet.defense, 33);
  });
}
