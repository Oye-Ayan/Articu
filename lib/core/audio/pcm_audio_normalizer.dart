import 'dart:typed_data';

/// High-performance audio signal normalization engine for on-device ML ingestion.
///
/// Converts 16-bit Linear PCM (raw or inside RIFF/WAVE containers) into a
/// canonical Float32List [-1.0, 1.0] of exactly [targetSamples] (48,000 samples / 3.0s @ 16kHz).
class PcmAudioNormalizer {
  /// Default target sample rate in Hertz (16 kHz).
  static const int defaultSampleRate = 16000;

  /// Default window size in samples (3 seconds @ 16 kHz = 48,000 samples).
  static const int defaultTargetSamples = 48000;

  /// 'RIFF' ASCII tag in little-endian / ASCII bytes: 0x52, 0x49, 0x46, 0x46
  static const List<int> _riffMarker = [0x52, 0x49, 0x46, 0x46];

  /// 'WAVE' ASCII tag: 0x57, 0x41, 0x56, 0x45
  static const List<int> _waveMarker = [0x57, 0x41, 0x56, 0x45];

  /// 'data' ASCII tag: 0x64, 0x61, 0x74, 0x61
  static const List<int> _dataMarker = [0x64, 0x61, 0x74, 0x61];

  /// Converts a WAV or headerless PCM16 byte array into a normalized Float32List of length [targetSamples].
  ///
  /// - Strips any RIFF headers by dynamically resolving the 'data' chunk (handling JUNK, LIST, fmt chunks).
  /// - Falls back to headerless PCM16 if no RIFF marker is present.
  /// - Normalizes 16-bit signed integers to [-1.0, 1.0] using sample / 32768.0.
  /// - Enforces deterministic leading windowing: if > [targetSamples], takes index 0 to [targetSamples].
  /// - Zero-pads if < [targetSamples].
  static Float32List wavToFloat32(
    Uint8List rawBytes, {
    int targetSamples = defaultTargetSamples,
  }) {
    final Uint8List pcmBytes = extractPcmPayload(rawBytes);
    final Float32List floatSamples = pcm16ToFloat32(pcmBytes);
    return applyDeterministicWindow(floatSamples, targetSamples: targetSamples);
  }

  /// Dynamically extracts the raw PCM payload from a byte buffer.
  ///
  /// Inspects for RIFF/WAVE headers and walks chunks to find 'data'.
  /// If no RIFF header exists, the input is treated as headerless PCM16.
  static Uint8List extractPcmPayload(Uint8List rawBytes) {
    if (rawBytes.length < 12) {
      return rawBytes;
    }

    // Check if input begins with 'RIFF' and 'WAVE'
    final bool isRiff = _matches(rawBytes, 0, _riffMarker);
    final bool isWave = _matches(rawBytes, 8, _waveMarker);

    if (!isRiff || !isWave) {
      // Headerless raw PCM16
      return rawBytes;
    }

    final ByteData byteData = ByteData.sublistView(rawBytes);
    int offset = 12;

    // Structured chunk traversal
    while (offset + 8 <= rawBytes.length) {
      final bool isDataChunk = _matches(rawBytes, offset, _dataMarker);
      final int chunkSize = byteData.getUint32(offset + 4, Endian.little);

      if (isDataChunk) {
        final int payloadStart = offset + 8;
        if (payloadStart > rawBytes.length) {
          return Uint8List(0);
        }
        final int available = rawBytes.length - payloadStart;
        final int payloadLength = chunkSize <= available && chunkSize > 0 ? chunkSize : available;
        return rawBytes.sublist(payloadStart, payloadStart + payloadLength);
      }

      // Advance past this chunk: 4 bytes tag + 4 bytes size + payload
      offset += 8 + chunkSize;
      // RIFF chunks are word-aligned (padded to 2 bytes if odd)
      if (chunkSize % 2 != 0) {
        offset += 1;
      }
    }

    // Fallback: sequential byte scanner for 'data' marker if chunks were malformed/truncated
    for (int i = 12; i <= rawBytes.length - 8; i++) {
      if (_matches(rawBytes, i, _dataMarker)) {
        final int chunkSize = byteData.getUint32(i + 4, Endian.little);
        final int payloadStart = i + 8;
        final int available = rawBytes.length - payloadStart;
        final int payloadLength = chunkSize <= available && chunkSize > 0 ? chunkSize : available;
        return rawBytes.sublist(payloadStart, payloadStart + payloadLength);
      }
    }

    // If 'data' chunk was never found despite RIFF header, return empty buffer
    return Uint8List(0);
  }

  /// Converts 16-bit signed Little-Endian PCM bytes to normalized Float32 values.
  static Float32List pcm16ToFloat32(Uint8List pcmBytes) {
    // Each 16-bit sample requires 2 bytes. Discard trailing stray byte if odd length.
    final int sampleCount = pcmBytes.lengthInBytes ~/ 2;
    if (sampleCount == 0) {
      return Float32List(0);
    }

    final ByteData byteData = ByteData.sublistView(pcmBytes);
    final Float32List floatList = Float32List(sampleCount);

    for (int i = 0; i < sampleCount; i++) {
      final int sample = byteData.getInt16(i * 2, Endian.little);
      // Normalized to [-1.0, 1.0] with 32768.0 divisor
      floatList[i] = (sample / 32768.0).clamp(-1.0, 1.0);
    }

    return floatList;
  }

  /// Applies strict deterministic windowing to guarantee exactly [targetSamples] output length.
  ///
  /// - If [input] length > [targetSamples]: slices strictly the leading [targetSamples] (index 0 to [targetSamples]).
  /// - If [input] length < [targetSamples]: zero-pads trailing values.
  /// - If [input] length == [targetSamples]: returns [input] directly.
  static Float32List applyDeterministicWindow(
    Float32List input, {
    int targetSamples = defaultTargetSamples,
  }) {
    if (input.length == targetSamples) {
      return input;
    }

    final Float32List output = Float32List(targetSamples);

    if (input.length > targetSamples) {
      // Deterministic leading windowing: strictly index 0 to targetSamples
      output.setRange(0, targetSamples, input.sublist(0, targetSamples));
    } else if (input.isNotEmpty) {
      // Zero-pad trailing elements
      output.setRange(0, input.length, input);
    }

    return output;
  }

  static bool _matches(Uint8List source, int offset, List<int> pattern) {
    if (offset + pattern.length > source.length) return false;
    for (int i = 0; i < pattern.length; i++) {
      if (source[offset + i] != pattern[i]) return false;
    }
    return true;
  }
}
