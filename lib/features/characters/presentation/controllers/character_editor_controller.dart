import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/models/character_sheet.dart';
import '../../data/repositories/character_repository.dart';
import '../../domain/services/character_calculation_service.dart';

enum CharacterSaveStatus { idle, saving, saved, error }

class CharacterEditorController extends ChangeNotifier {
  CharacterEditorController({
    required this.repository,
    CharacterCalculationService? calculationService,
  }) : _calculationService =
           calculationService ?? CharacterCalculationService();

  final CharacterRepository repository;
  final CharacterCalculationService _calculationService;

  CharacterSheet? characterSheet;
  CharacterSaveStatus saveStatus = CharacterSaveStatus.idle;
  bool isLoading = false;
  String? errorMessage;

  Timer? _autoSaveTimer;

  Future<void> load({int? characterId}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      if (characterId == null) {
        characterSheet = _calculationService.applyAutomaticValues(
          CharacterSheet.empty(),
        );
      } else {
        final CharacterSheet? loadedCharacter = await repository.getCharacter(
          characterId,
        );
        characterSheet = loadedCharacter == null
            ? null
            : _calculationService.applyAutomaticValues(loadedCharacter);
      }
    } catch (exception) {
      errorMessage = 'Não foi possível carregar a ficha.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void updateCharacter(
    CharacterSheet Function(CharacterSheet currentSheet) sheetChange,
  ) {
    final CharacterSheet? currentSheet = characterSheet;

    if (currentSheet == null) {
      return;
    }

    characterSheet = _calculationService.applyAutomaticValues(
      sheetChange(currentSheet),
    );
    saveStatus = CharacterSaveStatus.idle;
    errorMessage = null;
    notifyListeners();
    _scheduleAutoSave();
  }

  Future<void> saveNow() async {
    final CharacterSheet? currentSheet = characterSheet;

    if (currentSheet == null) {
      return;
    }

    _autoSaveTimer?.cancel();
    saveStatus = CharacterSaveStatus.saving;
    errorMessage = null;
    notifyListeners();

    try {
      characterSheet = await repository.saveCharacter(currentSheet);
      saveStatus = CharacterSaveStatus.saved;
    } catch (exception) {
      saveStatus = CharacterSaveStatus.error;
      errorMessage = 'Erro ao salvar a ficha.';
    }

    notifyListeners();
  }

  void _scheduleAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(milliseconds: 700), saveNow);
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    super.dispose();
  }
}
