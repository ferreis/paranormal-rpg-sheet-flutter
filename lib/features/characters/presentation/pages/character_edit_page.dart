import 'package:flutter/material.dart';

import 'package:ordem_fichas/features/characters/domain/repositories/character_repository.dart';
import 'package:ordem_fichas/features/characters/presentation/pages/character_form_page.dart';

class CharacterEditPage extends StatelessWidget {
  const CharacterEditPage({
    required this.repository,
    required this.characterId,
    super.key,
  });

  final CharacterRepository repository;
  final int characterId;

  @override
  Widget build(BuildContext context) {
    return CharacterFormPage(repository: repository, characterId: characterId);
  }
}
