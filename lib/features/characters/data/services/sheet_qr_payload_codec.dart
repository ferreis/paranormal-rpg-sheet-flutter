import 'dart:convert';
import 'dart:typed_data';

class SheetQrPayloadCodec {
  const SheetQrPayloadCodec();

  Uint8List encodeBytes(String jsonContent) {
    final Object? decodedJson = jsonDecode(jsonContent);

    if (decodedJson is! Map) {
      throw const FormatException('JSON inválido para ficha.');
    }

    final _BinaryWriter binaryWriter = _BinaryWriter();

    binaryWriter.writeByte(1);
    binaryWriter.writeValue(_toCompactSheetData(_stringKeyMap(decodedJson)));

    return binaryWriter.toBytes();
  }

  String decodeBytes(Uint8List payloadBytes) {
    final _BinaryReader binaryReader = _BinaryReader(payloadBytes);
    final int formatVersion = binaryReader.readByte();

    if (formatVersion != 1) {
      throw const FormatException('Formato de ficha binária inválido.');
    }

    final Object? compactSheetData = binaryReader.readValue();

    return jsonEncode(_fromCompactSheetData(_objectList(compactSheetData)));
  }

  String decodeCompactJson(String jsonContent) {
    try {
      final Object? decodedJson = jsonDecode(jsonContent);

      if (decodedJson is Map) {
        final Map<String, Object?> jsonMap = _stringKeyMap(decodedJson);

        if (jsonMap['v'] == 1) {
          return jsonEncode(_fromCompactSheetJson(jsonMap));
        }
      }
    } on FormatException {
      return jsonContent;
    }

    return jsonContent;
  }

  List<Object?> _toCompactSheetData(Map<String, Object?> jsonMap) {
    return <Object?>[
      _trimTrailingValues(
        <Object?>[
          jsonMap['characterName'],
          jsonMap['playerName'],
          jsonMap['origin'],
          jsonMap['characterClass'],
          jsonMap['characterPath'],
          jsonMap['rank'],
          jsonMap['exposureLevel'],
          jsonMap['movement'],
        ],
        <Object?>['', '', '', '', '', '', 0, 9],
      ),
      _trimTrailingValues(
        <Object?>[
          jsonMap['baseLife'],
          jsonMap['lifePerVigor'],
          jsonMap['lifeManualBonus'],
          jsonMap['lifeCurrent'],
          jsonMap['lifeMaximum'],
          jsonMap['useManualLifeMaximum'],
        ],
        <Object?>[16, 4, 0, 16, 16, false],
      ),
      _trimTrailingValues(
        <Object?>[
          jsonMap['baseSanity'],
          jsonMap['sanityPerPresence'],
          jsonMap['sanityManualBonus'],
          jsonMap['sanityCurrent'],
          jsonMap['sanityMaximum'],
          jsonMap['useManualSanityMaximum'],
        ],
        <Object?>[12, 2, 0, 12, 12, false],
      ),
      _trimTrailingValues(
        <Object?>[
          jsonMap['baseEffort'],
          jsonMap['effortPerPresence'],
          jsonMap['effortManualBonus'],
          jsonMap['effortCurrent'],
          jsonMap['effortMaximum'],
          jsonMap['useManualEffortMaximum'],
        ],
        <Object?>[2, 1, 0, 2, 2, false],
      ),
      _trimTrailingValues(
        <Object?>[
          jsonMap['baseDefense'],
          jsonMap['defenseManualBonus'],
          jsonMap['defense'],
          jsonMap['useManualDefense'],
        ],
        <Object?>[10, 0, 10, false],
      ),
      _compactAttributesData(jsonMap['attributes']),
      _compactDataList(jsonMap['skills'], _compactSkillData),
      _compactDataList(jsonMap['weapons'], _compactWeaponData),
      _compactDataList(jsonMap['items'], _compactItemData),
      _compactDataList(jsonMap['rituals'], _compactRitualData),
      _compactDataList(jsonMap['powers'], _compactPowerData),
      _compactDataList(jsonMap['notes'], _compactNoteData),
    ];
  }

  Map<String, Object?> _fromCompactSheetData(List<Object?> compactSheetData) {
    final List<Object?> baseValues = _objectList(
      _listValue(compactSheetData, 0, <Object?>[]),
    );
    final List<Object?> lifeValues = _objectList(
      _listValue(compactSheetData, 1, <Object?>[]),
    );
    final List<Object?> sanityValues = _objectList(
      _listValue(compactSheetData, 2, <Object?>[]),
    );
    final List<Object?> effortValues = _objectList(
      _listValue(compactSheetData, 3, <Object?>[]),
    );
    final List<Object?> defenseValues = _objectList(
      _listValue(compactSheetData, 4, <Object?>[]),
    );

    return <String, Object?>{
      'characterName': _listValue(baseValues, 0, ''),
      'playerName': _listValue(baseValues, 1, ''),
      'origin': _listValue(baseValues, 2, ''),
      'characterClass': _listValue(baseValues, 3, ''),
      'characterPath': _listValue(baseValues, 4, ''),
      'rank': _listValue(baseValues, 5, ''),
      'exposureLevel': _listValue(baseValues, 6, 0),
      'movement': _listValue(baseValues, 7, 9),
      'baseLife': _listValue(lifeValues, 0, 16),
      'lifePerVigor': _listValue(lifeValues, 1, 4),
      'lifeManualBonus': _listValue(lifeValues, 2, 0),
      'lifeCurrent': _listValue(lifeValues, 3, 16),
      'lifeMaximum': _listValue(lifeValues, 4, 16),
      'useManualLifeMaximum': _listValue(lifeValues, 5, false),
      'baseSanity': _listValue(sanityValues, 0, 12),
      'sanityPerPresence': _listValue(sanityValues, 1, 2),
      'sanityManualBonus': _listValue(sanityValues, 2, 0),
      'sanityCurrent': _listValue(sanityValues, 3, 12),
      'sanityMaximum': _listValue(sanityValues, 4, 12),
      'useManualSanityMaximum': _listValue(sanityValues, 5, false),
      'baseEffort': _listValue(effortValues, 0, 2),
      'effortPerPresence': _listValue(effortValues, 1, 1),
      'effortManualBonus': _listValue(effortValues, 2, 0),
      'effortCurrent': _listValue(effortValues, 3, 2),
      'effortMaximum': _listValue(effortValues, 4, 2),
      'useManualEffortMaximum': _listValue(effortValues, 5, false),
      'baseDefense': _listValue(defenseValues, 0, 10),
      'defenseManualBonus': _listValue(defenseValues, 1, 0),
      'defense': _listValue(defenseValues, 2, 10),
      'useManualDefense': _listValue(defenseValues, 3, false),
      'attributes': _expandAttributesData(
        _listValue(compactSheetData, 5, <Object?>[]),
      ),
      'skills': _expandDataList(
        _listValue(compactSheetData, 6, <Object?>[]),
        _expandSkillData,
      ),
      'weapons': _expandDataList(
        _listValue(compactSheetData, 7, <Object?>[]),
        _expandWeaponData,
      ),
      'items': _expandDataList(
        _listValue(compactSheetData, 8, <Object?>[]),
        _expandItemData,
      ),
      'rituals': _expandDataList(
        _listValue(compactSheetData, 9, <Object?>[]),
        _expandRitualData,
      ),
      'powers': _expandDataList(
        _listValue(compactSheetData, 10, <Object?>[]),
        _expandPowerData,
      ),
      'notes': _expandDataList(
        _listValue(compactSheetData, 11, <Object?>[]),
        _expandNoteData,
      ),
    };
  }

  Map<String, Object?> _fromCompactSheetJson(Map<String, Object?> jsonMap) {
    return _fromCompactSheetData(<Object?>[
      jsonMap['b'],
      jsonMap['l'],
      jsonMap['s'],
      jsonMap['e'],
      jsonMap['d'],
      jsonMap['a'],
      jsonMap['k'],
      jsonMap['w'],
      jsonMap['i'],
      jsonMap['r'],
      jsonMap['p'],
      jsonMap['n'],
    ]);
  }

  List<Object?> _compactAttributesData(Object? rawAttributesJson) {
    final Map<String, Object?> attributesJson = _stringKeyMap(
      rawAttributesJson,
    );

    return _trimTrailingValues(
      <Object?>[
        attributesJson['strength'],
        attributesJson['agility'],
        attributesJson['intellect'],
        attributesJson['presence'],
        attributesJson['vigor'],
      ],
      <Object?>[1, 1, 1, 1, 1],
    );
  }

  Map<String, Object?> _expandAttributesData(Object? rawCompactData) {
    final List<Object?> compactData = _objectList(rawCompactData);

    return <String, Object?>{
      'strength': _listValue(compactData, 0, 1),
      'agility': _listValue(compactData, 1, 1),
      'intellect': _listValue(compactData, 2, 1),
      'presence': _listValue(compactData, 3, 1),
      'vigor': _listValue(compactData, 4, 1),
    };
  }

  List<Object?> _compactSkillData(Map<String, Object?> jsonMap) {
    return _trimTrailingValues(
      <Object?>[
        jsonMap['name'],
        jsonMap['training'],
        jsonMap['bonus'],
        jsonMap['notes'],
      ],
      <Object?>['', 0, 0, ''],
    );
  }

  Map<String, Object?> _expandSkillData(Object? rawCompactData) {
    final List<Object?> compactData = _objectList(rawCompactData);

    return <String, Object?>{
      'name': _listValue(compactData, 0, ''),
      'training': _listValue(compactData, 1, 0),
      'bonus': _listValue(compactData, 2, 0),
      'notes': _listValue(compactData, 3, ''),
    };
  }

  List<Object?> _compactWeaponData(Map<String, Object?> jsonMap) {
    return _trimTrailingValues(
      <Object?>[
        jsonMap['name'],
        jsonMap['attackBonus'],
        jsonMap['damage'],
        jsonMap['critical'],
        jsonMap['range'],
        jsonMap['notes'],
      ],
      <Object?>['', 0, '', '', '', ''],
    );
  }

  Map<String, Object?> _expandWeaponData(Object? rawCompactData) {
    final List<Object?> compactData = _objectList(rawCompactData);

    return <String, Object?>{
      'name': _listValue(compactData, 0, ''),
      'attackBonus': _listValue(compactData, 1, 0),
      'damage': _listValue(compactData, 2, ''),
      'critical': _listValue(compactData, 3, ''),
      'range': _listValue(compactData, 4, ''),
      'notes': _listValue(compactData, 5, ''),
    };
  }

  List<Object?> _compactItemData(Map<String, Object?> jsonMap) {
    return _trimTrailingValues(
      <Object?>[
        jsonMap['name'],
        jsonMap['category'],
        jsonMap['quantity'],
        jsonMap['weight'],
        jsonMap['defenseBonus'],
        jsonMap['notes'],
      ],
      <Object?>['', 'Item', 1, 0, 0, ''],
    );
  }

  Map<String, Object?> _expandItemData(Object? rawCompactData) {
    final List<Object?> compactData = _objectList(rawCompactData);

    return <String, Object?>{
      'name': _listValue(compactData, 0, ''),
      'category': _listValue(compactData, 1, 'Item'),
      'quantity': _listValue(compactData, 2, 1),
      'weight': _listValue(compactData, 3, 0),
      'defenseBonus': _listValue(compactData, 4, 0),
      'notes': _listValue(compactData, 5, ''),
    };
  }

  List<Object?> _compactRitualData(Map<String, Object?> jsonMap) {
    return _trimTrailingValues(
      <Object?>[
        jsonMap['name'],
        jsonMap['circle'],
        jsonMap['cost'],
        jsonMap['description'],
      ],
      <Object?>['', '', '', ''],
    );
  }

  Map<String, Object?> _expandRitualData(Object? rawCompactData) {
    final List<Object?> compactData = _objectList(rawCompactData);

    return <String, Object?>{
      'name': _listValue(compactData, 0, ''),
      'circle': _listValue(compactData, 1, ''),
      'cost': _listValue(compactData, 2, ''),
      'description': _listValue(compactData, 3, ''),
    };
  }

  List<Object?> _compactPowerData(Map<String, Object?> jsonMap) {
    return _trimTrailingValues(
      <Object?>[jsonMap['name'], jsonMap['category'], jsonMap['description']],
      <Object?>['', 'Poder', ''],
    );
  }

  Map<String, Object?> _expandPowerData(Object? rawCompactData) {
    final List<Object?> compactData = _objectList(rawCompactData);

    return <String, Object?>{
      'name': _listValue(compactData, 0, ''),
      'category': _listValue(compactData, 1, 'Poder'),
      'description': _listValue(compactData, 2, ''),
    };
  }

  List<Object?> _compactNoteData(Map<String, Object?> jsonMap) {
    return _trimTrailingValues(
      <Object?>[jsonMap['category'], jsonMap['title'], jsonMap['content']],
      <Object?>['Anotações', '', ''],
    );
  }

  Map<String, Object?> _expandNoteData(Object? rawCompactData) {
    final List<Object?> compactData = _objectList(rawCompactData);

    return <String, Object?>{
      'category': _listValue(compactData, 0, 'Anotações'),
      'title': _listValue(compactData, 1, ''),
      'content': _listValue(compactData, 2, ''),
    };
  }

  List<Object?> _compactDataList(
    Object? rawJsonList,
    List<Object?> Function(Map<String, Object?> jsonMap) compactData,
  ) {
    return _objectList(
      rawJsonList,
    ).map((Object? rawJson) => compactData(_stringKeyMap(rawJson))).toList();
  }

  List<Map<String, Object?>> _expandDataList(
    Object? rawCompactDataList,
    Map<String, Object?> Function(Object? rawCompactData) expandData,
  ) {
    return _objectList(rawCompactDataList).map(expandData).toList();
  }

  Map<String, Object?> _stringKeyMap(Object? rawJsonValue) {
    if (rawJsonValue is Map<String, Object?>) {
      return rawJsonValue;
    }

    if (rawJsonValue is Map) {
      return rawJsonValue.map(
        (Object? rawKey, Object? rawValue) =>
            MapEntry(rawKey.toString(), rawValue),
      );
    }

    return <String, Object?>{};
  }

  List<Object?> _objectList(Object? rawJsonValue) {
    if (rawJsonValue is List) {
      return rawJsonValue;
    }

    return <Object?>[];
  }

  List<Object?> _trimTrailingValues(
    List<Object?> values,
    List<Object?> defaultValues,
  ) {
    int lastCustomValueIndex = values.length - 1;

    while (lastCustomValueIndex >= 0 &&
        values[lastCustomValueIndex] == defaultValues[lastCustomValueIndex]) {
      lastCustomValueIndex -= 1;
    }

    return values.take(lastCustomValueIndex + 1).toList();
  }

  Object? _listValue(List<Object?> values, int valueIndex, [Object? fallback]) {
    if (valueIndex >= values.length) {
      return fallback;
    }

    return values[valueIndex];
  }
}

class _BinaryWriter {
  final BytesBuilder _bytesBuilder = BytesBuilder();

  Uint8List toBytes() {
    return _bytesBuilder.toBytes();
  }

  void writeValue(Object? value) {
    if (value == null) {
      writeByte(0);
      return;
    }

    if (value == false) {
      writeByte(1);
      return;
    }

    if (value == true) {
      writeByte(2);
      return;
    }

    if (value is int) {
      writeByte(3);
      _writeUnsignedInt(_encodeZigZag(value));
      return;
    }

    if (value is num) {
      writeByte(3);
      _writeUnsignedInt(_encodeZigZag(value.toInt()));
      return;
    }

    if (value is String) {
      final List<int> stringBytes = utf8.encode(value);

      writeByte(4);
      _writeUnsignedInt(stringBytes.length);
      _bytesBuilder.add(stringBytes);
      return;
    }

    if (value is List) {
      writeByte(5);
      _writeUnsignedInt(value.length);

      for (final Object? childValue in value) {
        writeValue(childValue);
      }
      return;
    }

    throw const FormatException('Tipo não suportado no payload da ficha.');
  }

  void writeByte(int value) {
    _bytesBuilder.add(<int>[value & 0xff]);
  }

  void _writeUnsignedInt(int value) {
    int remainingValue = value;

    while (remainingValue >= 0x80) {
      writeByte((remainingValue & 0x7f) | 0x80);
      remainingValue >>= 7;
    }

    writeByte(remainingValue);
  }

  int _encodeZigZag(int value) {
    return value < 0 ? (-value * 2) - 1 : value * 2;
  }
}

class _BinaryReader {
  _BinaryReader(this.bytes);

  final Uint8List bytes;
  int _offset = 0;

  Object? readValue() {
    final int valueType = readByte();

    return switch (valueType) {
      0 => null,
      1 => false,
      2 => true,
      3 => _decodeZigZag(_readUnsignedInt()),
      4 => _readString(),
      5 => _readList(),
      _ => throw const FormatException('Tipo inválido no payload da ficha.'),
    };
  }

  int readByte() {
    if (_offset >= bytes.length) {
      throw const FormatException('Payload de ficha incompleto.');
    }

    final int value = bytes[_offset];
    _offset += 1;

    return value;
  }

  int _readUnsignedInt() {
    int value = 0;
    int shift = 0;

    while (true) {
      final int currentByte = readByte();

      value |= (currentByte & 0x7f) << shift;

      if ((currentByte & 0x80) == 0) {
        return value;
      }

      shift += 7;

      if (shift > 63) {
        throw const FormatException('Número inválido no payload da ficha.');
      }
    }
  }

  String _readString() {
    final int stringLength = _readUnsignedInt();
    final int endOffset = _offset + stringLength;

    if (endOffset > bytes.length) {
      throw const FormatException('Texto inválido no payload da ficha.');
    }

    final String value = utf8.decode(bytes.sublist(_offset, endOffset));

    _offset = endOffset;

    return value;
  }

  List<Object?> _readList() {
    final int listLength = _readUnsignedInt();
    final List<Object?> values = <Object?>[];

    for (int valueIndex = 0; valueIndex < listLength; valueIndex += 1) {
      values.add(readValue());
    }

    return values;
  }

  int _decodeZigZag(int value) {
    return value.isOdd ? -((value + 1) ~/ 2) : value ~/ 2;
  }
}
