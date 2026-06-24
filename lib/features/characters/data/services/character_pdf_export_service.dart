import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../models/character_sheet.dart';

class CharacterPdfExportService {
  static const String templateAssetPath =
      'assets/forms/FichaDosAgentesEditavel.pdf';

  Future<Uint8List> buildEditablePdf(CharacterSheet characterSheet) async {
    final ByteData templateData = await rootBundle.load(templateAssetPath);
    final Uint8List templateBytes = templateData.buffer.asUint8List();
    final PdfDocument pdfDocument = PdfDocument(inputBytes: templateBytes);

    try {
      final Map<String, PdfTextBoxField> textFields = _textFieldsByName(
        pdfDocument,
      );

      _fillIdentity(textFields, characterSheet);
      _fillAttributes(textFields, characterSheet.attributes);
      _fillResources(textFields, characterSheet);
      _fillSkills(textFields, characterSheet.skills);
      _fillWeapons(textFields, characterSheet.weapons);
      _fillRitualsAndPowers(textFields, characterSheet);
      _fillItems(textFields, characterSheet.items);
      _removeTemplateDescription(pdfDocument, textFields);
      _appendNotesPages(pdfDocument, characterSheet);

      return Uint8List.fromList(pdfDocument.saveSync());
    } finally {
      pdfDocument.dispose();
    }
  }

  Map<String, PdfTextBoxField> _textFieldsByName(PdfDocument pdfDocument) {
    final Map<String, PdfTextBoxField> textFields = <String, PdfTextBoxField>{};
    final PdfFormFieldCollection formFields = pdfDocument.form.fields;

    for (int fieldIndex = 0; fieldIndex < formFields.count; fieldIndex += 1) {
      final PdfField pdfField = formFields[fieldIndex];
      final String? fieldName = pdfField.name;

      if (fieldName != null && pdfField is PdfTextBoxField) {
        textFields[fieldName] = pdfField;
      }
    }

    return textFields;
  }

  void _fillIdentity(
    Map<String, PdfTextBoxField> textFields,
    CharacterSheet characterSheet,
  ) {
    _setText(textFields, 'untitled1', characterSheet.characterName);
    _setText(textFields, 'untitled2', characterSheet.playerName);
    _setText(textFields, 'untitled129', characterSheet.origin);
    _setText(textFields, 'untitled130', characterSheet.characterClass);
    _setText(textFields, 'untitled131', characterSheet.exposureLevel);
    _setText(textFields, 'untitled132', characterSheet.effortMaximum);
    _setText(textFields, 'untitled133', '${characterSheet.movement} m');
  }

  void _fillAttributes(
    Map<String, PdfTextBoxField> textFields,
    CharacterAttributes attributes,
  ) {
    _setText(textFields, 'untitled12', attributes.strength);
    _setText(textFields, 'untitled13', attributes.agility);
    _setText(textFields, 'untitled14', attributes.intellect);
    _setText(textFields, 'untitled11', attributes.presence);
    _setText(textFields, 'untitled15', attributes.vigor);
  }

  void _fillResources(
    Map<String, PdfTextBoxField> textFields,
    CharacterSheet characterSheet,
  ) {
    _setText(textFields, 'untitled134', characterSheet.lifeCurrent);
    _setText(textFields, 'untitled135', characterSheet.lifeMaximum);
    _setText(textFields, 'untitled136', characterSheet.effortCurrent);
    _setText(textFields, 'untitled137', characterSheet.effortMaximum);
    _setText(textFields, 'untitled138', characterSheet.defense);
    _setText(textFields, 'untitled141', characterSheet.sanityCurrent);
    _setText(textFields, 'untitled142', characterSheet.sanityMaximum);
    _setText(textFields, 'untitled247', characterSheet.rank);
  }

  void _fillSkills(
    Map<String, PdfTextBoxField> textFields,
    List<CharacterSkill> skills,
  ) {
    final Map<String, CharacterSkill> skillsByName = <String, CharacterSkill>{
      for (final CharacterSkill skill in skills) _normalize(skill.name): skill,
    };

    for (
      int pdfSkillIndex = 0;
      pdfSkillIndex < _pdfSkillNames.length;
      pdfSkillIndex += 1
    ) {
      final CharacterSkill? skill =
          skillsByName[_normalize(_pdfSkillNames[pdfSkillIndex])];

      if (skill == null) {
        continue;
      }

      _setText(textFields, 'untitled${16 + pdfSkillIndex}', skill.total);
      _setText(textFields, 'untitled${45 + pdfSkillIndex}', skill.bonus);
      _setText(textFields, 'untitled${73 + pdfSkillIndex}', skill.training);
      _setText(textFields, 'untitled${101 + pdfSkillIndex}', skill.notes);
    }
  }

  void _fillWeapons(
    Map<String, PdfTextBoxField> textFields,
    List<CharacterWeapon> weapons,
  ) {
    for (
      int weaponIndex = 0;
      weaponIndex < weapons.length && weaponIndex < 5;
      weaponIndex += 1
    ) {
      final CharacterWeapon weapon = weapons[weaponIndex];

      _setText(textFields, 'untitled${145 + weaponIndex}', weapon.name);
      _setText(textFields, 'untitled${150 + weaponIndex}', weapon.attackBonus);
      _setText(textFields, 'untitled${155 + weaponIndex}', weapon.damage);
      _setText(
        textFields,
        'untitled${160 + weaponIndex}',
        _joinFilled(<String>[weapon.critical, weapon.range, weapon.notes]),
      );
    }
  }

  void _fillRitualsAndPowers(
    Map<String, PdfTextBoxField> textFields,
    CharacterSheet characterSheet,
  ) {
    final List<_PdfPowerLine> powerLines = <_PdfPowerLine>[
      ...characterSheet.powers.map(
        (CharacterPower power) => _PdfPowerLine(
          name: power.name,
          cost: '',
          page: '',
          description: power.description,
        ),
      ),
      ...characterSheet.rituals.map(
        (CharacterRitual ritual) => _PdfPowerLine(
          name: ritual.name,
          cost: ritual.cost,
          page: '',
          description: ritual.description,
        ),
      ),
    ];

    for (
      int powerIndex = 0;
      powerIndex < powerLines.length && powerIndex < 20;
      powerIndex += 1
    ) {
      final _PdfPowerLine powerLine = powerLines[powerIndex];
      final String nameField = powerIndex == 0
          ? 'untitled166'
          : 'untitled${170 + powerIndex - 1}';
      final String costField = powerIndex == 0
          ? 'untitled167'
          : 'untitled${189 + powerIndex - 1}';
      final String pageField = powerIndex == 0
          ? 'untitled168'
          : 'untitled${208 + powerIndex - 1}';
      final String descriptionField = powerIndex == 0
          ? 'untitled169'
          : 'untitled${227 + powerIndex - 1}';

      _setText(textFields, nameField, powerLine.name);
      _setText(textFields, costField, powerLine.cost);
      _setText(textFields, pageField, powerLine.page);
      _setText(textFields, descriptionField, powerLine.description);
    }
  }

  void _fillItems(
    Map<String, PdfTextBoxField> textFields,
    List<CharacterItem> items,
  ) {
    for (
      int itemIndex = 0;
      itemIndex < items.length && itemIndex < _pdfItemFields.length;
      itemIndex += 1
    ) {
      final CharacterItem characterItem = items[itemIndex];
      final _PdfItemFields itemFields = _pdfItemFields[itemIndex];

      _setText(
        textFields,
        itemFields.nameField,
        _itemName(characterItem),
        fontSize: 8,
      );
      _setText(
        textFields,
        itemFields.categoryField,
        _compactItemCategory(characterItem.category),
        fontSize: 6,
        textAlignment: PdfTextAlignment.center,
      );
      _setText(
        textFields,
        itemFields.weightField,
        characterItem.weight,
        fontSize: 8,
        textAlignment: PdfTextAlignment.center,
      );
    }
  }

  void _setText(
    Map<String, PdfTextBoxField> textFields,
    String fieldName,
    Object? fieldValue, {
    double? fontSize,
    PdfTextAlignment? textAlignment,
  }) {
    final PdfTextBoxField? textField = textFields[fieldName];

    if (textField == null) {
      return;
    }

    if (fontSize != null) {
      textField.font = PdfStandardFont(PdfFontFamily.helvetica, fontSize);
    }

    if (textAlignment != null) {
      textField.textAlignment = textAlignment;
    }

    textField.text = _fieldText(fieldValue);
  }

  String _fieldText(Object? fieldValue) {
    return fieldValue?.toString().trim() ?? '';
  }

  String _joinFilled(List<String> values) {
    return values
        .map((String value) => value.trim())
        .where((String value) => value.isNotEmpty)
        .join(' | ');
  }

  String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll('\u00e7', 'c')
        .replaceAll('\u00e3', 'a')
        .replaceAll('\u00e2', 'a')
        .replaceAll('\u00e1', 'a')
        .replaceAll('\u00ea', 'e')
        .replaceAll('\u00e9', 'e')
        .replaceAll('\u00ed', 'i')
        .replaceAll('\u00f5', 'o')
        .replaceAll('\u00f4', 'o')
        .replaceAll('\u00f3', 'o')
        .replaceAll('\u00fa', 'u')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '');
  }

  void _appendNotesPages(
    PdfDocument pdfDocument,
    CharacterSheet characterSheet,
  ) {
    final List<CharacterNote> filledNotes = characterSheet.notes
        .where(_hasPrintableNoteContent)
        .toList();

    if (filledNotes.isEmpty) {
      return;
    }

    final _PdfNotesPageWriter notesPageWriter = _PdfNotesPageWriter(
      pdfDocument: pdfDocument,
      characterName: characterSheet.characterName,
    );

    notesPageWriter.writeNotes(filledNotes);
  }

  bool _hasPrintableNoteContent(CharacterNote note) {
    return _fieldText(note.title).isNotEmpty ||
        _fieldText(note.content).isNotEmpty;
  }

  void _removeTemplateDescription(
    PdfDocument pdfDocument,
    Map<String, PdfTextBoxField> textFields,
  ) {
    _removeTextFields(pdfDocument, textFields, const <String>[
      'untitled321',
      'untitled322',
      'untitled323',
      'untitled324',
      'untitled325',
      'untitled326',
      'untitled327',
      'untitled328',
      'untitled329',
      'untitled330',
      'untitled331',
      'untitled332',
      'untitled333',
      'untitled334',
      'untitled335',
      'untitled336',
      'untitled337',
      'untitled338',
      'untitled339',
      'untitled340',
    ]);

    if (pdfDocument.pages.count < 2) {
      return;
    }

    pdfDocument.pages[1].graphics.drawRectangle(
      brush: PdfSolidBrush(PdfColor(255, 255, 255)),
      bounds: Rect.fromLTWH(18, 622, 540, 124),
    );
  }

  void _removeTextFields(
    PdfDocument pdfDocument,
    Map<String, PdfTextBoxField> textFields,
    List<String> fieldNames,
  ) {
    for (final String fieldName in fieldNames) {
      final PdfTextBoxField? textField = textFields[fieldName];

      if (textField != null) {
        pdfDocument.form.fields.remove(textField);
      }
    }
  }

  String _itemName(CharacterItem characterItem) {
    if (characterItem.quantity <= 1) {
      return characterItem.name;
    }

    return '${characterItem.quantity}x ${characterItem.name}';
  }

  String _compactItemCategory(String category) {
    final String normalizedCategory = _normalize(category);

    if (normalizedCategory.contains('acessorio')) {
      return 'Aces.';
    }

    if (normalizedCategory.contains('protec')) {
      return 'Prot.';
    }

    if (normalizedCategory.contains('equip')) {
      return 'Equip.';
    }

    if (normalizedCategory.contains('arma')) {
      return 'Arma';
    }

    if (normalizedCategory.contains('item')) {
      return 'Item';
    }

    final String trimmedCategory = category.trim();

    if (trimmedCategory.length <= 5) {
      return trimmedCategory;
    }

    return '${trimmedCategory.substring(0, 5)}.';
  }

  static const List<_PdfItemFields> _pdfItemFields = <_PdfItemFields>[
    _PdfItemFields('untitled256', 'untitled257', 'untitled258'),
    _PdfItemFields('untitled255', 'untitled262', 'untitled263'),
    _PdfItemFields('untitled264', 'untitled273', 'untitled282'),
    _PdfItemFields('untitled265', 'untitled274', 'untitled283'),
    _PdfItemFields('untitled266', 'untitled275', 'untitled284'),
    _PdfItemFields('untitled267', 'untitled276', 'untitled285'),
    _PdfItemFields('untitled268', 'untitled277', 'untitled286'),
    _PdfItemFields('untitled269', 'untitled278', 'untitled287'),
    _PdfItemFields('untitled270', 'untitled279', 'untitled288'),
    _PdfItemFields('untitled271', 'untitled280', 'untitled289'),
    _PdfItemFields('untitled272', 'untitled281', 'untitled290'),
    _PdfItemFields('untitled291', 'untitled301', 'untitled311'),
    _PdfItemFields('untitled292', 'untitled302', 'untitled312'),
    _PdfItemFields('untitled293', 'untitled303', 'untitled313'),
    _PdfItemFields('untitled294', 'untitled304', 'untitled314'),
    _PdfItemFields('untitled295', 'untitled305', 'untitled315'),
    _PdfItemFields('untitled296', 'untitled306', 'untitled316'),
    _PdfItemFields('untitled297', 'untitled307', 'untitled317'),
    _PdfItemFields('untitled298', 'untitled308', 'untitled318'),
    _PdfItemFields('untitled299', 'untitled309', 'untitled319'),
    _PdfItemFields('untitled300', 'untitled310', 'untitled320'),
  ];

  static const List<String> _pdfSkillNames = <String>[
    'Acrobacia',
    'Adestramento',
    'Artes',
    'Atletismo',
    'Atualidades',
    'Ciencias',
    'Crime',
    'Diplomacia',
    'Enganacao',
    'Fortitude',
    'Furtividade',
    'Iniciativa',
    'Intimidacao',
    'Intuicao',
    'Investigacao',
    'Luta',
    'Medicina',
    'Ocultismo',
    'Percepcao',
    'Pilotagem',
    'Pontaria',
    'Profissao',
    'Reflexos',
    'Religiao',
    'Sobrevivencia',
    'Tatica',
    'Tecnologia',
    'Vontade',
  ];
}

class _PdfItemFields {
  const _PdfItemFields(this.nameField, this.categoryField, this.weightField);

  final String nameField;
  final String categoryField;
  final String weightField;
}

class _PdfPowerLine {
  const _PdfPowerLine({
    required this.name,
    required this.cost,
    required this.page,
    required this.description,
  });

  final String name;
  final String cost;
  final String page;
  final String description;
}

class _PdfNotesPageWriter {
  _PdfNotesPageWriter({
    required this.pdfDocument,
    required String characterName,
  }) : characterName = characterName.trim().isEmpty
           ? 'Personagem sem nome'
           : characterName.trim();

  final PdfDocument pdfDocument;
  final String characterName;

  static const double _margin = 42;
  static const double _headerHeight = 72;
  static const double _footerHeight = 28;
  static const double _contentGap = 18;
  static const double _noteGap = 18;
  static const double _titleLineHeight = 17;
  static const double _contentLineHeight = 14;
  static const double _categoryLineHeight = 11;

  final PdfFont _headerFont = PdfStandardFont(
    PdfFontFamily.helvetica,
    18,
    style: PdfFontStyle.bold,
  );
  final PdfFont _subtitleFont = PdfStandardFont(PdfFontFamily.helvetica, 9);
  final PdfFont _categoryFont = PdfStandardFont(
    PdfFontFamily.helvetica,
    8,
    style: PdfFontStyle.bold,
  );
  final PdfFont _noteTitleFont = PdfStandardFont(
    PdfFontFamily.helvetica,
    13,
    style: PdfFontStyle.bold,
  );
  final PdfFont _contentFont = PdfStandardFont(PdfFontFamily.helvetica, 10);
  final PdfFont _footerFont = PdfStandardFont(PdfFontFamily.helvetica, 8);

  final PdfBrush _blackBrush = PdfSolidBrush(PdfColor(18, 18, 18));
  final PdfBrush _whiteBrush = PdfSolidBrush(PdfColor(255, 255, 255));
  final PdfBrush _mutedBrush = PdfSolidBrush(PdfColor(92, 92, 92));
  final PdfBrush _lightBrush = PdfSolidBrush(PdfColor(244, 244, 244));
  final PdfPen _linePen = PdfPen(PdfColor(210, 210, 210), width: 0.8);

  late PdfPage _currentPage;
  late Size _currentPageSize;
  late double _currentContentBottom;
  double _currentContentTop = 0;
  double _currentVerticalPosition = 0;
  int _notesPageNumber = 0;

  void writeNotes(List<CharacterNote> notes) {
    _startNewPage();

    for (final CharacterNote note in notes) {
      _drawNote(note);
    }
  }

  void _startNewPage() {
    _notesPageNumber += 1;
    _currentPage = pdfDocument.pages.add();
    _currentPageSize = _currentPage.getClientSize();
    _currentContentTop = _margin + _headerHeight + _contentGap;
    _currentContentBottom = _currentPageSize.height - _margin - _footerHeight;
    _currentVerticalPosition = _currentContentTop;

    _drawPageChrome();
  }

  void _drawPageChrome() {
    final PdfGraphics graphics = _currentPage.graphics;

    graphics.drawRectangle(
      brush: _whiteBrush,
      bounds: Rect.fromLTWH(
        0,
        0,
        _currentPageSize.width,
        _currentPageSize.height,
      ),
    );
    graphics.drawRectangle(
      brush: _blackBrush,
      bounds: Rect.fromLTWH(
        _margin,
        _margin,
        _currentPageSize.width - (_margin * 2),
        38,
      ),
    );
    graphics.drawRectangle(
      brush: _lightBrush,
      bounds: Rect.fromLTWH(
        _margin,
        _margin + 38,
        _currentPageSize.width - (_margin * 2),
        34,
      ),
    );
    graphics.drawString(
      'ANOTAÇÕES DO PERSONAGEM',
      _headerFont,
      brush: _whiteBrush,
      bounds: Rect.fromLTWH(
        _margin + 14,
        _margin + 9,
        _currentPageSize.width - (_margin * 2) - 28,
        22,
      ),
    );
    graphics.drawString(
      characterName,
      _subtitleFont,
      brush: _mutedBrush,
      bounds: Rect.fromLTWH(
        _margin + 14,
        _margin + 49,
        _currentPageSize.width - (_margin * 2) - 28,
        14,
      ),
    );
    graphics.drawString(
      'Página de anotações $_notesPageNumber',
      _footerFont,
      brush: _mutedBrush,
      bounds: Rect.fromLTWH(
        _margin,
        _currentPageSize.height - _margin - 10,
        _currentPageSize.width - (_margin * 2),
        10,
      ),
      format: PdfStringFormat(alignment: PdfTextAlignment.right),
    );
  }

  void _drawNote(CharacterNote note) {
    final double contentWidth = _currentPageSize.width - (_margin * 2);
    final String noteCategory = _noteCategoryLabel(note.category).toUpperCase();
    final String noteTitle = _printableText(note.title).isEmpty
        ? _noteCategoryLabel(note.category)
        : _printableText(note.title);
    final List<String> titleLines = _wrapText(
      noteTitle,
      _noteTitleFont,
      contentWidth,
    );
    final List<String> contentLines = _wrapText(
      _printableText(note.content),
      _contentFont,
      contentWidth,
    );

    final double headerHeight =
        _categoryLineHeight + (titleLines.length * _titleLineHeight) + 8;
    _ensureSpace(headerHeight + _contentLineHeight);

    _currentPage.graphics.drawString(
      noteCategory,
      _categoryFont,
      brush: _mutedBrush,
      bounds: Rect.fromLTWH(
        _margin,
        _currentVerticalPosition,
        contentWidth,
        _categoryLineHeight,
      ),
    );
    _currentVerticalPosition += _categoryLineHeight;

    for (final String titleLine in titleLines) {
      _drawLine(titleLine, _noteTitleFont, _blackBrush, _titleLineHeight);
    }

    _currentPage.graphics.drawLine(
      _linePen,
      Offset(_margin, _currentVerticalPosition + 2),
      Offset(_currentPageSize.width - _margin, _currentVerticalPosition + 2),
    );
    _currentVerticalPosition += 9;

    for (final String contentLine in contentLines) {
      _ensureSpace(_contentLineHeight);
      _drawLine(contentLine, _contentFont, _blackBrush, _contentLineHeight);
    }

    _currentVerticalPosition += _noteGap;
  }

  void _drawLine(String line, PdfFont font, PdfBrush brush, double lineHeight) {
    _currentPage.graphics.drawString(
      line,
      font,
      brush: brush,
      bounds: Rect.fromLTWH(
        _margin,
        _currentVerticalPosition,
        _currentPageSize.width - (_margin * 2),
        lineHeight,
      ),
    );
    _currentVerticalPosition += lineHeight;
  }

  void _ensureSpace(double requiredHeight) {
    if (_currentVerticalPosition + requiredHeight <= _currentContentBottom) {
      return;
    }

    _startNewPage();
  }

  List<String> _wrapText(String text, PdfFont font, double maxWidth) {
    if (text.trim().isEmpty) {
      return <String>[];
    }

    final List<String> wrappedLines = <String>[];
    final List<String> paragraphs = text
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .split('\n');

    for (final String paragraph in paragraphs) {
      final String trimmedParagraph = paragraph.trim();

      if (trimmedParagraph.isEmpty) {
        wrappedLines.add('');
        continue;
      }

      final List<String> words = trimmedParagraph.split(RegExp(r'\s+'));
      String currentLine = '';

      for (final String word in words) {
        final String candidateLine = currentLine.isEmpty
            ? word
            : '$currentLine $word';

        if (_textWidth(candidateLine, font) <= maxWidth) {
          currentLine = candidateLine;
          continue;
        }

        if (currentLine.isNotEmpty) {
          wrappedLines.add(currentLine);
        }

        if (_textWidth(word, font) <= maxWidth) {
          currentLine = word;
        } else {
          final List<String> splitWordLines = _splitLongWord(
            word,
            font,
            maxWidth,
          );
          wrappedLines.addAll(splitWordLines.take(splitWordLines.length - 1));
          currentLine = splitWordLines.last;
        }
      }

      if (currentLine.isNotEmpty) {
        wrappedLines.add(currentLine);
      }
    }

    return wrappedLines;
  }

  List<String> _splitLongWord(String word, PdfFont font, double maxWidth) {
    final List<String> splitLines = <String>[];
    String currentLine = '';

    for (final String character in word.split('')) {
      final String candidateLine = currentLine + character;

      if (candidateLine.length == 1 ||
          _textWidth(candidateLine, font) <= maxWidth) {
        currentLine = candidateLine;
      } else {
        splitLines.add(currentLine);
        currentLine = character;
      }
    }

    if (currentLine.isNotEmpty) {
      splitLines.add(currentLine);
    }

    return splitLines;
  }

  double _textWidth(String text, PdfFont font) {
    return font.measureString(text).width;
  }

  String _printableText(String value) {
    return value.trim();
  }

  String _noteCategoryLabel(String category) {
    final String normalizedCategory = _normalizeCategoryLabel(category);

    if (normalizedCategory == 'anotacoes') {
      return 'Anotações';
    }

    if (normalizedCategory == 'historico') {
      return 'Histórico';
    }

    return category.trim();
  }

  String _normalizeCategoryLabel(String value) {
    return value
        .toLowerCase()
        .replaceAll('\u00e7', 'c')
        .replaceAll('\u00e3', 'a')
        .replaceAll('\u00f5', 'o')
        .replaceAll('\u00f3', 'o')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '');
  }
}
