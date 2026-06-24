import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/character_sheet.dart';

class CrisCharacterImportService {
  CrisCharacterImportService({
    http.Client? httpClient,
    this.apiKey = const String.fromEnvironment('CRIS_FIREBASE_API_KEY'),
  }) : httpClient = httpClient ?? http.Client();

  static const String _projectId = 'cris-ordem-paranormal';
  static const String _publicWebApiKey =
      'AIzaSyADXkE6U5j_hlSRxK3nfqyylmPXgUeGWsQ';

  final http.Client httpClient;
  final String apiKey;

  Future<CharacterSheet> importFromUrl(String crisUrl) async {
    final String characterId = extractCharacterId(crisUrl);
    final Uri firestoreUri = Uri.https(
      'firestore.googleapis.com',
      '/v1/projects/$_projectId/databases/(default)/documents/characters/$characterId',
      <String, String>{'key': _resolvedApiKey},
    );

    final http.Response response = await httpClient.get(firestoreUri);

    if (response.statusCode != 200) {
      throw StateError('Ficha C.R.I.S. não encontrada ou privada.');
    }

    final Object? decodedBody = jsonDecode(response.body);

    if (decodedBody is! Map) {
      throw const FormatException('Resposta inválida do C.R.I.S.');
    }

    return characterSheetFromFirestoreDocument(
      decodedBody.map(
        (Object? rawKey, Object? rawValue) =>
            MapEntry(rawKey.toString(), rawValue),
      ),
      sourceUrl: crisUrl,
    );
  }

  String extractCharacterId(String crisUrl) {
    final String normalizedInput = crisUrl.trim();

    if (normalizedInput.isEmpty) {
      throw const FormatException('Informe o link da ficha C.R.I.S.');
    }

    final Uri? parsedUri = Uri.tryParse(normalizedInput);
    final List<String> pathSegments = parsedUri?.pathSegments ?? <String>[];
    final int agentSegmentIndex = pathSegments.indexOf('agente');

    if (agentSegmentIndex >= 0 && pathSegments.length > agentSegmentIndex + 1) {
      return pathSegments[agentSegmentIndex + 1];
    }

    if (RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(normalizedInput)) {
      return normalizedInput;
    }

    throw const FormatException('Link C.R.I.S. inválido.');
  }

  String get _resolvedApiKey {
    final String configuredApiKey = apiKey.trim();

    if (configuredApiKey.isNotEmpty) {
      return configuredApiKey;
    }

    return _publicWebApiKey;
  }

  CharacterSheet characterSheetFromFirestoreDocument(
    Map<String, Object?> firestoreDocument, {
    required String sourceUrl,
  }) {
    final Map<String, Object?> firestoreFields = _mapValue(
      firestoreDocument['fields'],
    );
    final Map<String, Object?> characterData = _decodeFirestoreFields(
      firestoreFields,
    );
    final DateTime currentDate = DateTime.now();

    return CharacterSheet.empty().copyWith(
      characterName: _text(characterData['name'], fallback: 'Ficha C.R.I.S.'),
      playerName: _text(characterData['player']),
      origin: _text(characterData['backgroundName']),
      characterClass: _text(characterData['className']),
      characterPath: _text(characterData['statsClass']),
      rank: _text(characterData['patent']),
      exposureLevel: _percentNumber(characterData['nex']),
      movement: _integer(characterData['movement'], fallback: 9),
      lifeCurrent: _integer(characterData['currentPv'], fallback: 1),
      lifeMaximum: _integer(characterData['maxPv'], fallback: 1),
      useManualLifeMaximum: true,
      sanityCurrent: _integer(characterData['currentSan']),
      sanityMaximum: _integer(characterData['maxSan'], fallback: 1),
      useManualSanityMaximum: true,
      effortCurrent: _integer(characterData['currentPe']),
      effortMaximum: _integer(characterData['maxPe'], fallback: 1),
      useManualEffortMaximum: true,
      baseDefense: 10,
      defenseManualBonus: _integer(characterData['bonusDefense']),
      defense:
          10 +
          _integer(_mapValue(characterData['attributes'])['dex']) +
          _integer(characterData['protectionDefense']) +
          _integer(characterData['bonusDefense']),
      useManualDefense: true,
      attributes: _attributesFromCris(characterData),
      skills: _skillsFromCris(characterData),
      weapons: _weaponsFromCris(characterData),
      items: _itemsFromCris(characterData),
      rituals: _ritualsFromCris(characterData),
      powers: _powersFromCris(characterData),
      notes: _notesFromCris(characterData, sourceUrl),
      createdAt: currentDate,
      updatedAt: currentDate,
    );
  }

  CharacterAttributes _attributesFromCris(Map<String, Object?> characterData) {
    final Map<String, Object?> attributes = _mapValue(
      characterData['attributes'],
    );

    return CharacterAttributes(
      strength: _integer(attributes['str'], fallback: 1),
      agility: _integer(attributes['dex'], fallback: 1),
      intellect: _integer(attributes['int'], fallback: 1),
      presence: _integer(attributes['pre'], fallback: 1),
      vigor: _integer(attributes['con'], fallback: 1),
    );
  }

  List<CharacterSkill> _skillsFromCris(Map<String, Object?> characterData) {
    final List<Object?> skills = _listValue(characterData['skills']);

    if (skills.isEmpty) {
      return CharacterSkill.defaultSkills();
    }

    return skills.map((Object? rawSkill) {
      final Map<String, Object?> skill = _mapValue(rawSkill);
      final String attribute = _text(skill['attribute']);

      return CharacterSkill(
        name: _text(skill['name'], fallback: 'Perícia'),
        training: _integer(skill['trainingDegree']),
        bonus: _integer(skill['otherBonus']),
        notes: attribute.isEmpty ? '' : 'Atributo no C.R.I.S.: $attribute',
      );
    }).toList();
  }

  List<CharacterWeapon> _weaponsFromCris(Map<String, Object?> characterData) {
    final List<Object?> attacks = _listValue(characterData['attacks']);

    return attacks.map((Object? rawAttack) {
      final Map<String, Object?> attack = _mapValue(rawAttack);
      final String criticalRange = _text(attack['criticalRange']);
      final String criticalMultiplier = _text(attack['criticalMult']);
      final String skillUsed = _text(attack['skillUsed']);
      final String damageType = _text(attack['damageType']);

      return CharacterWeapon(
        name: _text(attack['name'], fallback: 'Ataque C.R.I.S.'),
        attackBonus: _integer(attack['attackBonus']),
        damage: _text(attack['damage']),
        critical: [
          if (criticalRange.isNotEmpty) 'Margem $criticalRange',
          if (criticalMultiplier.isNotEmpty) 'x$criticalMultiplier',
        ].join(' / '),
        range: _text(attack['range']),
        notes: [
          if (skillUsed.isNotEmpty) 'Perícia: $skillUsed',
          if (damageType.isNotEmpty) 'Tipo: $damageType',
        ].join('\n'),
      );
    }).toList();
  }

  List<CharacterItem> _itemsFromCris(Map<String, Object?> characterData) {
    final List<Object?> inventory = _listValue(characterData['inventory']);

    return inventory.map((Object? rawItem) {
      final Map<String, Object?> item = _mapValue(rawItem);
      final String itemType = _text(item['itemType'], fallback: 'item');
      final String tag = _text(item['tag']);
      final String category = _text(item['category']);
      final String itemCategory = tag.isNotEmpty
          ? tag
          : itemType == 'protection'
          ? 'Proteção'
          : category.isNotEmpty
          ? category
          : 'Item';

      return CharacterItem(
        name: _text(item['name'], fallback: 'Item C.R.I.S.'),
        category: itemCategory,
        quantity: 1,
        weight: _integer(item['slots']),
        defenseBonus: _integer(item['defense']),
        notes: itemType.isEmpty ? '' : 'Tipo no C.R.I.S.: $itemType',
      );
    }).toList();
  }

  List<CharacterRitual> _ritualsFromCris(Map<String, Object?> characterData) {
    return _listValue(characterData['rituals']).map((Object? rawRitual) {
      final Map<String, Object?> ritual = _mapValue(rawRitual);

      return CharacterRitual(
        name: _text(ritual['name'], fallback: 'Ritual C.R.I.S.'),
        circle: _text(ritual['circle']),
        cost: _text(ritual['cost']),
        description: '',
      );
    }).toList();
  }

  List<CharacterPower> _powersFromCris(Map<String, Object?> characterData) {
    return _listValue(characterData['powers']).map((Object? rawPower) {
      final Map<String, Object?> power = _mapValue(rawPower);

      return CharacterPower(
        name: _text(power['name'], fallback: 'Poder C.R.I.S.'),
        category: _text(power['category'], fallback: 'Poder'),
        description: '',
      );
    }).toList();
  }

  List<CharacterNote> _notesFromCris(
    Map<String, Object?> characterData,
    String sourceUrl,
  ) {
    final Map<String, Object?> description = _mapValue(
      characterData['description'],
    );
    final List<CharacterNote> notes = <CharacterNote>[];

    void addDescriptionNote(String key, String title) {
      final String content = _text(description[key]);

      if (content.isEmpty) {
        return;
      }

      notes.add(
        CharacterNote(
          category: key == 'history'
              ? CharacterNoteCategory.history
              : CharacterNoteCategory.general,
          title: title,
          content: content,
        ),
      );
    }

    addDescriptionNote('history', 'Histórico');
    addDescriptionNote('physical', 'Descrição física');
    addDescriptionNote('goal', 'Objetivo');
    addDescriptionNote('personal', 'Personalidade');
    addDescriptionNote('anotation', 'Anotações');

    notes.add(
      CharacterNote(
        category: CharacterNoteCategory.general,
        title: 'Importação C.R.I.S.',
        content:
            'Fonte: $sourceUrl\nDescrições longas de regras, itens, poderes e rituais não foram importadas automaticamente.',
      ),
    );

    return notes;
  }

  Map<String, Object?> _decodeFirestoreFields(
    Map<String, Object?> firestoreFields,
  ) {
    return firestoreFields.map(
      (String key, Object? rawValue) =>
          MapEntry(key, _decodeFirestoreValue(_mapValue(rawValue))),
    );
  }

  Object? _decodeFirestoreValue(Map<String, Object?> firestoreValue) {
    if (firestoreValue.containsKey('stringValue')) {
      return firestoreValue['stringValue'] as String? ?? '';
    }

    if (firestoreValue.containsKey('integerValue')) {
      return int.tryParse(firestoreValue['integerValue'].toString()) ?? 0;
    }

    if (firestoreValue.containsKey('doubleValue')) {
      return double.tryParse(firestoreValue['doubleValue'].toString()) ?? 0;
    }

    if (firestoreValue.containsKey('booleanValue')) {
      return firestoreValue['booleanValue'] == true;
    }

    if (firestoreValue.containsKey('timestampValue')) {
      return firestoreValue['timestampValue'] as String? ?? '';
    }

    if (firestoreValue.containsKey('mapValue')) {
      final Map<String, Object?> mapValue = _mapValue(
        firestoreValue['mapValue'],
      );
      return _decodeFirestoreFields(_mapValue(mapValue['fields']));
    }

    if (firestoreValue.containsKey('arrayValue')) {
      final Map<String, Object?> arrayValue = _mapValue(
        firestoreValue['arrayValue'],
      );
      return _listValue(arrayValue['values'])
          .map(
            (Object? rawArrayItem) =>
                _decodeFirestoreValue(_mapValue(rawArrayItem)),
          )
          .toList();
    }

    return null;
  }

  Map<String, Object?> _mapValue(Object? rawValue) {
    if (rawValue is Map<String, Object?>) {
      return rawValue;
    }

    if (rawValue is Map) {
      return rawValue.map(
        (Object? rawKey, Object? rawMapValue) =>
            MapEntry(rawKey.toString(), rawMapValue),
      );
    }

    return <String, Object?>{};
  }

  List<Object?> _listValue(Object? rawValue) {
    if (rawValue is List) {
      return rawValue;
    }

    return <Object?>[];
  }

  String _text(Object? rawValue, {String fallback = ''}) {
    if (rawValue == null) {
      return fallback;
    }

    final String text = rawValue.toString();

    if (text.trim().isEmpty) {
      return fallback;
    }

    return text;
  }

  int _integer(Object? rawValue, {int fallback = 0}) {
    if (rawValue is int) {
      return rawValue;
    }

    if (rawValue is num) {
      return rawValue.toInt();
    }

    if (rawValue is String) {
      return int.tryParse(rawValue) ?? fallback;
    }

    return fallback;
  }

  int _percentNumber(Object? rawValue) {
    final String text = _text(rawValue);
    final String onlyDigits = text.replaceAll(RegExp('[^0-9]'), '');

    return int.tryParse(onlyDigits) ?? 0;
  }
}
