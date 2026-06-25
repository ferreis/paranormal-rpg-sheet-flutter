import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ordem_fichas/features/characters/domain/entities/character_sheet.dart';
import 'package:ordem_fichas/features/characters/presentation/pages/character_detail_page.dart';

void main() {
  testWidgets('centraliza os numeros dos atributos nos pontos da imagem', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 720,
              height: 720,
              child: AttributeCircle(characterSheet: _visualCharacterSheet()),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final Rect imageRect = tester.getRect(find.byType(Image).first);
    final Map<String, Offset> expectedAnchors = <String, Offset>{
      'attribute-number-agility': const Offset(360 / 720, 132 / 720),
      'attribute-number-strength': const Offset(137 / 720, 292 / 720),
      'attribute-number-intellect': const Offset(586 / 720, 290 / 720),
      'attribute-number-presence': const Offset(211 / 720, 557 / 720),
      'attribute-number-vigor': const Offset(505 / 720, 555 / 720),
    };

    for (final MapEntry<String, Offset> anchorEntry
        in expectedAnchors.entries) {
      final Offset renderedCenter = tester.getCenter(
        find.byKey(ValueKey<String>(anchorEntry.key)),
      );
      final Offset expectedCenter = Offset(
        imageRect.left + imageRect.width * anchorEntry.value.dx,
        imageRect.top + imageRect.height * anchorEntry.value.dy,
      );

      expect((renderedCenter - expectedCenter).distance, lessThanOrEqualTo(1));
    }
  });
}

CharacterSheet _visualCharacterSheet() {
  return CharacterSheet.empty().copyWith(
    attributes: CharacterAttributes.empty().copyWith(
      agility: 5,
      strength: 4,
      intellect: 6,
      presence: 7,
      vigor: 8,
    ),
  );
}
