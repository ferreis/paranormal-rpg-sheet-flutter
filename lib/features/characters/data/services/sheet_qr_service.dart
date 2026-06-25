import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

class SheetQrService {
  static const String payloadPrefix = 'ordemficha:v1:';
  static const String multipartPrefix = 'ordemficha:v2:';
  static const int maxQrPayloadLength = 1800;

  String encodeJson(String jsonContent) {
    final String compactJson = _compactJson(jsonContent);
    final Uint8List jsonBytes = Uint8List.fromList(utf8.encode(compactJson));
    final Uint8List gzipBytes = const GZipEncoder().encodeBytes(
      jsonBytes,
      level: 9,
    );

    return '$payloadPrefix${base64Url.encode(gzipBytes)}';
  }

  List<String> encodeJsonParts(String jsonContent) {
    final String encodedPayload = encodeJson(jsonContent);

    if (encodedPayload.length <= maxQrPayloadLength) {
      return <String>[encodedPayload];
    }

    final String encodedContent = encodedPayload.substring(
      payloadPrefix.length,
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

    if (!normalizedPayload.startsWith(payloadPrefix)) {
      return normalizedPayload;
    }

    final String encodedContent = normalizedPayload.substring(
      payloadPrefix.length,
    );
    final Uint8List gzipBytes = base64Url.decode(encodedContent);
    final Uint8List jsonBytes = const GZipDecoder().decodeBytes(gzipBytes);

    return utf8.decode(jsonBytes);
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

    return '$payloadPrefix$encodedContent';
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
      startIndex += maxQrPayloadLength
    ) {
      final int endIndex = startIndex + maxQrPayloadLength;
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
