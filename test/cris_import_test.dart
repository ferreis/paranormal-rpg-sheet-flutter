import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ordem_fichas/features/characters/data/services/cris_import_service.dart';

void main() {
  test('extrai id da URL do C.R.I.S.', () {
    final CrisImportService importService = CrisImportService();

    expect(
      importService.extractCharacterId(
        'https://crisordemparanormal.com/agente/zCHWUGicLBWO4MFkXRU1',
      ),
      'zCHWUGicLBWO4MFkXRU1',
    );
    expect(
      importService.extractCharacterId('zCHWUGicLBWO4MFkXRU1'),
      'zCHWUGicLBWO4MFkXRU1',
    );
  });

  test('importa ficha do C.R.I.S. sem exigir API key configurada', () async {
    Uri? requestedUri;
    final CrisImportService importService = CrisImportService(
      apiKey: '',
      httpClient: MockClient((http.Request request) async {
        requestedUri = request.url;

        return http.Response(jsonEncode(_firestoreDocument()), 200);
      }),
    );

    final characterSheet = await importService.importFromUrl(
      'https://crisordemparanormal.com/agente/zCHWUGicLBWO4MFkXRU1',
    );

    expect(characterSheet.characterName, 'Fernando Severino');
    expect(requestedUri?.host, 'firestore.googleapis.com');
    expect(
      requestedUri?.path,
      '/v1/projects/cris-ordem-paranormal/databases/(default)/documents/characters/zCHWUGicLBWO4MFkXRU1',
    );
    expect(requestedUri?.queryParameters['key'], isNotEmpty);
  });

  test('converte documento Firestore do C.R.I.S. em ficha local', () {
    final CrisImportService importService = CrisImportService();

    final characterSheet = importService.characterSheetFromFirestoreDocument(
      _firestoreDocument(),
      sourceUrl: 'https://crisordemparanormal.com/agente/zCHWUGicLBWO4MFkXRU1',
    );

    expect(characterSheet.characterName, 'Fernando Severino');
    expect(characterSheet.playerName, 'Ferreis');
    expect(characterSheet.origin, 'Escritor Paranormal');
    expect(characterSheet.characterClass, 'Sobrevivente');
    expect(characterSheet.characterPath, 'Mundano');
    expect(characterSheet.exposureLevel, 5);
    expect(characterSheet.movement, 9);
    expect(characterSheet.lifeCurrent, 11);
    expect(characterSheet.lifeMaximum, 11);
    expect(characterSheet.sanityCurrent, 3);
    expect(characterSheet.sanityMaximum, 8);
    expect(characterSheet.effortCurrent, 5);
    expect(characterSheet.effortMaximum, 5);
    expect(characterSheet.defense, 11);
    expect(characterSheet.attributes.intellect, 3);
    expect(characterSheet.skills.single.name, 'Diplomacia');
    expect(characterSheet.skills.single.training, 5);
    expect(characterSheet.weapons.single.name, 'Bastão');
    expect(characterSheet.items.single.name, 'Lanterna');
    expect(characterSheet.powers.single.description, isEmpty);
    expect(characterSheet.notes.first.title, 'Histórico');
    expect(characterSheet.notes.last.title, 'Importação C.R.I.S.');
  });
}

Map<String, Object?> _firestoreDocument() {
  return <String, Object?>{
    'fields': <String, Object?>{
      'name': _string('Fernando Severino'),
      'player': _string('Ferreis'),
      'backgroundName': _string('Escritor Paranormal'),
      'className': _string('Sobrevivente'),
      'statsClass': _string('Mundano'),
      'patent': _string('Mundano'),
      'nex': _string('5%'),
      'movement': _integer(9),
      'currentPv': _integer(11),
      'maxPv': _integer(11),
      'currentSan': _integer(3),
      'maxSan': _integer(8),
      'currentPe': _integer(5),
      'maxPe': _integer(5),
      'protectionDefense': _integer(0),
      'bonusDefense': _integer(0),
      'attributes': _map(<String, Object?>{
        'str': _integer(1),
        'dex': _integer(1),
        'int': _integer(3),
        'pre': _integer(2),
        'con': _integer(1),
      }),
      'skills': _array(<Object?>[
        _map(<String, Object?>{
          'name': _string('Diplomacia'),
          'trainingDegree': _string('5'),
          'otherBonus': _integer(0),
          'attribute': _string('PRE'),
        }),
      ]),
      'attacks': _array(<Object?>[
        _map(<String, Object?>{
          'name': _string('Bastão'),
          'attackBonus': _integer(0),
          'damage': _string('1d6'),
          'criticalRange': _integer(20),
          'criticalMult': _integer(2),
          'range': _string('-'),
          'skillUsed': _string('Luta'),
          'damageType': _string('Impacto'),
        }),
      ]),
      'inventory': _array(<Object?>[
        _map(<String, Object?>{
          'name': _string('Lanterna'),
          'itemType': _string('misc'),
          'tag': _string('Itens Operacionais'),
          'slots': _integer(1),
        }),
      ]),
      'rituals': _array(<Object?>[]),
      'powers': _array(<Object?>[
        _map(<String, Object?>{
          'name': _string('Empenho'),
          'description': _string('Descrição oficial longa ignorada.'),
        }),
      ]),
      'description': _map(<String, Object?>{
        'history': _string('História criada pelo usuário.'),
        'anotation': _string('Notas livres.'),
      }),
    },
  };
}

Map<String, Object?> _string(String value) {
  return <String, Object?>{'stringValue': value};
}

Map<String, Object?> _integer(int value) {
  return <String, Object?>{'integerValue': value.toString()};
}

Map<String, Object?> _map(Map<String, Object?> fields) {
  return <String, Object?>{
    'mapValue': <String, Object?>{'fields': fields},
  };
}

Map<String, Object?> _array(List<Object?> values) {
  return <String, Object?>{
    'arrayValue': <String, Object?>{'values': values},
  };
}
