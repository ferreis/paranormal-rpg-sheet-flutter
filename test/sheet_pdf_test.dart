import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ordem_fichas/features/characters/domain/entities/character_sheet.dart';
import 'package:ordem_fichas/features/characters/data/services/sheet_pdf_service.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('gera PDF editável preenchendo campos principais', () async {
    final CharacterSheet characterSheet = CharacterSheet.empty().copyWith(
      characterName: 'Arthur Cervero',
      playerName: 'João',
      attributes: const CharacterAttributes(
        strength: 2,
        agility: 3,
        intellect: 4,
        presence: 1,
        vigor: 5,
      ),
    );
    final SheetPdfService pdfExportService = SheetPdfService();

    final Uint8List pdfBytes = await pdfExportService.buildEditablePdf(
      characterSheet,
    );
    final PdfDocument pdfDocument = PdfDocument(inputBytes: pdfBytes);

    try {
      expect(pdfDocument.form.fields.count, greaterThan(0));
      expect(_textFieldValue(pdfDocument, 'untitled1'), 'Arthur Cervero');
      expect(_textFieldValue(pdfDocument, 'untitled2'), 'João');
      expect(_textFieldValue(pdfDocument, 'untitled12'), '2');
      expect(_textFieldValue(pdfDocument, 'untitled13'), '3');
      expect(_textFieldValue(pdfDocument, 'untitled14'), '4');
      expect(_textFieldValue(pdfDocument, 'untitled11'), '1');
      expect(_textFieldValue(pdfDocument, 'untitled15'), '5');
    } finally {
      pdfDocument.dispose();
    }
  });

  test('gera páginas extras para anotações fora dos campos editáveis', () async {
    final CharacterSheet characterSheet = CharacterSheet.empty().copyWith(
      characterName: 'Livia Torres',
      notes: const <CharacterNote>[
        CharacterNote(
          category: CharacterNoteCategory.general,
          title: 'Pesquisa intensa',
          content:
              'Micro-TOC: precisa manter cadernos, canetas e objetos de estudo alinhados.',
        ),
        CharacterNote(
          category: CharacterNoteCategory.history,
          title: 'Carreira',
          content:
              'Formou-se em psicologia e encontrou sucesso escrevendo contos de terror.',
        ),
      ],
    );
    final SheetPdfService pdfExportService = SheetPdfService();

    final Uint8List emptyPdfBytes = await pdfExportService.buildEditablePdf(
      CharacterSheet.empty(),
    );
    final Uint8List pdfBytes = await pdfExportService.buildEditablePdf(
      characterSheet,
    );
    final PdfDocument emptyPdfDocument = PdfDocument(inputBytes: emptyPdfBytes);
    final PdfDocument pdfDocument = PdfDocument(inputBytes: pdfBytes);

    try {
      final String extractedText = PdfTextExtractor(pdfDocument).extractText();

      expect(
        pdfDocument.pages.count,
        greaterThan(emptyPdfDocument.pages.count),
      );
      expect(_textFieldValue(pdfDocument, 'untitled1'), 'Livia Torres');
      expect(_hasTextField(pdfDocument, 'untitled321'), isFalse);
      expect(extractedText, contains('ANOTAÇÕES DO PERSONAGEM'));
      expect(extractedText, contains('Página de anotações 1'));
      expect(extractedText, contains('Pesquisa intensa'));
      expect(extractedText, contains('Micro-TOC'));
      expect(extractedText, contains('Carreira'));
    } finally {
      emptyPdfDocument.dispose();
      pdfDocument.dispose();
    }
  });

  test('preenche inventário usando os campos corretos do template', () async {
    final CharacterSheet characterSheet = CharacterSheet.empty().copyWith(
      items: const <CharacterItem>[
        CharacterItem(
          name: 'Utensílio',
          category: 'Acessório',
          quantity: 1,
          weight: 1,
          defenseBonus: 0,
          notes: '',
        ),
        CharacterItem(
          name: 'Bastão',
          category: 'Arma',
          quantity: 1,
          weight: 1,
          defenseBonus: 0,
          notes: '',
        ),
        CharacterItem(
          name: 'Colete leve',
          category: 'Proteção',
          quantity: 1,
          weight: 2,
          defenseBonus: 2,
          notes: '',
        ),
      ],
    );
    final SheetPdfService pdfExportService = SheetPdfService();

    final Uint8List pdfBytes = await pdfExportService.buildEditablePdf(
      characterSheet,
    );
    final PdfDocument pdfDocument = PdfDocument(inputBytes: pdfBytes);

    try {
      expect(_textFieldValue(pdfDocument, 'untitled256'), 'Utensílio');
      expect(_textFieldValue(pdfDocument, 'untitled257'), 'Aces.');
      expect(_textFieldValue(pdfDocument, 'untitled258'), '1');
      expect(_textFieldValue(pdfDocument, 'untitled255'), 'Bastão');
      expect(_textFieldValue(pdfDocument, 'untitled262'), 'Arma');
      expect(_textFieldValue(pdfDocument, 'untitled263'), '1');
      expect(_textFieldValue(pdfDocument, 'untitled264'), 'Colete leve');
      expect(_textFieldValue(pdfDocument, 'untitled273'), 'Prot.');
      expect(_textFieldValue(pdfDocument, 'untitled282'), '2');
    } finally {
      pdfDocument.dispose();
    }
  });
}

String _textFieldValue(PdfDocument pdfDocument, String fieldName) {
  final PdfFormFieldCollection formFields = pdfDocument.form.fields;

  for (int fieldIndex = 0; fieldIndex < formFields.count; fieldIndex += 1) {
    final PdfField pdfField = formFields[fieldIndex];

    if (pdfField.name == fieldName && pdfField is PdfTextBoxField) {
      return pdfField.text;
    }
  }

  throw StateError('Campo $fieldName não encontrado no PDF.');
}

bool _hasTextField(PdfDocument pdfDocument, String fieldName) {
  final PdfFormFieldCollection formFields = pdfDocument.form.fields;

  for (int fieldIndex = 0; fieldIndex < formFields.count; fieldIndex += 1) {
    final PdfField pdfField = formFields[fieldIndex];

    if (pdfField.name == fieldName && pdfField is PdfTextBoxField) {
      return true;
    }
  }

  return false;
}
