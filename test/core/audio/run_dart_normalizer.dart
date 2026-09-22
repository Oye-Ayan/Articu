import 'dart:io';
import 'dart:typed_data';
import 'package:articulicare/core/audio/pcm_audio_normalizer.dart';

void main(List<String> args) {
  if (args.length < 2) {
    stderr.writeln('Usage: dart run_dart_normalizer.dart <input_wav_path> <output_raw_float32_path>');
    exit(1);
  }

  final String inputPath = args[0];
  final String outputPath = args[1];

  final Uint8List rawBytes = File(inputPath).readAsBytesSync();
  final Float32List normalized = PcmAudioNormalizer.wavToFloat32(rawBytes);

  // Write out as raw little-endian Float32 byte stream
  final Uint8List outBytes = normalized.buffer.asUint8List();
  File(outputPath).writeAsBytesSync(outBytes);

  stdout.writeln('PROCESSED ${normalized.length} SAMPLES');
}
