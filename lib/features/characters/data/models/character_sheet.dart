class CharacterSheet {
  CharacterSheet({
    this.id,
    required this.characterName,
    required this.playerName,
    required this.origin,
    required this.characterClass,
    required this.characterPath,
    required this.rank,
    required this.exposureLevel,
    required this.movement,
    required this.baseLife,
    required this.lifePerVigor,
    required this.lifeManualBonus,
    required this.lifeCurrent,
    required this.lifeMaximum,
    required this.useManualLifeMaximum,
    required this.baseSanity,
    required this.sanityPerPresence,
    required this.sanityManualBonus,
    required this.sanityCurrent,
    required this.sanityMaximum,
    required this.useManualSanityMaximum,
    required this.baseEffort,
    required this.effortPerPresence,
    required this.effortManualBonus,
    required this.effortCurrent,
    required this.effortMaximum,
    required this.useManualEffortMaximum,
    required this.baseDefense,
    required this.defenseManualBonus,
    required this.defense,
    required this.useManualDefense,
    required this.attributes,
    required this.skills,
    required this.weapons,
    required this.items,
    required this.rituals,
    required this.powers,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CharacterSheet.empty() {
    final DateTime currentDate = DateTime.now();

    return CharacterSheet(
      characterName: 'Novo personagem',
      playerName: '',
      origin: '',
      characterClass: '',
      characterPath: '',
      rank: '',
      exposureLevel: 0,
      movement: 9,
      baseLife: 16,
      lifePerVigor: 4,
      lifeManualBonus: 0,
      lifeCurrent: 16,
      lifeMaximum: 16,
      useManualLifeMaximum: false,
      baseSanity: 12,
      sanityPerPresence: 2,
      sanityManualBonus: 0,
      sanityCurrent: 12,
      sanityMaximum: 12,
      useManualSanityMaximum: false,
      baseEffort: 2,
      effortPerPresence: 1,
      effortManualBonus: 0,
      effortCurrent: 2,
      effortMaximum: 2,
      useManualEffortMaximum: false,
      baseDefense: 10,
      defenseManualBonus: 0,
      defense: 10,
      useManualDefense: false,
      attributes: CharacterAttributes.empty(),
      skills: CharacterSkill.defaultSkills(),
      weapons: <CharacterWeapon>[],
      items: <CharacterItem>[],
      rituals: <CharacterRitual>[],
      powers: <CharacterPower>[],
      notes: <CharacterNote>[
        CharacterNote.empty(category: CharacterNoteCategory.general),
        CharacterNote.empty(category: CharacterNoteCategory.history),
      ],
      createdAt: currentDate,
      updatedAt: currentDate,
    );
  }

  factory CharacterSheet.fromDatabase({
    required Map<String, Object?> characterRow,
    required CharacterAttributes attributes,
    required List<CharacterSkill> skills,
    required List<CharacterWeapon> weapons,
    required List<CharacterItem> items,
    required List<CharacterRitual> rituals,
    required List<CharacterPower> powers,
    required List<CharacterNote> notes,
  }) {
    return CharacterSheet(
      id: characterRow['id'] as int?,
      characterName: characterRow['character_name'] as String? ?? '',
      playerName: characterRow['player_name'] as String? ?? '',
      origin: characterRow['origin'] as String? ?? '',
      characterClass: characterRow['class_name'] as String? ?? '',
      characterPath: characterRow['path_name'] as String? ?? '',
      rank: characterRow['rank_name'] as String? ?? '',
      exposureLevel: characterRow['exposure_level'] as int? ?? 0,
      movement: characterRow['movement'] as int? ?? 0,
      baseLife: characterRow['base_life'] as int? ?? 0,
      lifePerVigor: characterRow['life_per_vigor'] as int? ?? 0,
      lifeManualBonus: characterRow['life_manual_bonus'] as int? ?? 0,
      lifeCurrent: characterRow['life_current'] as int? ?? 0,
      lifeMaximum: characterRow['life_maximum'] as int? ?? 0,
      useManualLifeMaximum: _intToBool(characterRow['use_manual_life_maximum']),
      baseSanity: characterRow['base_sanity'] as int? ?? 0,
      sanityPerPresence: characterRow['sanity_per_presence'] as int? ?? 0,
      sanityManualBonus: characterRow['sanity_manual_bonus'] as int? ?? 0,
      sanityCurrent: characterRow['sanity_current'] as int? ?? 0,
      sanityMaximum: characterRow['sanity_maximum'] as int? ?? 0,
      useManualSanityMaximum: _intToBool(
        characterRow['use_manual_sanity_maximum'],
      ),
      baseEffort: characterRow['base_effort'] as int? ?? 0,
      effortPerPresence: characterRow['effort_per_presence'] as int? ?? 0,
      effortManualBonus: characterRow['effort_manual_bonus'] as int? ?? 0,
      effortCurrent: characterRow['effort_current'] as int? ?? 0,
      effortMaximum: characterRow['effort_maximum'] as int? ?? 0,
      useManualEffortMaximum: _intToBool(
        characterRow['use_manual_effort_maximum'],
      ),
      baseDefense: characterRow['base_defense'] as int? ?? 0,
      defenseManualBonus: characterRow['defense_manual_bonus'] as int? ?? 0,
      defense: characterRow['defense'] as int? ?? 0,
      useManualDefense: _intToBool(characterRow['use_manual_defense']),
      attributes: attributes,
      skills: skills,
      weapons: weapons,
      items: items,
      rituals: rituals,
      powers: powers,
      notes: notes,
      createdAt: DateTime.parse(characterRow['created_at'] as String),
      updatedAt: DateTime.parse(characterRow['updated_at'] as String),
    );
  }

  factory CharacterSheet.fromJson(Map<String, Object?> jsonMap) {
    final DateTime currentDate = DateTime.now();
    final Map<String, Object?> attributesJson = _objectMap(
      jsonMap['attributes'],
    );

    return CharacterSheet(
      characterName: jsonMap['characterName'] as String? ?? 'Personagem',
      playerName: jsonMap['playerName'] as String? ?? '',
      origin: jsonMap['origin'] as String? ?? '',
      characterClass: jsonMap['characterClass'] as String? ?? '',
      characterPath: jsonMap['characterPath'] as String? ?? '',
      rank: jsonMap['rank'] as String? ?? '',
      exposureLevel: _jsonInt(jsonMap['exposureLevel']),
      movement: _jsonInt(jsonMap['movement'], fallback: 9),
      baseLife: _jsonInt(jsonMap['baseLife'], fallback: 16),
      lifePerVigor: _jsonInt(jsonMap['lifePerVigor'], fallback: 4),
      lifeManualBonus: _jsonInt(jsonMap['lifeManualBonus']),
      lifeCurrent: _jsonInt(jsonMap['lifeCurrent'], fallback: 16),
      lifeMaximum: _jsonInt(jsonMap['lifeMaximum'], fallback: 16),
      useManualLifeMaximum: jsonMap['useManualLifeMaximum'] == true,
      baseSanity: _jsonInt(jsonMap['baseSanity'], fallback: 12),
      sanityPerPresence: _jsonInt(jsonMap['sanityPerPresence'], fallback: 2),
      sanityManualBonus: _jsonInt(jsonMap['sanityManualBonus']),
      sanityCurrent: _jsonInt(jsonMap['sanityCurrent'], fallback: 12),
      sanityMaximum: _jsonInt(jsonMap['sanityMaximum'], fallback: 12),
      useManualSanityMaximum: jsonMap['useManualSanityMaximum'] == true,
      baseEffort: _jsonInt(jsonMap['baseEffort'], fallback: 2),
      effortPerPresence: _jsonInt(jsonMap['effortPerPresence'], fallback: 1),
      effortManualBonus: _jsonInt(jsonMap['effortManualBonus']),
      effortCurrent: _jsonInt(jsonMap['effortCurrent'], fallback: 2),
      effortMaximum: _jsonInt(jsonMap['effortMaximum'], fallback: 2),
      useManualEffortMaximum: jsonMap['useManualEffortMaximum'] == true,
      baseDefense: _jsonInt(jsonMap['baseDefense'], fallback: 10),
      defenseManualBonus: _jsonInt(jsonMap['defenseManualBonus']),
      defense: _jsonInt(jsonMap['defense'], fallback: 10),
      useManualDefense: jsonMap['useManualDefense'] == true,
      attributes: CharacterAttributes.fromJson(attributesJson),
      skills: _objectList(
        jsonMap['skills'],
      ).map(CharacterSkill.fromJson).toList(),
      weapons: _objectList(
        jsonMap['weapons'],
      ).map(CharacterWeapon.fromJson).toList(),
      items: _objectList(jsonMap['items']).map(CharacterItem.fromJson).toList(),
      rituals: _objectList(
        jsonMap['rituals'],
      ).map(CharacterRitual.fromJson).toList(),
      powers: _objectList(
        jsonMap['powers'],
      ).map(CharacterPower.fromJson).toList(),
      notes: _objectList(jsonMap['notes']).map(CharacterNote.fromJson).toList(),
      createdAt: currentDate,
      updatedAt: currentDate,
    );
  }

  final int? id;
  final String characterName;
  final String playerName;
  final String origin;
  final String characterClass;
  final String characterPath;
  final String rank;
  final int exposureLevel;
  final int movement;
  final int baseLife;
  final int lifePerVigor;
  final int lifeManualBonus;
  final int lifeCurrent;
  final int lifeMaximum;
  final bool useManualLifeMaximum;
  final int baseSanity;
  final int sanityPerPresence;
  final int sanityManualBonus;
  final int sanityCurrent;
  final int sanityMaximum;
  final bool useManualSanityMaximum;
  final int baseEffort;
  final int effortPerPresence;
  final int effortManualBonus;
  final int effortCurrent;
  final int effortMaximum;
  final bool useManualEffortMaximum;
  final int baseDefense;
  final int defenseManualBonus;
  final int defense;
  final bool useManualDefense;
  final CharacterAttributes attributes;
  final List<CharacterSkill> skills;
  final List<CharacterWeapon> weapons;
  final List<CharacterItem> items;
  final List<CharacterRitual> rituals;
  final List<CharacterPower> powers;
  final List<CharacterNote> notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, Object?> toDatabaseMap() {
    return <String, Object?>{
      'id': id,
      'character_name': characterName,
      'player_name': playerName,
      'origin': origin,
      'class_name': characterClass,
      'path_name': characterPath,
      'rank_name': rank,
      'exposure_level': exposureLevel,
      'movement': movement,
      'base_life': baseLife,
      'life_per_vigor': lifePerVigor,
      'life_manual_bonus': lifeManualBonus,
      'life_current': lifeCurrent,
      'life_maximum': lifeMaximum,
      'use_manual_life_maximum': _boolToInt(useManualLifeMaximum),
      'base_sanity': baseSanity,
      'sanity_per_presence': sanityPerPresence,
      'sanity_manual_bonus': sanityManualBonus,
      'sanity_current': sanityCurrent,
      'sanity_maximum': sanityMaximum,
      'use_manual_sanity_maximum': _boolToInt(useManualSanityMaximum),
      'base_effort': baseEffort,
      'effort_per_presence': effortPerPresence,
      'effort_manual_bonus': effortManualBonus,
      'effort_current': effortCurrent,
      'effort_maximum': effortMaximum,
      'use_manual_effort_maximum': _boolToInt(useManualEffortMaximum),
      'base_defense': baseDefense,
      'defense_manual_bonus': defenseManualBonus,
      'defense': defense,
      'use_manual_defense': _boolToInt(useManualDefense),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'characterName': characterName,
      'playerName': playerName,
      'origin': origin,
      'characterClass': characterClass,
      'characterPath': characterPath,
      'rank': rank,
      'exposureLevel': exposureLevel,
      'movement': movement,
      'baseLife': baseLife,
      'lifePerVigor': lifePerVigor,
      'lifeManualBonus': lifeManualBonus,
      'lifeCurrent': lifeCurrent,
      'lifeMaximum': lifeMaximum,
      'useManualLifeMaximum': useManualLifeMaximum,
      'baseSanity': baseSanity,
      'sanityPerPresence': sanityPerPresence,
      'sanityManualBonus': sanityManualBonus,
      'sanityCurrent': sanityCurrent,
      'sanityMaximum': sanityMaximum,
      'useManualSanityMaximum': useManualSanityMaximum,
      'baseEffort': baseEffort,
      'effortPerPresence': effortPerPresence,
      'effortManualBonus': effortManualBonus,
      'effortCurrent': effortCurrent,
      'effortMaximum': effortMaximum,
      'useManualEffortMaximum': useManualEffortMaximum,
      'baseDefense': baseDefense,
      'defenseManualBonus': defenseManualBonus,
      'defense': defense,
      'useManualDefense': useManualDefense,
      'attributes': attributes.toJson(),
      'skills': skills.map((CharacterSkill skill) => skill.toJson()).toList(),
      'weapons': weapons
          .map((CharacterWeapon weapon) => weapon.toJson())
          .toList(),
      'items': items
          .map((CharacterItem characterItem) => characterItem.toJson())
          .toList(),
      'rituals': rituals
          .map((CharacterRitual ritual) => ritual.toJson())
          .toList(),
      'powers': powers.map((CharacterPower power) => power.toJson()).toList(),
      'notes': notes.map((CharacterNote note) => note.toJson()).toList(),
    };
  }

  CharacterSheet copyWith({
    int? id,
    bool clearId = false,
    String? characterName,
    String? playerName,
    String? origin,
    String? characterClass,
    String? characterPath,
    String? rank,
    int? exposureLevel,
    int? movement,
    int? baseLife,
    int? lifePerVigor,
    int? lifeManualBonus,
    int? lifeCurrent,
    bool clearLifeCurrent = false,
    int? lifeMaximum,
    bool? useManualLifeMaximum,
    int? baseSanity,
    int? sanityPerPresence,
    int? sanityManualBonus,
    int? sanityCurrent,
    bool clearSanityCurrent = false,
    int? sanityMaximum,
    bool? useManualSanityMaximum,
    int? baseEffort,
    int? effortPerPresence,
    int? effortManualBonus,
    int? effortCurrent,
    bool clearEffortCurrent = false,
    int? effortMaximum,
    bool? useManualEffortMaximum,
    int? baseDefense,
    int? defenseManualBonus,
    int? defense,
    bool? useManualDefense,
    CharacterAttributes? attributes,
    List<CharacterSkill>? skills,
    List<CharacterWeapon>? weapons,
    List<CharacterItem>? items,
    List<CharacterRitual>? rituals,
    List<CharacterPower>? powers,
    List<CharacterNote>? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CharacterSheet(
      id: clearId ? null : id ?? this.id,
      characterName: characterName ?? this.characterName,
      playerName: playerName ?? this.playerName,
      origin: origin ?? this.origin,
      characterClass: characterClass ?? this.characterClass,
      characterPath: characterPath ?? this.characterPath,
      rank: rank ?? this.rank,
      exposureLevel: exposureLevel ?? this.exposureLevel,
      movement: movement ?? this.movement,
      baseLife: baseLife ?? this.baseLife,
      lifePerVigor: lifePerVigor ?? this.lifePerVigor,
      lifeManualBonus: lifeManualBonus ?? this.lifeManualBonus,
      lifeCurrent: clearLifeCurrent ? 0 : lifeCurrent ?? this.lifeCurrent,
      lifeMaximum: lifeMaximum ?? this.lifeMaximum,
      useManualLifeMaximum: useManualLifeMaximum ?? this.useManualLifeMaximum,
      baseSanity: baseSanity ?? this.baseSanity,
      sanityPerPresence: sanityPerPresence ?? this.sanityPerPresence,
      sanityManualBonus: sanityManualBonus ?? this.sanityManualBonus,
      sanityCurrent: clearSanityCurrent
          ? 0
          : sanityCurrent ?? this.sanityCurrent,
      sanityMaximum: sanityMaximum ?? this.sanityMaximum,
      useManualSanityMaximum:
          useManualSanityMaximum ?? this.useManualSanityMaximum,
      baseEffort: baseEffort ?? this.baseEffort,
      effortPerPresence: effortPerPresence ?? this.effortPerPresence,
      effortManualBonus: effortManualBonus ?? this.effortManualBonus,
      effortCurrent: clearEffortCurrent
          ? 0
          : effortCurrent ?? this.effortCurrent,
      effortMaximum: effortMaximum ?? this.effortMaximum,
      useManualEffortMaximum:
          useManualEffortMaximum ?? this.useManualEffortMaximum,
      baseDefense: baseDefense ?? this.baseDefense,
      defenseManualBonus: defenseManualBonus ?? this.defenseManualBonus,
      defense: defense ?? this.defense,
      useManualDefense: useManualDefense ?? this.useManualDefense,
      attributes: attributes ?? this.attributes,
      skills: skills ?? this.skills,
      weapons: weapons ?? this.weapons,
      items: items ?? this.items,
      rituals: rituals ?? this.rituals,
      powers: powers ?? this.powers,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class CharacterAttributes {
  const CharacterAttributes({
    this.id,
    this.characterId,
    required this.strength,
    required this.agility,
    required this.intellect,
    required this.presence,
    required this.vigor,
  });

  factory CharacterAttributes.empty() {
    return const CharacterAttributes(
      strength: 1,
      agility: 1,
      intellect: 1,
      presence: 1,
      vigor: 1,
    );
  }

  factory CharacterAttributes.fromDatabase(Map<String, Object?> databaseRow) {
    return CharacterAttributes(
      id: databaseRow['id'] as int?,
      characterId: databaseRow['character_id'] as int?,
      strength: databaseRow['strength'] as int? ?? 1,
      agility: databaseRow['agility'] as int? ?? 1,
      intellect: databaseRow['intellect'] as int? ?? 1,
      presence: databaseRow['presence'] as int? ?? 1,
      vigor: databaseRow['vigor'] as int? ?? 1,
    );
  }

  factory CharacterAttributes.fromJson(Map<String, Object?> jsonMap) {
    return CharacterAttributes(
      strength: _jsonInt(jsonMap['strength'], fallback: 1),
      agility: _jsonInt(jsonMap['agility'], fallback: 1),
      intellect: _jsonInt(jsonMap['intellect'], fallback: 1),
      presence: _jsonInt(jsonMap['presence'], fallback: 1),
      vigor: _jsonInt(jsonMap['vigor'], fallback: 1),
    );
  }

  final int? id;
  final int? characterId;
  final int strength;
  final int agility;
  final int intellect;
  final int presence;
  final int vigor;

  Map<String, Object?> toDatabaseMap(int ownerCharacterId) {
    return <String, Object?>{
      'id': id,
      'character_id': ownerCharacterId,
      'strength': strength,
      'agility': agility,
      'intellect': intellect,
      'presence': presence,
      'vigor': vigor,
    };
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'strength': strength,
      'agility': agility,
      'intellect': intellect,
      'presence': presence,
      'vigor': vigor,
    };
  }

  CharacterAttributes copyWith({
    int? id,
    int? characterId,
    int? strength,
    int? agility,
    int? intellect,
    int? presence,
    int? vigor,
  }) {
    return CharacterAttributes(
      id: id ?? this.id,
      characterId: characterId ?? this.characterId,
      strength: strength ?? this.strength,
      agility: agility ?? this.agility,
      intellect: intellect ?? this.intellect,
      presence: presence ?? this.presence,
      vigor: vigor ?? this.vigor,
    );
  }
}

class CharacterSkill {
  const CharacterSkill({
    this.id,
    this.characterId,
    required this.name,
    required this.training,
    required this.bonus,
    required this.notes,
  });

  factory CharacterSkill.empty() {
    return const CharacterSkill(name: '', training: 0, bonus: 0, notes: '');
  }

  factory CharacterSkill.fromDatabase(Map<String, Object?> databaseRow) {
    return CharacterSkill(
      id: databaseRow['id'] as int?,
      characterId: databaseRow['character_id'] as int?,
      name: databaseRow['name'] as String? ?? '',
      training: databaseRow['training'] as int? ?? 0,
      bonus: databaseRow['bonus'] as int? ?? 0,
      notes: databaseRow['notes'] as String? ?? '',
    );
  }

  factory CharacterSkill.fromJson(Map<String, Object?> jsonMap) {
    return CharacterSkill(
      name: jsonMap['name'] as String? ?? '',
      training: _jsonInt(jsonMap['training']),
      bonus: _jsonInt(jsonMap['bonus']),
      notes: jsonMap['notes'] as String? ?? '',
    );
  }

  static List<CharacterSkill> defaultSkills() {
    const List<String> skillNames = <String>[
      'Acrobacia',
      'Atletismo',
      'Atualidades',
      'Crime',
      'Diplomacia',
      'Enganação',
      'Fortitude',
      'Iniciativa',
      'Intimidação',
      'Investigação',
      'Luta',
      'Medicina',
      'Ocultismo',
      'Percepção',
      'Pontaria',
      'Reflexos',
      'Tecnologia',
      'Vontade',
    ];

    return skillNames
        .map(
          (String skillName) =>
              CharacterSkill(name: skillName, training: 0, bonus: 0, notes: ''),
        )
        .toList();
  }

  final int? id;
  final int? characterId;
  final String name;
  final int training;
  final int bonus;
  final String notes;

  int get total => training + bonus;

  Map<String, Object?> toDatabaseMap(int ownerCharacterId) {
    return <String, Object?>{
      'id': id,
      'character_id': ownerCharacterId,
      'name': name,
      'training': training,
      'bonus': bonus,
      'notes': notes,
    };
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'name': name,
      'training': training,
      'bonus': bonus,
      'notes': notes,
    };
  }

  CharacterSkill copyWith({
    int? id,
    int? characterId,
    String? name,
    int? training,
    int? bonus,
    String? notes,
  }) {
    return CharacterSkill(
      id: id ?? this.id,
      characterId: characterId ?? this.characterId,
      name: name ?? this.name,
      training: training ?? this.training,
      bonus: bonus ?? this.bonus,
      notes: notes ?? this.notes,
    );
  }
}

class CharacterWeapon {
  const CharacterWeapon({
    this.id,
    this.characterId,
    required this.name,
    required this.attackBonus,
    required this.damage,
    required this.critical,
    required this.range,
    required this.notes,
  });

  factory CharacterWeapon.empty() {
    return const CharacterWeapon(
      name: '',
      attackBonus: 0,
      damage: '',
      critical: '',
      range: '',
      notes: '',
    );
  }

  factory CharacterWeapon.fromDatabase(Map<String, Object?> databaseRow) {
    return CharacterWeapon(
      id: databaseRow['id'] as int?,
      characterId: databaseRow['character_id'] as int?,
      name: databaseRow['name'] as String? ?? '',
      attackBonus: databaseRow['attack_bonus'] as int? ?? 0,
      damage: databaseRow['damage'] as String? ?? '',
      critical: databaseRow['critical_text'] as String? ?? '',
      range: databaseRow['range_text'] as String? ?? '',
      notes: databaseRow['notes'] as String? ?? '',
    );
  }

  factory CharacterWeapon.fromJson(Map<String, Object?> jsonMap) {
    return CharacterWeapon(
      name: jsonMap['name'] as String? ?? '',
      attackBonus: _jsonInt(jsonMap['attackBonus']),
      damage: jsonMap['damage'] as String? ?? '',
      critical: jsonMap['critical'] as String? ?? '',
      range: jsonMap['range'] as String? ?? '',
      notes: jsonMap['notes'] as String? ?? '',
    );
  }

  final int? id;
  final int? characterId;
  final String name;
  final int attackBonus;
  final String damage;
  final String critical;
  final String range;
  final String notes;

  Map<String, Object?> toDatabaseMap(int ownerCharacterId) {
    return <String, Object?>{
      'id': id,
      'character_id': ownerCharacterId,
      'name': name,
      'attack_bonus': attackBonus,
      'damage': damage,
      'critical_text': critical,
      'range_text': range,
      'notes': notes,
    };
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'name': name,
      'attackBonus': attackBonus,
      'damage': damage,
      'critical': critical,
      'range': range,
      'notes': notes,
    };
  }

  CharacterWeapon copyWith({
    int? id,
    int? characterId,
    String? name,
    int? attackBonus,
    String? damage,
    String? critical,
    String? range,
    String? notes,
  }) {
    return CharacterWeapon(
      id: id ?? this.id,
      characterId: characterId ?? this.characterId,
      name: name ?? this.name,
      attackBonus: attackBonus ?? this.attackBonus,
      damage: damage ?? this.damage,
      critical: critical ?? this.critical,
      range: range ?? this.range,
      notes: notes ?? this.notes,
    );
  }
}

class CharacterItem {
  const CharacterItem({
    this.id,
    this.characterId,
    required this.name,
    required this.category,
    required this.quantity,
    required this.weight,
    required this.defenseBonus,
    required this.notes,
  });

  factory CharacterItem.empty({String category = 'Item'}) {
    return CharacterItem(
      name: '',
      category: category,
      quantity: 1,
      weight: 0,
      defenseBonus: 0,
      notes: '',
    );
  }

  factory CharacterItem.fromDatabase(Map<String, Object?> databaseRow) {
    return CharacterItem(
      id: databaseRow['id'] as int?,
      characterId: databaseRow['character_id'] as int?,
      name: databaseRow['name'] as String? ?? '',
      category: databaseRow['category'] as String? ?? 'Item',
      quantity: databaseRow['quantity'] as int? ?? 1,
      weight: databaseRow['weight'] as int? ?? 0,
      defenseBonus: databaseRow['defense_bonus'] as int? ?? 0,
      notes: databaseRow['notes'] as String? ?? '',
    );
  }

  factory CharacterItem.fromJson(Map<String, Object?> jsonMap) {
    return CharacterItem(
      name: jsonMap['name'] as String? ?? '',
      category: jsonMap['category'] as String? ?? 'Item',
      quantity: _jsonInt(jsonMap['quantity'], fallback: 1),
      weight: _jsonInt(jsonMap['weight']),
      defenseBonus: _jsonInt(jsonMap['defenseBonus']),
      notes: jsonMap['notes'] as String? ?? '',
    );
  }

  final int? id;
  final int? characterId;
  final String name;
  final String category;
  final int quantity;
  final int weight;
  final int defenseBonus;
  final String notes;

  bool get isProtection {
    return category.toLowerCase().replaceAll('\u00e7', 'c').contains('protec');
  }

  Map<String, Object?> toDatabaseMap(int ownerCharacterId) {
    return <String, Object?>{
      'id': id,
      'character_id': ownerCharacterId,
      'name': name,
      'category': category,
      'quantity': quantity,
      'weight': weight,
      'defense_bonus': defenseBonus,
      'notes': notes,
    };
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'name': name,
      'category': category,
      'quantity': quantity,
      'weight': weight,
      'defenseBonus': defenseBonus,
      'notes': notes,
    };
  }

  CharacterItem copyWith({
    int? id,
    int? characterId,
    String? name,
    String? category,
    int? quantity,
    int? weight,
    int? defenseBonus,
    String? notes,
  }) {
    return CharacterItem(
      id: id ?? this.id,
      characterId: characterId ?? this.characterId,
      name: name ?? this.name,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      weight: weight ?? this.weight,
      defenseBonus: defenseBonus ?? this.defenseBonus,
      notes: notes ?? this.notes,
    );
  }
}

class CharacterRitual {
  const CharacterRitual({
    this.id,
    this.characterId,
    required this.name,
    required this.circle,
    required this.cost,
    required this.description,
  });

  factory CharacterRitual.empty() {
    return const CharacterRitual(
      name: '',
      circle: '',
      cost: '',
      description: '',
    );
  }

  factory CharacterRitual.fromDatabase(Map<String, Object?> databaseRow) {
    return CharacterRitual(
      id: databaseRow['id'] as int?,
      characterId: databaseRow['character_id'] as int?,
      name: databaseRow['name'] as String? ?? '',
      circle: databaseRow['circle'] as String? ?? '',
      cost: databaseRow['cost'] as String? ?? '',
      description: databaseRow['description'] as String? ?? '',
    );
  }

  factory CharacterRitual.fromJson(Map<String, Object?> jsonMap) {
    return CharacterRitual(
      name: jsonMap['name'] as String? ?? '',
      circle: jsonMap['circle'] as String? ?? '',
      cost: jsonMap['cost'] as String? ?? '',
      description: jsonMap['description'] as String? ?? '',
    );
  }

  final int? id;
  final int? characterId;
  final String name;
  final String circle;
  final String cost;
  final String description;

  Map<String, Object?> toDatabaseMap(int ownerCharacterId) {
    return <String, Object?>{
      'id': id,
      'character_id': ownerCharacterId,
      'name': name,
      'circle': circle,
      'cost': cost,
      'description': description,
    };
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'name': name,
      'circle': circle,
      'cost': cost,
      'description': description,
    };
  }

  CharacterRitual copyWith({
    int? id,
    int? characterId,
    String? name,
    String? circle,
    String? cost,
    String? description,
  }) {
    return CharacterRitual(
      id: id ?? this.id,
      characterId: characterId ?? this.characterId,
      name: name ?? this.name,
      circle: circle ?? this.circle,
      cost: cost ?? this.cost,
      description: description ?? this.description,
    );
  }
}

class CharacterPower {
  const CharacterPower({
    this.id,
    this.characterId,
    required this.name,
    required this.category,
    required this.description,
  });

  factory CharacterPower.empty({String category = 'Poder'}) {
    return CharacterPower(name: '', category: category, description: '');
  }

  factory CharacterPower.fromDatabase(Map<String, Object?> databaseRow) {
    return CharacterPower(
      id: databaseRow['id'] as int?,
      characterId: databaseRow['character_id'] as int?,
      name: databaseRow['name'] as String? ?? '',
      category: databaseRow['category'] as String? ?? 'Poder',
      description: databaseRow['description'] as String? ?? '',
    );
  }

  factory CharacterPower.fromJson(Map<String, Object?> jsonMap) {
    return CharacterPower(
      name: jsonMap['name'] as String? ?? '',
      category: jsonMap['category'] as String? ?? 'Poder',
      description: jsonMap['description'] as String? ?? '',
    );
  }

  final int? id;
  final int? characterId;
  final String name;
  final String category;
  final String description;

  Map<String, Object?> toDatabaseMap(int ownerCharacterId) {
    return <String, Object?>{
      'id': id,
      'character_id': ownerCharacterId,
      'name': name,
      'category': category,
      'description': description,
    };
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'name': name,
      'category': category,
      'description': description,
    };
  }

  CharacterPower copyWith({
    int? id,
    int? characterId,
    String? name,
    String? category,
    String? description,
  }) {
    return CharacterPower(
      id: id ?? this.id,
      characterId: characterId ?? this.characterId,
      name: name ?? this.name,
      category: category ?? this.category,
      description: description ?? this.description,
    );
  }
}

class CharacterNote {
  const CharacterNote({
    this.id,
    this.characterId,
    required this.category,
    required this.title,
    required this.content,
  });

  factory CharacterNote.empty({
    String category = CharacterNoteCategory.general,
  }) {
    return CharacterNote(category: category, title: '', content: '');
  }

  factory CharacterNote.fromDatabase(Map<String, Object?> databaseRow) {
    return CharacterNote(
      id: databaseRow['id'] as int?,
      characterId: databaseRow['character_id'] as int?,
      category:
          databaseRow['category'] as String? ?? CharacterNoteCategory.general,
      title: databaseRow['title'] as String? ?? '',
      content: databaseRow['content'] as String? ?? '',
    );
  }

  factory CharacterNote.fromJson(Map<String, Object?> jsonMap) {
    return CharacterNote(
      category: jsonMap['category'] as String? ?? CharacterNoteCategory.general,
      title: jsonMap['title'] as String? ?? '',
      content: jsonMap['content'] as String? ?? '',
    );
  }

  final int? id;
  final int? characterId;
  final String category;
  final String title;
  final String content;

  Map<String, Object?> toDatabaseMap(int ownerCharacterId) {
    return <String, Object?>{
      'id': id,
      'character_id': ownerCharacterId,
      'category': category,
      'title': title,
      'content': content,
    };
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'category': category,
      'title': title,
      'content': content,
    };
  }

  CharacterNote copyWith({
    int? id,
    int? characterId,
    String? category,
    String? title,
    String? content,
  }) {
    return CharacterNote(
      id: id ?? this.id,
      characterId: characterId ?? this.characterId,
      category: category ?? this.category,
      title: title ?? this.title,
      content: content ?? this.content,
    );
  }
}

class CharacterNoteCategory {
  const CharacterNoteCategory._();

  static const String general = 'Anotações';
  static const String history = 'Histórico';
  static const String ability = 'Habilidade';
}

int _boolToInt(bool booleanValue) {
  return booleanValue ? 1 : 0;
}

bool _intToBool(Object? databaseValue) {
  return databaseValue == 1;
}

int _jsonInt(Object? jsonValue, {int fallback = 0}) {
  if (jsonValue is int) {
    return jsonValue;
  }

  if (jsonValue is num) {
    return jsonValue.toInt();
  }

  if (jsonValue is String) {
    return int.tryParse(jsonValue) ?? fallback;
  }

  return fallback;
}

Map<String, Object?> _objectMap(Object? rawJsonValue) {
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

List<Map<String, Object?>> _objectList(Object? rawJsonValue) {
  if (rawJsonValue is! List) {
    return <Map<String, Object?>>[];
  }

  return rawJsonValue
      .whereType<Map>()
      .map(
        (Map rawMap) => rawMap.map(
          (Object? rawKey, Object? rawValue) =>
              MapEntry(rawKey.toString(), rawValue),
        ),
      )
      .toList();
}
