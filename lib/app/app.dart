import 'package:flutter/material.dart';
import 'package:ordem_fichas/app/dependency_injection/injection.dart';
import 'package:ordem_fichas/app/theme/app_theme.dart';
import 'package:ordem_fichas/features/characters/domain/repositories/character_repository.dart';
import 'package:ordem_fichas/features/characters/presentation/pages/character_list_page.dart';

class App extends StatelessWidget {
  const App({this.repository, super.key});

  final CharacterRepository? repository;

  @override
  Widget build(BuildContext context) {
    final CharacterRepository characterRepository =
        repository ?? AppInjection.characterRepository();

    return MaterialApp(
      title: 'Fichas Ordem',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: CharacterListPage(repository: characterRepository),
    );
  }
}
