import 'package:flutter/material.dart';

import '../../data/models/character_sheet.dart';
import '../../data/repositories/character_repository.dart';
import 'character_edit_page.dart';
import 'character_import_export_page.dart';

class CharacterDetailPage extends StatefulWidget {
  const CharacterDetailPage({
    required this.repository,
    required this.characterId,
    super.key,
  });

  final CharacterRepository repository;
  final int characterId;

  @override
  State<CharacterDetailPage> createState() => _CharacterDetailPageState();
}

class _CharacterDetailPageState extends State<CharacterDetailPage> {
  CharacterSheet? characterSheet;
  bool isLoading = true;
  String? errorMessage;
  Future<void> resourceSaveQueue = Future<void>.value();
  int resourceSaveVersion = 0;

  @override
  void initState() {
    super.initState();
    _loadCharacter();
  }

  Future<void> _loadCharacter() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final CharacterSheet? loadedCharacter = await widget.repository
          .getCharacter(widget.characterId);

      if (!mounted) {
        return;
      }

      setState(() {
        characterSheet = loadedCharacter;
      });
    } catch (exception) {
      if (!mounted) {
        return;
      }

      setState(() {
        errorMessage = 'Não foi possível carregar a ficha.';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _openEditor() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => CharacterEditPage(
          repository: widget.repository,
          characterId: widget.characterId,
        ),
      ),
    );
    await _loadCharacter();
  }

  void _openExport() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => CharacterImportExportPage(
          repository: widget.repository,
          characterId: widget.characterId,
        ),
      ),
    );
  }

  Future<void> _deleteCharacter(CharacterSheet characterSheet) async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Excluir ficha'),
        content: Text('Excluir "${characterSheet.characterName}"?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) {
      return;
    }

    await widget.repository.deleteCharacter(widget.characterId);

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _duplicateCharacter() async {
    final CharacterSheet duplicatedCharacter = await widget.repository
        .duplicateCharacter(widget.characterId);

    if (!mounted || duplicatedCharacter.id == null) {
      return;
    }

    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => CharacterDetailPage(
          repository: widget.repository,
          characterId: duplicatedCharacter.id!,
        ),
      ),
    );
  }

  Future<void> _changeResourceValue({
    required _SheetResource resource,
    required int delta,
  }) async {
    final CharacterSheet? currentCharacterSheet = characterSheet;

    if (currentCharacterSheet == null) {
      return;
    }

    final CharacterSheet updatedCharacter;
    final int currentResourceSaveVersion = resourceSaveVersion + 1;
    resourceSaveVersion = currentResourceSaveVersion;

    switch (resource) {
      case _SheetResource.life:
        final int nextLifeCurrent = _clampValue(
          currentCharacterSheet.lifeCurrent + delta,
          currentCharacterSheet.lifeMaximum,
        );
        updatedCharacter = currentCharacterSheet.copyWith(
          lifeCurrent: nextLifeCurrent,
          clearLifeCurrent: nextLifeCurrent == 0,
        );
      case _SheetResource.sanity:
        final int nextSanityCurrent = _clampValue(
          currentCharacterSheet.sanityCurrent + delta,
          currentCharacterSheet.sanityMaximum,
        );
        updatedCharacter = currentCharacterSheet.copyWith(
          sanityCurrent: nextSanityCurrent,
          clearSanityCurrent: nextSanityCurrent == 0,
        );
      case _SheetResource.effort:
        final int nextEffortCurrent = _clampValue(
          currentCharacterSheet.effortCurrent + delta,
          currentCharacterSheet.effortMaximum,
        );
        updatedCharacter = currentCharacterSheet.copyWith(
          effortCurrent: nextEffortCurrent,
          clearEffortCurrent: nextEffortCurrent == 0,
        );
    }

    setState(() {
      characterSheet = updatedCharacter;
    });

    resourceSaveQueue = resourceSaveQueue.then((_) async {
      try {
        if (currentResourceSaveVersion != resourceSaveVersion) {
          return;
        }

        final CharacterSheet? latestCharacterSheet = characterSheet;

        if (latestCharacterSheet == null) {
          return;
        }

        final CharacterSheet savedCharacter = await widget.repository
            .saveCharacter(latestCharacterSheet);

        if (!mounted || currentResourceSaveVersion != resourceSaveVersion) {
          return;
        }

        setState(() {
          characterSheet = savedCharacter;
          errorMessage = null;
        });
      } catch (exception) {
        if (!mounted) {
          return;
        }

        setState(() {
          errorMessage = 'Não foi possível salvar a alteração.';
        });
      }
    });

    await resourceSaveQueue;
  }

  int _clampValue(int value, int maximum) {
    if (value < 0) {
      return 0;
    }

    if (value > maximum) {
      return maximum;
    }

    return value;
  }

  @override
  Widget build(BuildContext context) {
    final CharacterSheet? currentCharacterSheet = characterSheet;

    return DefaultTabController(
      length: 6,
      child: Scaffold(
        backgroundColor: const Color(0xFF080808),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0D0D0D),
          surfaceTintColor: Colors.transparent,
          title: Text(currentCharacterSheet?.characterName ?? 'Ficha'),
          actions: <Widget>[
            IconButton(
              tooltip: 'Editar',
              onPressed: currentCharacterSheet == null ? null : _openEditor,
              icon: const Icon(Icons.edit_outlined),
            ),
            PopupMenuButton<String>(
              onSelected: (String action) {
                if (action == 'duplicate') {
                  _duplicateCharacter();
                }
                if (action == 'export') {
                  _openExport();
                }
                if (action == 'delete' && currentCharacterSheet != null) {
                  _deleteCharacter(currentCharacterSheet);
                }
              },
              itemBuilder: (BuildContext context) =>
                  const <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(
                      value: 'duplicate',
                      child: Text('Duplicar'),
                    ),
                    PopupMenuItem<String>(
                      value: 'export',
                      child: Text('Exportar/compartilhar'),
                    ),
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Text('Excluir'),
                    ),
                  ],
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: Color(0xFFA347FF),
            tabs: <Widget>[
              Tab(text: 'Status'),
              Tab(text: 'Perícias'),
              Tab(text: 'Combate'),
              Tab(text: 'Inventário'),
              Tab(text: 'Extras'),
              Tab(text: 'Notas'),
            ],
          ),
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading && characterSheet == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final CharacterSheet? currentCharacterSheet = characterSheet;

    if (currentCharacterSheet == null) {
      return Center(child: Text(errorMessage ?? 'Ficha não encontrada.'));
    }

    return TabBarView(
      children: <Widget>[
        _SheetScroll(
          child: _StatusTab(
            characterSheet: currentCharacterSheet,
            onChangeResourceValue:
                ({required _SheetResource resource, required int delta}) =>
                    _changeResourceValue(resource: resource, delta: delta),
          ),
        ),
        _SheetScroll(child: _SkillsTab(characterSheet: currentCharacterSheet)),
        _SheetScroll(child: _CombatTab(characterSheet: currentCharacterSheet)),
        _SheetScroll(
          child: _InventoryTab(characterSheet: currentCharacterSheet),
        ),
        _SheetScroll(child: _ExtrasTab(characterSheet: currentCharacterSheet)),
        _SheetScroll(child: _NotesTab(characterSheet: currentCharacterSheet)),
      ],
    );
  }
}

enum _SheetResource { life, sanity, effort }

class _SheetScroll extends StatelessWidget {
  const _SheetScroll({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      children: <Widget>[child],
    );
  }
}

class _StatusTab extends StatelessWidget {
  const _StatusTab({
    required this.characterSheet,
    required this.onChangeResourceValue,
  });

  final CharacterSheet characterSheet;
  final void Function({required _SheetResource resource, required int delta})
  onChangeResourceValue;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool useWideLayout = constraints.maxWidth >= 760;

        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: <Widget>[
            SizedBox(
              width: useWideLayout
                  ? (constraints.maxWidth - 14) * 0.48
                  : constraints.maxWidth,
              child: _IdentityAndAttributesCard(characterSheet: characterSheet),
            ),
            SizedBox(
              width: useWideLayout
                  ? (constraints.maxWidth - 14) * 0.52
                  : constraints.maxWidth,
              child: _StatusPanel(
                characterSheet: characterSheet,
                onChangeResourceValue: onChangeResourceValue,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _IdentityAndAttributesCard extends StatelessWidget {
  const _IdentityAndAttributesCard({required this.characterSheet});

  final CharacterSheet characterSheet;

  @override
  Widget build(BuildContext context) {
    return _SheetPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _PortraitPlaceholder(characterName: characterSheet.characterName),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: <Widget>[
                    _HeaderLine(
                      label: 'PERSONAGEM',
                      value: characterSheet.characterName,
                    ),
                    _HeaderLine(label: 'ORIGEM', value: characterSheet.origin),
                    _HeaderLine(
                      label: 'JOGADOR',
                      value: characterSheet.playerName,
                    ),
                    _HeaderLine(
                      label: 'CLASSE',
                      value: characterSheet.characterClass,
                    ),
                    _HeaderLine(
                      label: 'TRILHA',
                      value: characterSheet.characterPath,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          AttributeCircle(characterSheet: characterSheet),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: <Widget>[
              _FramedValue(
                label: 'NEX',
                value: '${characterSheet.exposureLevel}%',
              ),
              _FramedValue(
                label: 'PE / TURNO',
                value: characterSheet.effortMaximum.toString(),
              ),
              _FramedValue(
                label: 'DESLOCAMENTO',
                value: '${characterSheet.movement} m',
              ),
              _FramedValue(label: 'PATENTE', value: characterSheet.rank),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({
    required this.characterSheet,
    required this.onChangeResourceValue,
  });

  final CharacterSheet characterSheet;
  final void Function({required _SheetResource resource, required int delta})
  onChangeResourceValue;

  @override
  Widget build(BuildContext context) {
    return _SheetPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _ResourceBar(
            label: 'VIDA',
            currentValue: characterSheet.lifeCurrent,
            maximumValue: characterSheet.lifeMaximum,
            color: const Color(0xFFBE2028),
            onDecrease: () =>
                onChangeResourceValue(resource: _SheetResource.life, delta: -1),
            onDecreaseLarge: () =>
                onChangeResourceValue(resource: _SheetResource.life, delta: -5),
            onIncrease: () =>
                onChangeResourceValue(resource: _SheetResource.life, delta: 1),
            onIncreaseLarge: () =>
                onChangeResourceValue(resource: _SheetResource.life, delta: 5),
          ),
          const SizedBox(height: 14),
          _ResourceBar(
            label: 'SANIDADE',
            currentValue: characterSheet.sanityCurrent,
            maximumValue: characterSheet.sanityMaximum,
            color: const Color(0xFF4E2768),
            onDecrease: () => onChangeResourceValue(
              resource: _SheetResource.sanity,
              delta: -1,
            ),
            onDecreaseLarge: () => onChangeResourceValue(
              resource: _SheetResource.sanity,
              delta: -5,
            ),
            onIncrease: () => onChangeResourceValue(
              resource: _SheetResource.sanity,
              delta: 1,
            ),
            onIncreaseLarge: () => onChangeResourceValue(
              resource: _SheetResource.sanity,
              delta: 5,
            ),
          ),
          const SizedBox(height: 14),
          _ResourceBar(
            label: 'ESFORCO',
            currentValue: characterSheet.effortCurrent,
            maximumValue: characterSheet.effortMaximum,
            color: const Color(0xFFFF8518),
            onDecrease: () => onChangeResourceValue(
              resource: _SheetResource.effort,
              delta: -1,
            ),
            onDecreaseLarge: () => onChangeResourceValue(
              resource: _SheetResource.effort,
              delta: -5,
            ),
            onIncrease: () => onChangeResourceValue(
              resource: _SheetResource.effort,
              delta: 1,
            ),
            onIncreaseLarge: () => onChangeResourceValue(
              resource: _SheetResource.effort,
              delta: 5,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              _DefenseShield(value: characterSheet.defense),
              const SizedBox(width: 14),
              Expanded(
                child: _DefenseBreakdown(characterSheet: characterSheet),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _InfoLine(label: 'PROTEÇÃO', value: _protectionText(characterSheet)),
          _InfoLine(
            label: 'RESISTENCIAS',
            value: _resistanceText(characterSheet),
          ),
          _InfoLine(
            label: 'PROFICIENCIAS',
            value: _proficiencyText(characterSheet),
          ),
        ],
      ),
    );
  }

  String _protectionText(CharacterSheet characterSheet) {
    final List<String> protections = characterSheet.items
        .where((CharacterItem characterItem) => characterItem.isProtection)
        .map((CharacterItem characterItem) => characterItem.name)
        .where((String name) => name.trim().isNotEmpty)
        .toList();

    if (protections.isEmpty) {
      return 'Nenhuma';
    }

    return protections.join(', ');
  }

  String _resistanceText(CharacterSheet characterSheet) {
    CharacterNote? resistanceNote;

    for (final CharacterNote note in characterSheet.notes) {
      if (note.title.toLowerCase().contains('resist') ||
          note.category.toLowerCase().contains('resist')) {
        resistanceNote = note;
        break;
      }
    }

    return resistanceNote?.content ?? 'Nenhuma';
  }

  String _proficiencyText(CharacterSheet characterSheet) {
    final List<String> weaponNotes = characterSheet.weapons
        .map((CharacterWeapon weapon) => weapon.notes)
        .where((String note) => note.trim().isNotEmpty)
        .toList();

    if (weaponNotes.isEmpty) {
      return characterSheet.characterClass.isEmpty
          ? 'Não informado'
          : characterSheet.characterClass;
    }

    return weaponNotes.join(' | ');
  }
}

class AttributeCircle extends StatelessWidget {
  const AttributeCircle({required this.characterSheet, super.key});

  static const double _assetSize = 720;
  static const Offset _agilityNumberAnchor = Offset(
    360 / _assetSize,
    132 / _assetSize,
  );
  static const Offset _strengthNumberAnchor = Offset(
    137 / _assetSize,
    292 / _assetSize,
  );
  static const Offset _intellectNumberAnchor = Offset(
    586 / _assetSize,
    290 / _assetSize,
  );
  static const Offset _presenceNumberAnchor = Offset(
    211 / _assetSize,
    557 / _assetSize,
  );
  static const Offset _vigorNumberAnchor = Offset(
    505 / _assetSize,
    555 / _assetSize,
  );

  final CharacterSheet characterSheet;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final Size canvasSize = Size(
            constraints.maxWidth,
            constraints.maxHeight,
          );

          return Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Positioned.fill(
                child: Image.asset(
                  'assets/images/attributes.png',
                  fit: BoxFit.contain,
                  color: Colors.white.withValues(alpha: 0.92),
                ),
              ),
              _AttributeBadge(
                numberKey: const ValueKey<String>('attribute-number-agility'),
                anchor: _agilityNumberAnchor,
                canvasSize: canvasSize,
                value: characterSheet.attributes.agility,
              ),
              _AttributeBadge(
                numberKey: const ValueKey<String>('attribute-number-strength'),
                anchor: _strengthNumberAnchor,
                canvasSize: canvasSize,
                value: characterSheet.attributes.strength,
              ),
              _AttributeBadge(
                numberKey: const ValueKey<String>('attribute-number-intellect'),
                anchor: _intellectNumberAnchor,
                canvasSize: canvasSize,
                value: characterSheet.attributes.intellect,
              ),
              _AttributeBadge(
                numberKey: const ValueKey<String>('attribute-number-presence'),
                anchor: _presenceNumberAnchor,
                canvasSize: canvasSize,
                value: characterSheet.attributes.presence,
              ),
              _AttributeBadge(
                numberKey: const ValueKey<String>('attribute-number-vigor'),
                anchor: _vigorNumberAnchor,
                canvasSize: canvasSize,
                value: characterSheet.attributes.vigor,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AttributeBadge extends StatelessWidget {
  const _AttributeBadge({
    required this.numberKey,
    required this.anchor,
    required this.canvasSize,
    required this.value,
  });

  final Key numberKey;
  final Offset anchor;
  final Size canvasSize;
  final int value;

  @override
  Widget build(BuildContext context) {
    final double side = canvasSize.shortestSide;
    final double badgeWidth = side * 0.12;
    final double badgeHeight = side * 0.09;
    final double numberFontSize = (side * 0.058).clamp(24, 36).toDouble();

    return Positioned(
      left: canvasSize.width * anchor.dx - badgeWidth / 2,
      top: canvasSize.height * anchor.dy - badgeHeight / 2,
      width: badgeWidth,
      height: badgeHeight,
      child: SizedBox.expand(
        key: numberKey,
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: numberFontSize,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResourceBar extends StatelessWidget {
  const _ResourceBar({
    required this.label,
    required this.currentValue,
    required this.maximumValue,
    required this.color,
    required this.onDecrease,
    required this.onDecreaseLarge,
    required this.onIncrease,
    required this.onIncreaseLarge,
  });

  final String label;
  final int currentValue;
  final int maximumValue;
  final Color color;
  final VoidCallback onDecrease;
  final VoidCallback onDecreaseLarge;
  final VoidCallback onIncrease;
  final VoidCallback onIncreaseLarge;

  @override
  Widget build(BuildContext context) {
    final double percentage = maximumValue <= 0
        ? 0
        : (currentValue / maximumValue).clamp(0, 1).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFFB8B8C2),
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 38,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white38),
            color: const Color(0xFF101010),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              FractionallySizedBox(
                widthFactor: percentage,
                alignment: Alignment.centerLeft,
                child: DecoratedBox(decoration: BoxDecoration(color: color)),
              ),
              Row(
                children: <Widget>[
                  _BarIconButton(
                    tooltip: 'Diminuir $label em 5',
                    icon: Icons.keyboard_double_arrow_left,
                    onPressed: onDecreaseLarge,
                  ),
                  _BarIconButton(
                    tooltip: 'Diminuir $label',
                    icon: Icons.chevron_left,
                    onPressed: onDecrease,
                  ),
                  Expanded(
                    child: Text(
                      '$currentValue/$maximumValue',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  _BarIconButton(
                    tooltip: 'Aumentar $label',
                    icon: Icons.chevron_right,
                    onPressed: onIncrease,
                  ),
                  _BarIconButton(
                    tooltip: 'Aumentar $label em 5',
                    icon: Icons.keyboard_double_arrow_right,
                    onPressed: onIncreaseLarge,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BarIconButton extends StatelessWidget {
  const _BarIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 34, height: 34),
    );
  }
}

class _DefenseShield extends StatelessWidget {
  const _DefenseShield({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 74,
      height: 82,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white, width: 3),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
          bottomLeft: Radius.circular(34),
          bottomRight: Radius.circular(34),
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        value.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _DefenseBreakdown extends StatelessWidget {
  const _DefenseBreakdown({required this.characterSheet});

  final CharacterSheet characterSheet;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'DEFESA',
          style: TextStyle(
            color: Color(0xFFB8B8C2),
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '= 10 + ${characterSheet.attributes.agility} AGI + ${characterSheet.items.where((CharacterItem characterItem) => characterItem.isProtection).fold(0, (int total, CharacterItem characterItem) => total + characterItem.defenseBonus)} Equip. + ${characterSheet.defenseManualBonus} Outros.',
          style: const TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 16,
          runSpacing: 10,
          children: <Widget>[
            _SmallStat(label: 'BLOQUEIO', value: '0'),
            _SmallStat(
              label: 'ESQUIVA',
              value: characterSheet.defense.toString(),
            ),
          ],
        ),
      ],
    );
  }
}

class _SkillsTab extends StatelessWidget {
  const _SkillsTab({required this.characterSheet});

  final CharacterSheet characterSheet;

  @override
  Widget build(BuildContext context) {
    return _SheetPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const _PanelTitle('PERICIAS'),
          const SizedBox(height: 8),
          ...characterSheet.skills.map(
            (CharacterSkill skill) => _ExpandableDetailBlock(
              title: skill.name,
              trailing: '+${skill.total}',
              initiallyExpanded: skill.notes.trim().isNotEmpty,
              lines: <String>[
                'Treinamento: ${skill.training}',
                'Bônus manual: ${skill.bonus}',
                skill.notes,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CombatTab extends StatelessWidget {
  const _CombatTab({required this.characterSheet});

  final CharacterSheet characterSheet;

  @override
  Widget build(BuildContext context) {
    return _SheetPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const _PanelTitle('COMBATE'),
          const SizedBox(height: 8),
          if (characterSheet.weapons.isEmpty)
            const _EmptyText('Nenhuma arma cadastrada.'),
          ...characterSheet.weapons.map(
            (CharacterWeapon weapon) => _ExpandableDetailBlock(
              title: weapon.name,
              trailing: weapon.damage,
              lines: <String>[
                'Ataque: ${weapon.attackBonus}',
                'Dano: ${weapon.damage}',
                'Crítico: ${weapon.critical}',
                'Alcance: ${weapon.range}',
                'Notas: ${weapon.notes}',
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InventoryTab extends StatelessWidget {
  const _InventoryTab({required this.characterSheet});

  final CharacterSheet characterSheet;

  @override
  Widget build(BuildContext context) {
    return _SheetPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const _PanelTitle('INVENTARIO'),
          const SizedBox(height: 8),
          if (characterSheet.items.isEmpty)
            const _EmptyText('Nenhum item cadastrado.'),
          ...characterSheet.items.map(
            (CharacterItem item) => _ExpandableDetailBlock(
              title: item.name,
              trailing: item.category,
              lines: <String>[
                'Categoria: ${item.category}',
                'Quantidade: ${item.quantity}',
                'Carga: ${item.weight}',
                'Bônus de defesa: ${item.defenseBonus}',
                'Notas: ${item.notes}',
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExtrasTab extends StatelessWidget {
  const _ExtrasTab({required this.characterSheet});

  final CharacterSheet characterSheet;

  @override
  Widget build(BuildContext context) {
    return _SheetPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const _PanelTitle('PODERES'),
          const SizedBox(height: 8),
          if (characterSheet.powers.isEmpty)
            const _EmptyText('Nenhum poder ou habilidade cadastrado.'),
          ...characterSheet.powers.map(
            (CharacterPower power) => _ExpandableDetailBlock(
              title: power.name,
              trailing: power.category,
              lines: <String>[
                'Categoria: ${power.category}',
                power.description.trim().isEmpty
                    ? 'Sem descrição cadastrada.'
                    : power.description,
              ],
            ),
          ),
          const SizedBox(height: 18),
          const _PanelTitle('RITUAIS'),
          const SizedBox(height: 8),
          if (characterSheet.rituals.isEmpty)
            const _EmptyText('Nenhum ritual cadastrado.'),
          ...characterSheet.rituals.map(
            (CharacterRitual ritual) => _ExpandableDetailBlock(
              title: ritual.name,
              trailing: ritual.circle,
              lines: <String>[
                'Circulo: ${ritual.circle}',
                'Custo: ${ritual.cost}',
                ritual.description.trim().isEmpty
                    ? 'Sem descrição cadastrada.'
                    : ritual.description,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotesTab extends StatelessWidget {
  const _NotesTab({required this.characterSheet});

  final CharacterSheet characterSheet;

  @override
  Widget build(BuildContext context) {
    return _SheetPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const _PanelTitle('ANOTACOES E HISTORICO'),
          const SizedBox(height: 8),
          if (characterSheet.notes.isEmpty)
            const _EmptyText('Nenhuma anotação cadastrada.'),
          ...characterSheet.notes.map(
            (CharacterNote note) => _ExpandableDetailBlock(
              title: note.title.isEmpty ? note.category : note.title,
              trailing: note.category,
              lines: <String>['Categoria: ${note.category}', note.content],
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetPanel extends StatelessWidget {
  const _SheetPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF101010),
        border: Border.all(color: const Color(0xFF2B2B2B)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: child,
    );
  }
}

class _HeaderLine extends StatelessWidget {
  const _HeaderLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          SizedBox(
            width: 86,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF9AA2B6),
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.white54)),
              ),
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                value.trim().isEmpty ? '-' : value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PortraitPlaceholder extends StatelessWidget {
  const _PortraitPlaceholder({required this.characterName});

  final String characterName;

  @override
  Widget build(BuildContext context) {
    final String initials = characterName.trim().isEmpty
        ? '?'
        : characterName
              .trim()
              .split(RegExp(r'\s+'))
              .take(2)
              .map((String namePart) => namePart.characters.first)
              .join()
              .toUpperCase();

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFF191919),
        border: Border.all(color: Colors.white54),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 20,
        ),
      ),
    );
  }
}

class _FramedValue extends StatelessWidget {
  const _FramedValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          constraints: const BoxConstraints(minWidth: 78),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white),
            color: const Color(0xFF0A0A0A),
          ),
          child: Text(
            value.trim().isEmpty ? '-' : value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF9AA2B6),
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF9AA2B6),
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.white54)),
              ),
              padding: const EdgeInsets.only(bottom: 3),
              child: Text(
                value.trim().isEmpty ? '-' : value,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallStat extends StatelessWidget {
  const _SmallStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF9AA2B6),
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
        Container(
          constraints: const BoxConstraints(minWidth: 44),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.white)),
          ),
          padding: const EdgeInsets.only(bottom: 3),
          child: Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _PanelTitle extends StatelessWidget {
  const _PanelTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _ExpandableDetailBlock extends StatelessWidget {
  const _ExpandableDetailBlock({
    required this.title,
    required this.lines,
    this.trailing = '',
    this.initiallyExpanded = false,
  });

  final String title;
  final List<String> lines;
  final String trailing;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final List<String> visibleLines = lines
        .where((String line) => line.trim().isNotEmpty)
        .toList();

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF171717),
          border: Border.all(color: const Color(0xFF2E2E2E)),
        ),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          iconColor: const Color(0xFFA347FF),
          collapsedIconColor: Colors.white54,
          title: Text(
            title.trim().isEmpty ? 'Sem título' : title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (trailing.trim().isNotEmpty)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 108),
                  child: Text(
                    trailing,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFA347FF),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              const Icon(Icons.expand_more),
            ],
          ),
          children: visibleLines.isEmpty
              ? const <Widget>[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Sem descrição cadastrada.',
                      style: TextStyle(color: Colors.white60),
                    ),
                  ),
                ]
              : visibleLines
                    .map(
                      (String line) => Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 7),
                          child: Text(
                            line,
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                      ),
                    )
                    .toList(),
        ),
      ),
    );
  }
}

class _EmptyText extends StatelessWidget {
  const _EmptyText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Text(text, style: const TextStyle(color: Colors.white60)),
    );
  }
}
