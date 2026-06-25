import 'package:ordem_fichas/features/characters/data/repositories/character_repository_impl.dart';
import 'package:ordem_fichas/features/characters/domain/repositories/character_repository.dart';

class AppInjection {
  const AppInjection._();

  static CharacterRepository characterRepository() {
    return CharacterRepositoryImpl();
  }
}
