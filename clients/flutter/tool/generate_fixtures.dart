import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

/// Deterministic synthetic CC0 tones. No personal media is read.
void main() {
  final directory = Directory('fixtures/local_playback')
    ..createSync(recursive: true);
  for (final item in [('tone-a', 440), ('tone-b', 660)]) {
    const samples = 4000, rate = 8000;
    final bytes = ByteData(44 + samples * 2);
    void text(int offset, String value) {
      for (var i = 0; i < value.length; i++) {
        bytes.setUint8(offset + i, value.codeUnitAt(i));
      }
    }

    text(0, 'RIFF');
    bytes.setUint32(4, 36 + samples * 2, Endian.little);
    text(8, 'WAVE');
    text(12, 'fmt ');
    bytes.setUint32(16, 16, Endian.little);
    bytes.setUint16(20, 1, Endian.little);
    bytes.setUint16(22, 1, Endian.little);
    bytes.setUint32(24, rate, Endian.little);
    bytes.setUint32(28, rate * 2, Endian.little);
    bytes.setUint16(32, 2, Endian.little);
    bytes.setUint16(34, 16, Endian.little);
    text(36, 'data');
    bytes.setUint32(40, samples * 2, Endian.little);
    for (var i = 0; i < samples; i++) {
      bytes.setInt16(
        44 + i * 2,
        (math.sin(2 * math.pi * item.$2 * i / rate) * 3000).round(),
        Endian.little,
      );
    }
    File('${directory.path}/${item.$1}.wav')
        .writeAsBytesSync(bytes.buffer.asUint8List());
  }
}
