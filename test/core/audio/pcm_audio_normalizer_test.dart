import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:articulicare/core/audio/pcm_audio_normalizer.dart';

void main() {
  group('PcmAudioNormalizer - Bit-Level Normalization & Range Compliance', () {
    test('converts signed 16-bit PCM extreme values to exact float32 bounds', () {
      // Create a 4-sample PCM16 buffer: [-32768, 0, 32767, -1]
      final ByteData byteData = ByteData(8);
      byteData.setInt16(0, -32768, Endian.little);
      byteData.setInt16(2, 0, Endian.little);
      byteData.setInt16(4, 32767, Endian.little);
      byteData.setInt16(6, -1, Endian.little);

      final Uint8List rawPcm = byteData.buffer.asUint8List();
      final Float32List normalized = PcmAudioNormalizer.pcm16ToFloat32(rawPcm);

      expect(normalized.length, equals(4));
      expect(normalized[0], equals(-1.0)); // -32768 / 32768.0 == -1.0
      expect(normalized[1], equals(0.0));  // 0 / 32768.0 == 0.0
      expect(normalized[2], closeTo(0.99996948, 1e-6)); // 32767 / 32768.0
      expect(normalized[3], closeTo(-0.00003051, 1e-6)); // -1 / 32768.0
    });

    test('guarantees no NaN, no Infinity, and strict [-1.0, 1.0] range', () {
      // Test full spectrum of 16-bit integer values in step
      final ByteData byteData = ByteData(65536 * 2);
      for (int i = -32768; i <= 32767; i++) {
        byteData.setInt16((i + 32768) * 2, i, Endian.little);
      }

      final Float32List normalized = PcmAudioNormalizer.pcm16ToFloat32(byteData.buffer.asUint8List());

      for (int i = 0; i < normalized.length; i++) {
        final double val = normalized[i];
        expect(val.isNaN, isFalse);
        expect(val.isInfinite, isFalse);
        expect(val >= -1.0 && val <= 1.0, isTrue);
      }
    });

    test('safely discards odd trailing byte from corrupted pcm stream', () {
      // 5 bytes total = 2 full 16-bit samples + 1 trailing stray byte
      final Uint8List oddBytes = Uint8List.fromList([0x00, 0x00, 0x00, 0x40, 0xFF]);
      final Float32List result = PcmAudioNormalizer.pcm16ToFloat32(oddBytes);

      expect(result.length, equals(2));
      expect(result[0], equals(0.0));
      expect(result[1], equals(0.5)); // 0x4000 = 16384 / 32768.0 = 0.5
    });
  });

  group('PcmAudioNormalizer - Dynamic RIFF & Data Chunk Parsing', () {
    test('extracts payload from standard 44-byte WAV container', () {
      // Construct a valid minimal 44-byte WAV with 4 samples: [1000, 2000, -1000, -2000]
      final List<int> samples = [1000, 2000, -1000, -2000];
      final Uint8List wavBytes = _createWavWithChunks(
        samples: samples,
        prependJunkChunk: false,
      );

      final Uint8List extracted = PcmAudioNormalizer.extractPcmPayload(wavBytes);
      expect(extracted.length, equals(samples.length * 2));

      final Float32List result = PcmAudioNormalizer.wavToFloat32(wavBytes, targetSamples: 4);
      expect(result.length, equals(4));
      expect(result[0], closeTo(1000 / 32768.0, 1e-6));
      expect(result[1], closeTo(2000 / 32768.0, 1e-6));
      expect(result[2], closeTo(-1000 / 32768.0, 1e-6));
      expect(result[3], closeTo(-2000 / 32768.0, 1e-6));
    });

    test('dynamically skips JUNK chunk and locates data chunk correctly', () {
      // Construct a WAV with an intermediate JUNK chunk (common in Android/iOS audio recorders)
      final List<int> samples = [5000, -5000, 15000];
      final Uint8List wavWithJunk = _createWavWithChunks(
        samples: samples,
        prependJunkChunk: true, // Inserts 32 bytes of 'JUNK' metadata between 'fmt ' and 'data'
      );

      final Uint8List extracted = PcmAudioNormalizer.extractPcmPayload(wavWithJunk);
      expect(extracted.length, equals(samples.length * 2));

      final Float32List result = PcmAudioNormalizer.wavToFloat32(wavWithJunk, targetSamples: 3);
      expect(result.length, equals(3));
      expect(result[0], closeTo(5000 / 32768.0, 1e-6));
      expect(result[1], closeTo(-5000 / 32768.0, 1e-6));
      expect(result[2], closeTo(15000 / 32768.0, 1e-6));
    });

    test('gracefully falls back to headerless raw PCM16 when no RIFF header exists', () {
      final ByteData byteData = ByteData(4);
      byteData.setInt16(0, 16384, Endian.little);
      byteData.setInt16(2, -16384, Endian.little);

      final Uint8List rawPcm = byteData.buffer.asUint8List();
      final Uint8List extracted = PcmAudioNormalizer.extractPcmPayload(rawPcm);

      expect(extracted, equals(rawPcm));

      final Float32List result = PcmAudioNormalizer.wavToFloat32(rawPcm, targetSamples: 2);
      expect(result.length, equals(2));
      expect(result[0], equals(0.5));
      expect(result[1], equals(-0.5));
    });
  });

  group('PcmAudioNormalizer - Deterministic Leading Windowing (48,000 samples)', () {
    test('takes strictly leading 48,000 samples when input is longer', () {
      // Create 60,000 samples where sample[i] = i
      final Float32List oversized = Float32List(60000);
      for (int i = 0; i < oversized.length; i++) {
        oversized[i] = (i % 1000) / 1000.0;
      }

      final Float32List windowed = PcmAudioNormalizer.applyDeterministicWindow(
        oversized,
        targetSamples: 48000,
      );

      expect(windowed.length, equals(48000));
      // Leading samples index 0 to 48000 must match exactly
      for (int i = 0; i < 48000; i++) {
        expect(windowed[i], equals(oversized[i]));
      }
    });

    test('zero-pads trailing samples when input is shorter than 48,000 samples', () {
      // 16,000 samples (1.0 second)
      final Float32List undersized = Float32List(16000);
      for (int i = 0; i < undersized.length; i++) {
        undersized[i] = 0.75;
      }

      final Float32List windowed = PcmAudioNormalizer.applyDeterministicWindow(
        undersized,
        targetSamples: 48000,
      );

      expect(windowed.length, equals(48000));
      // First 16,000 samples match input
      for (int i = 0; i < 16000; i++) {
        expect(windowed[i], equals(0.75));
      }
      // Remaining 32,000 samples are strictly zero
      for (int i = 16000; i < 48000; i++) {
        expect(windowed[i], equals(0.0));
      }
    });

    test('returns exact input unchanged when length is already 48,000 samples', () {
      final Float32List exact = Float32List(48000);
      exact[0] = 0.123;
      exact[47999] = 0.987;

      final Float32List windowed = PcmAudioNormalizer.applyDeterministicWindow(
        exact,
        targetSamples: 48000,
      );

      expect(windowed.length, equals(48000));
      expect(identical(exact, windowed), isTrue);
    });
  });
}

/// Helper to construct synthetic WAV binary buffers with optional JUNK chunks
Uint8List _createWavWithChunks({
  required List<int> samples,
  required bool prependJunkChunk,
}) {
  final int pcmDataBytes = samples.length * 2;
  final int junkChunkBytes = prependJunkChunk ? 32 : 0; // 8 bytes header + 24 bytes payload
  final int totalFileSize = 36 + junkChunkBytes + pcmDataBytes;

  final BytesBuilder bb = BytesBuilder();

  // 1. RIFF Header
  bb.add([0x52, 0x49, 0x46, 0x46]); // 'RIFF'
  final ByteData sizeData = ByteData(4)..setUint32(0, totalFileSize, Endian.little);
  bb.add(sizeData.buffer.asUint8List());
  bb.add([0x57, 0x41, 0x56, 0x45]); // 'WAVE'

  // 2. 'fmt ' Subchunk
  bb.add([0x66, 0x6D, 0x74, 0x20]); // 'fmt '
  final ByteData fmtSize = ByteData(4)..setUint32(0, 16, Endian.little);
  bb.add(fmtSize.buffer.asUint8List());
  final ByteData fmtData = ByteData(16);
  fmtData.setUint16(0, 1, Endian.little);      // AudioFormat: 1 (PCM)
  fmtData.setUint16(2, 1, Endian.little);      // NumChannels: 1 (Mono)
  fmtData.setUint32(4, 16000, Endian.little);  // SampleRate: 16000
  fmtData.setUint32(8, 32000, Endian.little);  // ByteRate: 16000 * 1 * 2 = 32000
  fmtData.setUint16(12, 2, Endian.little);     // BlockAlign: 2
  fmtData.setUint16(14, 16, Endian.little);    // BitsPerSample: 16
  bb.add(fmtData.buffer.asUint8List());

  // 3. Optional 'JUNK' Subchunk
  if (prependJunkChunk) {
    bb.add([0x4A, 0x55, 0x4E, 0x4B]); // 'JUNK'
    final ByteData junkSize = ByteData(4)..setUint32(0, 24, Endian.little);
    bb.add(junkSize.buffer.asUint8List());
    bb.add(Uint8List(24)); // 24 bytes of junk padding
  }

  // 4. 'data' Subchunk
  bb.add([0x64, 0x61, 0x74, 0x61]); // 'data'
  final ByteData dataSize = ByteData(4)..setUint32(0, pcmDataBytes, Endian.little);
  bb.add(dataSize.buffer.asUint8List());

  // Write PCM Samples
  final ByteData samplesData = ByteData(pcmDataBytes);
  for (int i = 0; i < samples.length; i++) {
    samplesData.setInt16(i * 2, samples[i], Endian.little);
  }
  bb.add(samplesData.buffer.asUint8List());

  return bb.toBytes();
}
