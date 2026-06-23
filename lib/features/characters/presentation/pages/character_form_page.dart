import 'package:flutter/material.dart';

import '../../data/models/character_sheet.dart';
import '../../data/repositories/character_repository.dart';
import '../controllers/character_editor_controller.dart';
import '../widgets/attribute_selector.dart';
import '../widgets/save_status_indicator.dart';
import '../widgets/sheet_section_card.dart';
import '../widgets/standard_number_field.dart';
import '../widgets/standard_text_field.dart';

class CharacterFormPage extends StatefulWidget {
  const CharacterFormPage({
    required this.repository,
    this.characterId,
    super.key,
  });

  final CharacterRepository repository;
  final int? characterId;

  @override
  State<CharacterFormPage> createState() => _CharacterFormPageState();
}

class _CharacterFormPageState extends State<CharacterFormPage> {
  late final CharacterEditorController controller;

  @override
  void initState() {
    super.initState();
    controller = CharacterEditorController(repository: widget.repository);
    controller.load(characterId: widget.characterId);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, Widget? child) {
        final CharacterSheet? characterSheet = controller.characterSheet;

        return DefaultTabController(
          length: 7,
          child: Scaffold(
            appBar: AppBar(
              title: Text(
                widget.characterId == null ? 'Nova ficha' : 'Editar ficha',
              ),
              actions: <Widget>[
                Center(
                  child: SaveStatusIndicator(status: controller.saveStatus),
                ),
                IconButton(
                  tooltip: 'Salvar agora',
                  onPressed: characterSheet == null ? null : controller.saveNow,
                  icon: const Icon(Icons.save_outlined),
                ),
              ],
              bottom: const TabBar(
                isScrollable: true,
                tabs: <Widget>[
                  Tab(text: 'Identificacao'),
                  Tab(text: 'Atributos'),
                  Tab(text: 'Combate'),
                  Tab(text: 'Pericias'),
                  Tab(text: 'Inventario'),
                  Tab(text: 'Extras'),
                  Tab(text: 'Notas'),
                ],
              ),
            ),
            body: _buildBody(characterSheet),
          ),
        );
      },
    );
  }

  Widget _buildBody(CharacterSheet? characterSheet) {
    if (controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (characterSheet == null) {
      return Center(
        child: Text(controller.errorMessage ?? 'Ficha nao encontrada.'),
      );
    }

    return TabBarView(
      children: <Widget>[
        _TabScroller(children: _identificationFields(characterSheet)),
        _TabScroller(children: _attributeFields(characterSheet)),
        _TabScroller(children: _combatFields(characterSheet)),
        _TabScroller(children: _skillFields(characterSheet)),
        _TabScroller(children: _inventoryFields(characterSheet)),
        _TabScroller(children: _extraFields(characterSheet)),
        _TabScroller(children: _noteFields(characterSheet)),
      ],
    );
  }

  List<Widget> _identificationFields(CharacterSheet characterSheet) {
    return <Widget>[
      SheetSectionCard(
        title: 'Identificacao',
        children: <Widget>[
          StandardTextField(
            label: 'Nome do personagem',
            initialText: characterSheet.characterName,
            onChanged: (String text) => controller.updateCharacter(
              (CharacterSheet currentSheet) =>
                  currentSheet.copyWith(characterName: text),
            ),
          ),
          StandardTextField(
            label: 'Nome do jogador',
            initialText: characterSheet.playerName,
            onChanged: (String text) => controller.updateCharacter(
              (CharacterSheet currentSheet) =>
                  currentSheet.copyWith(playerName: text),
            ),
          ),
          StandardTextField(
            label: 'Origem',
            initialText: characterSheet.origin,
            onChanged: (String text) => controller.updateCharacter(
              (CharacterSheet currentSheet) =>
                  currentSheet.copyWith(origin: text),
            ),
          ),
          StandardTextField(
            label: 'Classe',
            initialText: characterSheet.characterClass,
            onChanged: (String text) => controller.updateCharacter(
              (CharacterSheet currentSheet) =>
                  currentSheet.copyWith(characterClass: text),
            ),
          ),
          StandardTextField(
            label: 'Trilha',
            initialText: characterSheet.characterPath,
            onChanged: (String text) => controller.updateCharacter(
              (CharacterSheet currentSheet) =>
                  currentSheet.copyWith(characterPath: text),
            ),
          ),
          StandardTextField(
            label: 'Patente',
            initialText: characterSheet.rank,
            onChanged: (String text) => controller.updateCharacter(
              (CharacterSheet currentSheet) =>
                  currentSheet.copyWith(rank: text),
            ),
          ),
          StandardNumberField(
            label: 'Nivel de exposicao paranormal',
            initialNumber: characterSheet.exposureLevel,
            allowNegative: false,
            onChanged: (int number) => controller.updateCharacter(
              (CharacterSheet currentSheet) =>
                  currentSheet.copyWith(exposureLevel: number),
            ),
          ),
          StandardNumberField(
            label: 'Deslocamento',
            initialNumber: characterSheet.movement,
            allowNegative: false,
            onChanged: (int number) => controller.updateCharacter(
              (CharacterSheet currentSheet) =>
                  currentSheet.copyWith(movement: number),
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _attributeFields(CharacterSheet characterSheet) {
    return <Widget>[
      SheetSectionCard(
        title: 'Atributos',
        children: <Widget>[
          AttributeSelector(
            label: 'Forca',
            currentValue: characterSheet.attributes.strength,
            onChanged: (int number) => _updateAttributes(
              characterSheet.attributes.copyWith(strength: number),
            ),
          ),
          AttributeSelector(
            label: 'Agilidade',
            currentValue: characterSheet.attributes.agility,
            onChanged: (int number) => _updateAttributes(
              characterSheet.attributes.copyWith(agility: number),
            ),
          ),
          AttributeSelector(
            label: 'Intelecto',
            currentValue: characterSheet.attributes.intellect,
            onChanged: (int number) => _updateAttributes(
              characterSheet.attributes.copyWith(intellect: number),
            ),
          ),
          AttributeSelector(
            label: 'Presenca',
            currentValue: characterSheet.attributes.presence,
            onChanged: (int number) => _updateAttributes(
              characterSheet.attributes.copyWith(presence: number),
            ),
          ),
          AttributeSelector(
            label: 'Vigor',
            currentValue: characterSheet.attributes.vigor,
            onChanged: (int number) => _updateAttributes(
              characterSheet.attributes.copyWith(vigor: number),
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _combatFields(CharacterSheet characterSheet) {
    return <Widget>[
      SheetSectionCard(
        title: 'Vida',
        children: <Widget>[
          StandardNumberField(
            label: 'Vida atual',
            initialNumber: characterSheet.lifeCurrent,
            allowNegative: false,
            onChanged: (int number) => controller.updateCharacter(
              (CharacterSheet currentSheet) =>
                  currentSheet.copyWith(lifeCurrent: number),
            ),
          ),
          StandardNumberField(
            label: 'Vida maxima',
            initialNumber: characterSheet.lifeMaximum,
            allowNegative: false,
            onChanged: (int number) => controller.updateCharacter(
              (CharacterSheet currentSheet) => currentSheet.copyWith(
                lifeMaximum: number,
                useManualLifeMaximum: true,
              ),
            ),
          ),
          _ManualSwitch(
            title: 'Editar vida maxima manualmente',
            currentValue: characterSheet.useManualLifeMaximum,
            onChanged: (bool booleanValue) => controller.updateCharacter(
              (CharacterSheet currentSheet) =>
                  currentSheet.copyWith(useManualLifeMaximum: booleanValue),
            ),
          ),
          StandardNumberField(
            label: 'Vida base',
            initialNumber: characterSheet.baseLife,
            onChanged: (int number) => controller.updateCharacter(
              (CharacterSheet currentSheet) =>
                  currentSheet.copyWith(baseLife: number),
            ),
          ),
          StandardNumberField(
            label: 'Vida por vigor',
            initialNumber: characterSheet.lifePerVigor,
            onChanged: (int number) => controller.updateCharacter(
              (CharacterSheet currentSheet) =>
                  currentSheet.copyWith(lifePerVigor: number),
            ),
          ),
          StandardNumberField(
            label: 'Bonus manual de vida',
            initialNumber: characterSheet.lifeManualBonus,
            onChanged: (int number) => controller.updateCharacter(
              (CharacterSheet currentSheet) =>
                  currentSheet.copyWith(lifeManualBonus: number),
            ),
          ),
        ],
      ),
      SheetSectionCard(
        title: 'Sanidade',
        children: <Widget>[
          StandardNumberField(
            label: 'Sanidade atual',
            initialNumber: characterSheet.sanityCurrent,
            allowNegative: false,
            onChanged: (int number) => controller.updateCharacter(
              (CharacterSheet currentSheet) =>
                  currentSheet.copyWith(sanityCurrent: number),
            ),
          ),
          StandardNumberField(
            label: 'Sanidade maxima',
            initialNumber: characterSheet.sanityMaximum,
            allowNegative: false,
            onChanged: (int number) => controller.updateCharacter(
              (CharacterSheet currentSheet) => currentSheet.copyWith(
                sanityMaximum: number,
                useManualSanityMaximum: true,
              ),
            ),
          ),
          _ManualSwitch(
            title: 'Editar sanidade maxima manualmente',
            currentValue: characterSheet.useManualSanityMaximum,
            onChanged: (bool booleanValue) => controller.updateCharacter(
              (CharacterSheet currentSheet) =>
                  currentSheet.copyWith(useManualSanityMaximum: booleanValue),
            ),
          ),
          StandardNumberField(
            label: 'Sanidade base',
            initialNumber: characterSheet.baseSanity,
            onChanged: (int number) => controller.updateCharacter(
              (CharacterSheet currentSheet) =>
                  currentSheet.copyWith(baseSanity: number),
            ),
          ),
          StandardNumberField(
            label: 'Sanidade por presenca',
            initialNumber: characterSheet.sanityPerPresence,
            onChanged: (int number) => controller.updateCharacter(
              (CharacterSheet currentSheet) =>
                  currentSheet.copyWith(sanityPerPresence: number),
            ),
          ),
          StandardNumberField(
            label: 'Bonus manual de sanidade',
            initialNumber: characterSheet.sanityManualBonus,
            onChanged: (int number) => controller.updateCharacter(
              (CharacterSheet currentSheet) =>
                  currentSheet.copyWith(sanityManualBonus: number),
            ),
          ),
        ],
      ),
      SheetSectionCard(
        title: 'Esforco e defesa',
        children: <Widget>[
          StandardNumberField(
            label: 'Esforco atual',
            initialNumber: characterSheet.effortCurrent,
            allowNegative: false,
            onChanged: (int number) => controller.updateCharacter(
              (CharacterSheet currentSheet) =>
                  currentSheet.copyWith(effortCurrent: number),
            ),
          ),
          StandardNumberField(
            label: 'Esforco maximo',
            initialNumber: characterSheet.effortMaximum,
            allowNegative: false,
            onChanged: (int number) => controller.updateCharacter(
              (CharacterSheet currentSheet) => currentSheet.copyWith(
                effortMaximum: number,
                useManualEffortMaximum: true,
              ),
            ),
          ),
          _ManualSwitch(
            title: 'Editar esforco maximo manualmente',
            currentValue: characterSheet.useManualEffortMaximum,
            onChanged: (bool booleanValue) => controller.updateCharacter(
              (CharacterSheet currentSheet) =>
                  currentSheet.copyWith(useManualEffortMaximum: booleanValue),
            ),
          ),
          StandardNumberField(
            label: 'Esforco base',
            initialNumber: characterSheet.baseEffort,
            onChanged: (int number) => controller.updateCharacter(
              (CharacterSheet currentSheet) =>
                  currentSheet.copyWith(baseEffort: number),
            ),
          ),
          StandardNumberField(
            label: 'Esforco por presenca',
            initialNumber: characterSheet.effortPerPresence,
            onChanged: (int number) => controller.updateCharacter(
              (CharacterSheet currentSheet) =>
                  currentSheet.copyWith(effortPerPresence: number),
            ),
          ),
          StandardNumberField(
            label: 'Bonus manual de esforco',
            initialNumber: characterSheet.effortManualBonus,
            onChanged: (int number) => controller.updateCharacter(
              (CharacterSheet currentSheet) =>
                  currentSheet.copyWith(effortManualBonus: number),
            ),
          ),
          const Divider(),
          StandardNumberField(
            label: 'Defesa',
            initialNumber: characterSheet.defense,
            onChanged: (int number) => controller.updateCharacter(
              (CharacterSheet currentSheet) => currentSheet.copyWith(
                defense: number,
                useManualDefense: true,
              ),
            ),
          ),
          _ManualSwitch(
            title: 'Editar defesa manualmente',
            currentValue: characterSheet.useManualDefense,
            onChanged: (bool booleanValue) => controller.updateCharacter(
              (CharacterSheet currentSheet) =>
                  currentSheet.copyWith(useManualDefense: booleanValue),
            ),
          ),
          StandardNumberField(
            label: 'Defesa base',
            initialNumber: characterSheet.baseDefense,
            onChanged: (int number) => controller.updateCharacter(
              (CharacterSheet currentSheet) =>
                  currentSheet.copyWith(baseDefense: number),
            ),
          ),
          StandardNumberField(
            label: 'Bonus manual de defesa',
            initialNumber: characterSheet.defenseManualBonus,
            onChanged: (int number) => controller.updateCharacter(
              (CharacterSheet currentSheet) =>
                  currentSheet.copyWith(defenseManualBonus: number),
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _skillFields(CharacterSheet characterSheet) {
    return <Widget>[
      SheetSectionCard(
        title: 'Pericias',
        trailing: IconButton(
          tooltip: 'Adicionar pericia',
          onPressed: () => _updateSkills(<CharacterSkill>[
            ...characterSheet.skills,
            CharacterSkill.empty(),
          ]),
          icon: const Icon(Icons.add),
        ),
        children: characterSheet.skills
            .asMap()
            .entries
            .map(
              (MapEntry<int, CharacterSkill> skillEntry) => _SkillEditor(
                skill: skillEntry.value,
                onRemove: () => _removeSkill(characterSheet, skillEntry.key),
                onChanged: (CharacterSkill skill) =>
                    _replaceSkill(characterSheet, skillEntry.key, skill),
              ),
            )
            .toList(),
      ),
    ];
  }

  List<Widget> _inventoryFields(CharacterSheet characterSheet) {
    return <Widget>[
      SheetSectionCard(
        title: 'Armas',
        trailing: IconButton(
          tooltip: 'Adicionar arma',
          onPressed: () => _updateWeapons(<CharacterWeapon>[
            ...characterSheet.weapons,
            CharacterWeapon.empty(),
          ]),
          icon: const Icon(Icons.add),
        ),
        children: characterSheet.weapons
            .asMap()
            .entries
            .map(
              (MapEntry<int, CharacterWeapon> weaponEntry) => _WeaponEditor(
                weapon: weaponEntry.value,
                onRemove: () => _removeWeapon(characterSheet, weaponEntry.key),
                onChanged: (CharacterWeapon weapon) =>
                    _replaceWeapon(characterSheet, weaponEntry.key, weapon),
              ),
            )
            .toList(),
      ),
      SheetSectionCard(
        title: 'Itens e protecoes',
        trailing: IconButton(
          tooltip: 'Adicionar item',
          onPressed: () => _updateItems(<CharacterItem>[
            ...characterSheet.items,
            CharacterItem.empty(),
          ]),
          icon: const Icon(Icons.add),
        ),
        children: characterSheet.items
            .asMap()
            .entries
            .map(
              (MapEntry<int, CharacterItem> itemEntry) => _ItemEditor(
                characterItem: itemEntry.value,
                onRemove: () => _removeItem(characterSheet, itemEntry.key),
                onChanged: (CharacterItem characterItem) =>
                    _replaceItem(characterSheet, itemEntry.key, characterItem),
              ),
            )
            .toList(),
      ),
    ];
  }

  List<Widget> _extraFields(CharacterSheet characterSheet) {
    return <Widget>[
      SheetSectionCard(
        title: 'Rituais',
        trailing: IconButton(
          tooltip: 'Adicionar ritual',
          onPressed: () => _updateRituals(<CharacterRitual>[
            ...characterSheet.rituals,
            CharacterRitual.empty(),
          ]),
          icon: const Icon(Icons.add),
        ),
        children: characterSheet.rituals
            .asMap()
            .entries
            .map(
              (MapEntry<int, CharacterRitual> ritualEntry) => _RitualEditor(
                ritual: ritualEntry.value,
                onRemove: () => _removeRitual(characterSheet, ritualEntry.key),
                onChanged: (CharacterRitual ritual) =>
                    _replaceRitual(characterSheet, ritualEntry.key, ritual),
              ),
            )
            .toList(),
      ),
      SheetSectionCard(
        title: 'Poderes e habilidades',
        trailing: PopupMenuButton<String>(
          tooltip: 'Adicionar',
          onSelected: (String category) => _updatePowers(<CharacterPower>[
            ...characterSheet.powers,
            CharacterPower.empty(category: category),
          ]),
          itemBuilder: (BuildContext context) => const <PopupMenuEntry<String>>[
            PopupMenuItem<String>(value: 'Poder', child: Text('Poder')),
            PopupMenuItem<String>(
              value: 'Habilidade',
              child: Text('Habilidade'),
            ),
          ],
          icon: const Icon(Icons.add),
        ),
        children: characterSheet.powers
            .asMap()
            .entries
            .map(
              (MapEntry<int, CharacterPower> powerEntry) => _PowerEditor(
                power: powerEntry.value,
                onRemove: () => _removePower(characterSheet, powerEntry.key),
                onChanged: (CharacterPower power) =>
                    _replacePower(characterSheet, powerEntry.key, power),
              ),
            )
            .toList(),
      ),
    ];
  }

  List<Widget> _noteFields(CharacterSheet characterSheet) {
    return <Widget>[
      SheetSectionCard(
        title: 'Anotacoes e historico',
        trailing: PopupMenuButton<String>(
          tooltip: 'Adicionar nota',
          onSelected: (String category) => _updateNotes(<CharacterNote>[
            ...characterSheet.notes,
            CharacterNote.empty(category: category),
          ]),
          itemBuilder: (BuildContext context) => const <PopupMenuEntry<String>>[
            PopupMenuItem<String>(
              value: CharacterNoteCategory.general,
              child: Text('Anotacao'),
            ),
            PopupMenuItem<String>(
              value: CharacterNoteCategory.history,
              child: Text('Historico'),
            ),
            PopupMenuItem<String>(
              value: CharacterNoteCategory.ability,
              child: Text('Habilidade'),
            ),
          ],
          icon: const Icon(Icons.add),
        ),
        children: characterSheet.notes
            .asMap()
            .entries
            .map(
              (MapEntry<int, CharacterNote> noteEntry) => _NoteEditor(
                note: noteEntry.value,
                onRemove: () => _removeNote(characterSheet, noteEntry.key),
                onChanged: (CharacterNote note) =>
                    _replaceNote(characterSheet, noteEntry.key, note),
              ),
            )
            .toList(),
      ),
    ];
  }

  void _updateAttributes(CharacterAttributes attributes) {
    controller.updateCharacter(
      (CharacterSheet currentSheet) =>
          currentSheet.copyWith(attributes: attributes),
    );
  }

  void _updateSkills(List<CharacterSkill> skills) {
    controller.updateCharacter(
      (CharacterSheet currentSheet) => currentSheet.copyWith(skills: skills),
    );
  }

  void _replaceSkill(
    CharacterSheet characterSheet,
    int skillIndex,
    CharacterSkill skill,
  ) {
    final List<CharacterSkill> skills = <CharacterSkill>[
      ...characterSheet.skills,
    ];
    skills[skillIndex] = skill;
    _updateSkills(skills);
  }

  void _removeSkill(CharacterSheet characterSheet, int skillIndex) {
    final List<CharacterSkill> skills = <CharacterSkill>[
      ...characterSheet.skills,
    ]..removeAt(skillIndex);
    _updateSkills(skills);
  }

  void _updateWeapons(List<CharacterWeapon> weapons) {
    controller.updateCharacter(
      (CharacterSheet currentSheet) => currentSheet.copyWith(weapons: weapons),
    );
  }

  void _replaceWeapon(
    CharacterSheet characterSheet,
    int weaponIndex,
    CharacterWeapon weapon,
  ) {
    final List<CharacterWeapon> weapons = <CharacterWeapon>[
      ...characterSheet.weapons,
    ];
    weapons[weaponIndex] = weapon;
    _updateWeapons(weapons);
  }

  void _removeWeapon(CharacterSheet characterSheet, int weaponIndex) {
    final List<CharacterWeapon> weapons = <CharacterWeapon>[
      ...characterSheet.weapons,
    ]..removeAt(weaponIndex);
    _updateWeapons(weapons);
  }

  void _updateItems(List<CharacterItem> characterItems) {
    controller.updateCharacter(
      (CharacterSheet currentSheet) =>
          currentSheet.copyWith(items: characterItems),
    );
  }

  void _replaceItem(
    CharacterSheet characterSheet,
    int itemIndex,
    CharacterItem characterItem,
  ) {
    final List<CharacterItem> characterItems = <CharacterItem>[
      ...characterSheet.items,
    ];
    characterItems[itemIndex] = characterItem;
    _updateItems(characterItems);
  }

  void _removeItem(CharacterSheet characterSheet, int itemIndex) {
    final List<CharacterItem> characterItems = <CharacterItem>[
      ...characterSheet.items,
    ]..removeAt(itemIndex);
    _updateItems(characterItems);
  }

  void _updateRituals(List<CharacterRitual> rituals) {
    controller.updateCharacter(
      (CharacterSheet currentSheet) => currentSheet.copyWith(rituals: rituals),
    );
  }

  void _replaceRitual(
    CharacterSheet characterSheet,
    int ritualIndex,
    CharacterRitual ritual,
  ) {
    final List<CharacterRitual> rituals = <CharacterRitual>[
      ...characterSheet.rituals,
    ];
    rituals[ritualIndex] = ritual;
    _updateRituals(rituals);
  }

  void _removeRitual(CharacterSheet characterSheet, int ritualIndex) {
    final List<CharacterRitual> rituals = <CharacterRitual>[
      ...characterSheet.rituals,
    ]..removeAt(ritualIndex);
    _updateRituals(rituals);
  }

  void _updatePowers(List<CharacterPower> powers) {
    controller.updateCharacter(
      (CharacterSheet currentSheet) => currentSheet.copyWith(powers: powers),
    );
  }

  void _replacePower(
    CharacterSheet characterSheet,
    int powerIndex,
    CharacterPower power,
  ) {
    final List<CharacterPower> powers = <CharacterPower>[
      ...characterSheet.powers,
    ];
    powers[powerIndex] = power;
    _updatePowers(powers);
  }

  void _removePower(CharacterSheet characterSheet, int powerIndex) {
    final List<CharacterPower> powers = <CharacterPower>[
      ...characterSheet.powers,
    ]..removeAt(powerIndex);
    _updatePowers(powers);
  }

  void _updateNotes(List<CharacterNote> notes) {
    controller.updateCharacter(
      (CharacterSheet currentSheet) => currentSheet.copyWith(notes: notes),
    );
  }

  void _replaceNote(
    CharacterSheet characterSheet,
    int noteIndex,
    CharacterNote note,
  ) {
    final List<CharacterNote> notes = <CharacterNote>[...characterSheet.notes];
    notes[noteIndex] = note;
    _updateNotes(notes);
  }

  void _removeNote(CharacterSheet characterSheet, int noteIndex) {
    final List<CharacterNote> notes = <CharacterNote>[...characterSheet.notes]
      ..removeAt(noteIndex);
    _updateNotes(notes);
  }
}

class _TabScroller extends StatelessWidget {
  const _TabScroller({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(12), children: children);
  }
}

class _ManualSwitch extends StatelessWidget {
  const _ManualSwitch({
    required this.title,
    required this.currentValue,
    required this.onChanged,
  });

  final String title;
  final bool currentValue;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      value: currentValue,
      onChanged: onChanged,
    );
  }
}

class _SkillEditor extends StatelessWidget {
  const _SkillEditor({
    required this.skill,
    required this.onChanged,
    required this.onRemove,
  });

  final CharacterSkill skill;
  final ValueChanged<CharacterSkill> onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return _EditorShell(
      title: skill.name.isEmpty ? 'Pericia sem nome' : skill.name,
      onRemove: onRemove,
      children: <Widget>[
        StandardTextField(
          label: 'Nome',
          initialText: skill.name,
          onChanged: (String text) => onChanged(skill.copyWith(name: text)),
        ),
        StandardNumberField(
          label: 'Treinamento',
          initialNumber: skill.training,
          onChanged: (int number) =>
              onChanged(skill.copyWith(training: number)),
        ),
        StandardNumberField(
          label: 'Bonus',
          initialNumber: skill.bonus,
          onChanged: (int number) => onChanged(skill.copyWith(bonus: number)),
        ),
        StandardTextField(
          label: 'Notas',
          initialText: skill.notes,
          maxLines: 2,
          onChanged: (String text) => onChanged(skill.copyWith(notes: text)),
        ),
      ],
    );
  }
}

class _WeaponEditor extends StatelessWidget {
  const _WeaponEditor({
    required this.weapon,
    required this.onChanged,
    required this.onRemove,
  });

  final CharacterWeapon weapon;
  final ValueChanged<CharacterWeapon> onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return _EditorShell(
      title: weapon.name.isEmpty ? 'Arma sem nome' : weapon.name,
      onRemove: onRemove,
      children: <Widget>[
        StandardTextField(
          label: 'Nome',
          initialText: weapon.name,
          onChanged: (String text) => onChanged(weapon.copyWith(name: text)),
        ),
        StandardNumberField(
          label: 'Bonus de ataque',
          initialNumber: weapon.attackBonus,
          onChanged: (int number) =>
              onChanged(weapon.copyWith(attackBonus: number)),
        ),
        StandardTextField(
          label: 'Dano',
          initialText: weapon.damage,
          onChanged: (String text) => onChanged(weapon.copyWith(damage: text)),
        ),
        StandardTextField(
          label: 'Critico',
          initialText: weapon.critical,
          onChanged: (String text) =>
              onChanged(weapon.copyWith(critical: text)),
        ),
        StandardTextField(
          label: 'Alcance',
          initialText: weapon.range,
          onChanged: (String text) => onChanged(weapon.copyWith(range: text)),
        ),
        StandardTextField(
          label: 'Notas',
          initialText: weapon.notes,
          maxLines: 2,
          onChanged: (String text) => onChanged(weapon.copyWith(notes: text)),
        ),
      ],
    );
  }
}

class _ItemEditor extends StatelessWidget {
  const _ItemEditor({
    required this.characterItem,
    required this.onChanged,
    required this.onRemove,
  });

  final CharacterItem characterItem;
  final ValueChanged<CharacterItem> onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return _EditorShell(
      title: characterItem.name.isEmpty ? 'Item sem nome' : characterItem.name,
      onRemove: onRemove,
      children: <Widget>[
        StandardTextField(
          label: 'Nome',
          initialText: characterItem.name,
          onChanged: (String text) =>
              onChanged(characterItem.copyWith(name: text)),
        ),
        StandardTextField(
          label: 'Categoria',
          initialText: characterItem.category,
          onChanged: (String text) =>
              onChanged(characterItem.copyWith(category: text)),
        ),
        StandardNumberField(
          label: 'Quantidade',
          initialNumber: characterItem.quantity,
          allowNegative: false,
          onChanged: (int number) =>
              onChanged(characterItem.copyWith(quantity: number)),
        ),
        StandardNumberField(
          label: 'Carga',
          initialNumber: characterItem.weight,
          allowNegative: false,
          onChanged: (int number) =>
              onChanged(characterItem.copyWith(weight: number)),
        ),
        StandardNumberField(
          label: 'Bonus de defesa',
          initialNumber: characterItem.defenseBonus,
          onChanged: (int number) =>
              onChanged(characterItem.copyWith(defenseBonus: number)),
        ),
        StandardTextField(
          label: 'Notas',
          initialText: characterItem.notes,
          maxLines: 2,
          onChanged: (String text) =>
              onChanged(characterItem.copyWith(notes: text)),
        ),
      ],
    );
  }
}

class _RitualEditor extends StatelessWidget {
  const _RitualEditor({
    required this.ritual,
    required this.onChanged,
    required this.onRemove,
  });

  final CharacterRitual ritual;
  final ValueChanged<CharacterRitual> onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return _EditorShell(
      title: ritual.name.isEmpty ? 'Ritual sem nome' : ritual.name,
      onRemove: onRemove,
      children: <Widget>[
        StandardTextField(
          label: 'Nome',
          initialText: ritual.name,
          onChanged: (String text) => onChanged(ritual.copyWith(name: text)),
        ),
        StandardTextField(
          label: 'Circulo',
          initialText: ritual.circle,
          onChanged: (String text) => onChanged(ritual.copyWith(circle: text)),
        ),
        StandardTextField(
          label: 'Custo',
          initialText: ritual.cost,
          onChanged: (String text) => onChanged(ritual.copyWith(cost: text)),
        ),
        StandardTextField(
          label: 'Descricao',
          initialText: ritual.description,
          maxLines: 4,
          onChanged: (String text) =>
              onChanged(ritual.copyWith(description: text)),
        ),
      ],
    );
  }
}

class _PowerEditor extends StatelessWidget {
  const _PowerEditor({
    required this.power,
    required this.onChanged,
    required this.onRemove,
  });

  final CharacterPower power;
  final ValueChanged<CharacterPower> onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return _EditorShell(
      title: power.name.isEmpty ? power.category : power.name,
      onRemove: onRemove,
      children: <Widget>[
        StandardTextField(
          label: 'Nome',
          initialText: power.name,
          onChanged: (String text) => onChanged(power.copyWith(name: text)),
        ),
        StandardTextField(
          label: 'Categoria',
          initialText: power.category,
          onChanged: (String text) => onChanged(power.copyWith(category: text)),
        ),
        StandardTextField(
          label: 'Descricao',
          initialText: power.description,
          maxLines: 4,
          onChanged: (String text) =>
              onChanged(power.copyWith(description: text)),
        ),
      ],
    );
  }
}

class _NoteEditor extends StatelessWidget {
  const _NoteEditor({
    required this.note,
    required this.onChanged,
    required this.onRemove,
  });

  final CharacterNote note;
  final ValueChanged<CharacterNote> onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return _EditorShell(
      title: note.title.isEmpty ? note.category : note.title,
      onRemove: onRemove,
      children: <Widget>[
        StandardTextField(
          label: 'Titulo',
          initialText: note.title,
          onChanged: (String text) => onChanged(note.copyWith(title: text)),
        ),
        StandardTextField(
          label: 'Categoria',
          initialText: note.category,
          onChanged: (String text) => onChanged(note.copyWith(category: text)),
        ),
        StandardTextField(
          label: 'Conteudo',
          initialText: note.content,
          maxLines: 5,
          onChanged: (String text) => onChanged(note.copyWith(content: text)),
        ),
      ],
    );
  }
}

class _EditorShell extends StatelessWidget {
  const _EditorShell({
    required this.title,
    required this.children,
    required this.onRemove,
  });

  final String title;
  final List<Widget> children;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        title: Text(title),
        trailing: IconButton(
          tooltip: 'Remover',
          onPressed: onRemove,
          icon: const Icon(Icons.delete_outline),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        children: children,
      ),
    );
  }
}
