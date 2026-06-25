import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ordem_fichas/features/characters/data/services/sheet_qr_service.dart';
import 'package:ordem_fichas/features/characters/domain/entities/character_sheet.dart';
import 'package:qr_flutter/qr_flutter.dart';

void main() {
  test('gera payload compacto e restaura JSON da ficha pequena', () {
    final SheetQrService qrService = SheetQrService();
    final String jsonContent = jsonEncode(CharacterSheet.empty().toJson());

    final List<String> qrPayloads = qrService.encodeJsonParts(jsonContent);
    final String decodedJson = qrService.decodePayload(qrPayloads.single);

    expect(qrPayloads, hasLength(1));
    expect(qrPayloads.single, startsWith(SheetQrService.payloadPrefix));
    expect(
      qrPayloads.single.length,
      lessThanOrEqualTo(SheetQrService.maxQrPayloadLength),
    );
    expect(decodedJson, jsonContent);
  });

  test('divide ficha grande em partes e restaura JSON completo', () {
    final SheetQrService qrService = SheetQrService();
    final String largeText = base64Url.encode(_pseudoRandomBytes(50000));
    final String jsonContent = jsonEncode(<String, Object?>{
      'characterName': 'Agente QR',
      'notes': <Map<String, Object?>>[
        <String, Object?>{'title': 'Texto grande', 'content': largeText},
      ],
    });

    final List<String> qrPayloads = qrService.encodeJsonParts(jsonContent);
    final String joinedPayload = qrService.joinPayloadParts(qrPayloads);
    final String decodedJson = qrService.decodePayload(joinedPayload);

    expect(qrPayloads.length, greaterThan(1));
    expect(
      qrPayloads.every(
        (String qrPayload) =>
            qrPayload.length <= SheetQrService.maxQrPayloadLength + 64,
      ),
      isTrue,
    );
    expect(qrPayloads.every(_isValidQrPayload), isTrue);
    expect(decodedJson, jsonContent);
  });

  test('mantem compatibilidade com JSON puro', () {
    final SheetQrService qrService = SheetQrService();
    const String jsonContent = '{"characterName":"Agente"}';

    expect(qrService.decodePayload(jsonContent), jsonContent);
  });
}

bool _isValidQrPayload(String qrPayload) {
  final QrValidationResult validationResult = QrValidator.validate(
    data: qrPayload,
    version: QrVersions.auto,
    errorCorrectionLevel: QrErrorCorrectLevel.L,
  );

  return validationResult.isValid;
}

Uint8List _pseudoRandomBytes(int byteCount) {
  final Uint8List randomBytes = Uint8List(byteCount);
  final math.Random randomGenerator = math.Random(123456789);

  for (int byteIndex = 0; byteIndex < randomBytes.length; byteIndex += 1) {
    randomBytes[byteIndex] = randomGenerator.nextInt(256);
  }

  return randomBytes;
}
