import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ordem_fichas/features/characters/data/services/sheet_qr_service.dart';
import 'package:ordem_fichas/features/characters/domain/entities/character_sheet.dart';
import 'package:qr_flutter/qr_flutter.dart';

void main() {
  test('compacta dados, gera um QR Code e restaura JSON da ficha', () {
    final SheetQrService qrService = SheetQrService();
    final String jsonContent = jsonEncode(CharacterSheet.empty().toJson());

    final Uint8List qrPayloadBytes = qrService.encodeJsonBytes(jsonContent);
    final String decodedJson = qrService.decodePayloadBytes(qrPayloadBytes);
    final QrCode qrCode = QrCode.fromUint8List(
      data: qrPayloadBytes,
      errorCorrectLevel: QrErrorCorrectLevel.L,
    );

    expect(
      qrPayloadBytes.length,
      lessThanOrEqualTo(SheetQrService.maxQrPayloadByteLength),
    );
    expect(qrCode.typeNumber, lessThanOrEqualTo(40));
    expect(jsonDecode(decodedJson), jsonDecode(jsonContent));
  });

  test('mantem leitura de payload textual OFB1 empacotado', () {
    final SheetQrService qrService = SheetQrService();
    final String jsonContent = jsonEncode(CharacterSheet.empty().toJson());

    final String qrPayload = qrService.encodeJson(jsonContent);
    final String decodedJson = qrService.decodePayload(qrPayload);

    expect(qrPayload, startsWith(SheetQrService.compactJsonPayloadPrefix));
    expect(jsonDecode(decodedJson), jsonDecode(jsonContent));
  });

  test('rejeita ficha grande demais para um QR Code', () {
    final SheetQrService qrService = SheetQrService();
    final String largeText = base64Url.encode(_pseudoRandomBytes(50000));
    final String jsonContent = jsonEncode(<String, Object?>{
      'characterName': 'Agente QR',
      'notes': <Map<String, Object?>>[
        <String, Object?>{'title': 'Texto grande', 'content': largeText},
      ],
    });

    expect(
      () => qrService.encodeJson(jsonContent),
      throwsA(isA<SheetQrPayloadTooLargeException>()),
    );
  });

  test('mantem leitura de QR Code multipart legado', () {
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
    expect(qrPayloads.first, startsWith(SheetQrService.multipartPrefix));
    expect(
      qrPayloads.every(
        (String qrPayload) =>
            qrPayload.length <= SheetQrService.legacyMaxQrPayloadLength + 64,
      ),
      isTrue,
    );
    expect(qrPayloads.every(_isValidQrPayload), isTrue);
    expect(decodedJson, jsonContent);
  });

  test('mantem leitura de QR Code legado de uma parte', () {
    final SheetQrService qrService = SheetQrService();
    const String jsonContent = '{"characterName":"Agente legado"}';

    final String legacyQrPayload = qrService
        .encodeJsonParts(jsonContent)
        .single;

    expect(legacyQrPayload, startsWith(SheetQrService.legacyPayloadPrefix));
    expect(qrService.decodePayload(legacyQrPayload), jsonContent);
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
