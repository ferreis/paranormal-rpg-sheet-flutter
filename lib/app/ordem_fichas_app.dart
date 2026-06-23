import 'package:flutter/material.dart';

import '../features/characters/data/repositories/character_repository.dart';
import '../features/characters/presentation/pages/character_list_page.dart';

class OrdemFichasApp extends StatelessWidget {
  OrdemFichasApp({CharacterRepository? repository, super.key})
    : repository = repository ?? CharacterRepository();

  final CharacterRepository repository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fichas Ordem',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7B1E2B),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: CharacterListPage(repository: repository),
    );
  }
}
