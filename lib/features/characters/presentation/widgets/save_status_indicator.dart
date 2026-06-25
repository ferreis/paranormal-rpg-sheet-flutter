import 'package:flutter/material.dart';

import 'package:ordem_fichas/features/characters/presentation/controllers/character_editor_controller.dart';

class SaveStatusIndicator extends StatelessWidget {
  const SaveStatusIndicator({required this.status, super.key});

  final CharacterSaveStatus status;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 150),
      child: _content(colorScheme),
    );
  }

  Widget _content(ColorScheme colorScheme) {
    switch (status) {
      case CharacterSaveStatus.saving:
        return const Row(
          key: ValueKey<String>('saving'),
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8),
            Text('Salvando'),
          ],
        );
      case CharacterSaveStatus.saved:
        return Row(
          key: const ValueKey<String>('saved'),
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.check_circle, size: 18, color: colorScheme.primary),
            const SizedBox(width: 6),
            const Text('Salvo'),
          ],
        );
      case CharacterSaveStatus.error:
        return Row(
          key: const ValueKey<String>('error'),
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.error_outline, size: 18, color: colorScheme.error),
            const SizedBox(width: 6),
            const Text('Erro'),
          ],
        );
      case CharacterSaveStatus.idle:
        return const SizedBox.shrink(key: ValueKey<String>('idle'));
    }
  }
}
