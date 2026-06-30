import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:ordem_fichas/features/characters/data/services/sheet_qr_payload_codec.dart';

class SheetQrService {
  static const String payloadPrefix = 'OFB1:';
  static const String compactJsonPayloadPrefix = 'OFZ1:';
  static const String legacyPayloadPrefix = 'ordemficha:v1:';
  static const String multipartPrefix = 'ordemficha:v2:';
  static const int maxQrPayloadByteLength = 2953;
  static const int legacyMaxQrPayloadLength = 1800;
  static const SheetQrPayloadCodec _payloadCodec = SheetQrPayloadCodec();
  static final Uint8List _binaryPayloadMagic = Uint8List.fromList(
    ascii.encode('OFB1'),
  );

  Uint8List encodeJsonBytes(String jsonContent) {
    final Uint8List payloadBytes = _payloadCodec.encodeBytes(jsonContent);
    final Uint8List compressedFileBytes = const ZLibEncoder().encodeBytes(
      payloadBytes,
      level: 9,
    );
    final Uint8List qrPayloadBytes = Uint8List.fromList(<int>[
      ..._binaryPayloadMagic,
      ...compressedFileBytes,
    ]);

    if (qrPayloadBytes.length > maxQrPayloadByteLength) {
      throw SheetQrPayloadTooLargeException(
        payloadLength: qrPayloadBytes.length,
        maxPayloadLength: maxQrPayloadByteLength,
      );
    }

    return qrPayloadBytes;
  }

  String encodeJson(String jsonContent) {
    return '$compactJsonPayloadPrefix${base64Url.encode(encodeJsonBytes(jsonContent))}';
  }

  List<String> encodeJsonParts(String jsonContent) {
    final String encodedPayload = _encodeLegacyGzipPayload(jsonContent);

    if (encodedPayload.length <= legacyMaxQrPayloadLength) {
      return <String>[encodedPayload];
    }

    final String encodedContent = encodedPayload.substring(
      legacyPayloadPrefix.length,
    );
    final String payloadId = _payloadId(encodedContent);
    final List<String> contentChunks = _splitContent(encodedContent);
    final int partCount = contentChunks.length;

    return <String>[
      for (int chunkIndex = 0; chunkIndex < contentChunks.length; chunkIndex++)
        '$multipartPrefix$payloadId:${chunkIndex + 1}:$partCount:${contentChunks[chunkIndex]}',
    ];
  }

  String decodePayload(String qrPayload) {
    final String normalizedPayload = qrPayload.trim();

    if (normalizedPayload.startsWith(multipartPrefix)) {
      return decodePayload(joinPayloadParts(<String>[normalizedPayload]));
    }

    if (normalizedPayload.startsWith(payloadPrefix)) {
      return decodePayloadBytes(Uint8List.fromList(latin1.encode(qrPayload)));
    }

    if (normalizedPayload.startsWith(compactJsonPayloadPrefix)) {
      final String encodedContent = normalizedPayload.substring(
        compactJsonPayloadPrefix.length,
      );
      final Uint8List encodedBytes = base64Url.decode(encodedContent);

      if (_hasBinaryPayloadMagic(encodedBytes)) {
        return decodePayloadBytes(encodedBytes);
      }

      final Uint8List jsonBytes = const ZLibDecoder().decodeBytes(encodedBytes);

      return _payloadCodec.decodeCompactJson(utf8.decode(jsonBytes));
    }

    if (normalizedPayload.startsWith(legacyPayloadPrefix)) {
      final String encodedContent = normalizedPayload.substring(
        legacyPayloadPrefix.length,
      );
      final Uint8List gzipBytes = base64Url.decode(encodedContent);
      final Uint8List jsonBytes = const GZipDecoder().decodeBytes(gzipBytes);

      return utf8.decode(jsonBytes);
    }

    return normalizedPayload;
  }

  bool canDecodePayloadBytes(Uint8List qrPayloadBytes) {
    return _hasBinaryPayloadMagic(qrPayloadBytes);
  }

  String decodePayloadBytes(Uint8List qrPayloadBytes) {
    if (!_hasBinaryPayloadMagic(qrPayloadBytes)) {
      throw const FormatException('QR Code binário de ficha inválido.');
    }

    final Uint8List compressedFileBytes = qrPayloadBytes.sublist(
      _binaryPayloadMagic.length,
    );
    final Uint8List payloadBytes = const ZLibDecoder().decodeBytes(
      compressedFileBytes,
    );

    return _payloadCodec.decodeBytes(payloadBytes);
  }

  bool _hasBinaryPayloadMagic(Uint8List qrPayloadBytes) {
    if (qrPayloadBytes.length <= _binaryPayloadMagic.length) {
      return false;
    }

    for (
      int byteIndex = 0;
      byteIndex < _binaryPayloadMagic.length;
      byteIndex++
    ) {
      if (qrPayloadBytes[byteIndex] != _binaryPayloadMagic[byteIndex]) {
        return false;
      }
    }

    return true;
  }

  SheetQrPart? parsePart(String qrPayload) {
    final String normalizedPayload = qrPayload.trim();

    if (!normalizedPayload.startsWith(multipartPrefix)) {
      return null;
    }

    final String multipartContent = normalizedPayload.substring(
      multipartPrefix.length,
    );
    final List<String> payloadSegments = multipartContent.split(':');

    if (payloadSegments.length != 4) {
      throw const FormatException('QR Code de ficha inválido.');
    }

    final String payloadId = payloadSegments[0];
    final int partIndex = int.parse(payloadSegments[1]);
    final int partCount = int.parse(payloadSegments[2]);
    final String chunkContent = payloadSegments[3];

    if (payloadId.isEmpty ||
        partIndex < 1 ||
        partCount < 1 ||
        partIndex > partCount ||
        chunkContent.isEmpty) {
      throw const FormatException('QR Code de ficha inválido.');
    }

    return SheetQrPart(
      payloadId: payloadId,
      partIndex: partIndex,
      partCount: partCount,
      chunkContent: chunkContent,
    );
  }

  String joinPayloadParts(Iterable<String> qrPayloads) {
    final List<SheetQrPart> qrParts = qrPayloads
        .map(parsePart)
        .whereType<SheetQrPart>()
        .toList();

    if (qrParts.isEmpty) {
      throw const FormatException('Nenhuma parte de QR Code informada.');
    }

    final String payloadId = qrParts.first.payloadId;
    final int partCount = qrParts.first.partCount;

    if (qrParts.any(
      (SheetQrPart qrPart) =>
          qrPart.payloadId != payloadId || qrPart.partCount != partCount,
    )) {
      throw const FormatException('Partes de QR Code incompatíveis.');
    }

    final Map<int, String> chunksByIndex = <int, String>{
      for (final SheetQrPart qrPart in qrParts)
        qrPart.partIndex: qrPart.chunkContent,
    };

    if (chunksByIndex.length != partCount) {
      throw const FormatException('QR Code incompleto.');
    }

    final String encodedContent = <String>[
      for (int partIndex = 1; partIndex <= partCount; partIndex++)
        chunksByIndex[partIndex]!,
    ].join();

    if (_payloadId(encodedContent) != payloadId) {
      throw const FormatException('QR Code corrompido.');
    }

    return '$legacyPayloadPrefix$encodedContent';
  }

  String _encodeLegacyGzipPayload(String jsonContent) {
    final String compactJson = _compactJson(jsonContent);
    final Uint8List jsonBytes = Uint8List.fromList(utf8.encode(compactJson));
    final Uint8List gzipBytes = const GZipEncoder().encodeBytes(
      jsonBytes,
      level: 9,
    );

    return '$legacyPayloadPrefix${base64Url.encode(gzipBytes)}';
  }

  String _compactJson(String jsonContent) {
    try {
      return jsonEncode(jsonDecode(jsonContent));
    } on FormatException {
      return jsonContent;
    }
  }

  List<String> _splitContent(String encodedContent) {
    final List<String> contentChunks = <String>[];

    for (
      int startIndex = 0;
      startIndex < encodedContent.length;
      startIndex += legacyMaxQrPayloadLength
    ) {
      final int endIndex = startIndex + legacyMaxQrPayloadLength;
      contentChunks.add(
        encodedContent.substring(
          startIndex,
          endIndex > encodedContent.length ? encodedContent.length : endIndex,
        ),
      );
    }

    return contentChunks;
  }

  String _payloadId(String encodedContent) {
    final int checksum = getCrc32(utf8.encode(encodedContent));

    return checksum.toRadixString(16).padLeft(8, '0');
  }
}

class SheetQrPayloadTooLargeException implements Exception {
  const SheetQrPayloadTooLargeException({
    required this.payloadLength,
    required this.maxPayloadLength,
  });

  final int payloadLength;
  final int maxPayloadLength;

  @override
  String toString() {
    return 'SheetQrPayloadTooLargeException: payloadLength=$payloadLength, '
        'maxPayloadLength=$maxPayloadLength';
  }
}

class SheetQrPart {
  const SheetQrPart({
    required this.payloadId,
    required this.partIndex,
    required this.partCount,
    required this.chunkContent,
  });

  final String payloadId;
  final int partIndex;
  final int partCount;
  final String chunkContent;
}
