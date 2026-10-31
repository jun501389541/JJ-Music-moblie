import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

void main() {
  const rate = 16000, samples = rate * 12;
  final b = ByteData(44 + samples * 2);
  void text(int at, String s) {
    for (var i = 0; i < s.length; i++) {
      b.setUint8(at + i, s.codeUnitAt(i));
    }
  }

  text(0, 'RIFF');
  b.setUint32(4, 36 + samples * 2, Endian.little);
  text(8, 'WAVE');
  text(12, 'fmt ');
  b.setUint32(16, 16, Endian.little);
  b.setUint16(20, 1, Endian.little);
  b.setUint16(22, 1, Endian.little);
  b.setUint32(24, rate, Endian.little);
  b.setUint32(28, rate * 2, Endian.little);
  b.setUint16(32, 2, Endian.little);
  b.setUint16(34, 16, Endian.little);
  text(36, 'data');
  b.setUint32(40, samples * 2, Endian.little);
  for (var i = 0; i < samples; i++) {
    b.setInt16(
      44 + i * 2,
      (math.sin(i * 2 * math.pi * 440 / rate) * 1500).round(),
      Endian.little,
    );
  }
  File('fixtures/local_playback/tone-long.wav')
      .writeAsBytesSync(b.buffer.asUint8List());
}
