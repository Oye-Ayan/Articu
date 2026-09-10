import 'package:wav/wav.dart';
import 'librosa_mfcc.dart';
import '../ml/tflite_service.dart';

class SpeechAnalysisService {
  final TfliteService _tfliteService;

  SpeechAnalysisService(this._tfliteService);

  /// Analyzes the speech WAV file and returns the classification result.
  /// 0 = Non-Dysarthria, 1 = Dysarthria
  Future<int> analyzeSpeech(String wavPath) async {
    // 1. Read WAV file
    final wav = await Wav.readFile(wavPath);
    
    // Convert to mono
    List<double> monoAudio = [];
    if (wav.channels.length == 1) {
      monoAudio = wav.channels[0];
    } else {
      for (int i = 0; i < wav.channels[0].length; i++) {
        double sum = 0;
        for (int c = 0; c < wav.channels.length; c++) {
          sum += wav.channels[c][i];
        }
        monoAudio.add(sum / wav.channels.length);
      }
    }

    // 2. Extract 3-second segment starting at 0.5s (To match training)
    int sr = 16000;
    int startSample = (0.5 * sr).toInt();
    int durationSamples = (3.0 * sr).toInt();
    
    // If the audio is too short, we adjust
    if (startSample >= monoAudio.length) {
      startSample = 0;
    }
    if (startSample + durationSamples > monoAudio.length) {
      durationSamples = monoAudio.length - startSample;
    }
    
    List<double> y = monoAudio.sublist(startSample, startSample + durationSamples);
    
    // 3. Compute MFCC using custom LibrosaMfcc
    final extractor = LibrosaMfcc(
      sr: sr,
      nFft: 2048,
      hopLength: 512,
      nMels: 128,
      nMfcc: 40,
    );
    
    List<List<double>> mfccs = extractor.computeMfcc(y);
    
    // 4. Compute mean across time
    List<double> mfccMean = List.filled(40, 0.0);
    int numFrames = mfccs.length;
    for (int t = 0; t < numFrames; t++) {
      for (int i = 0; i < 40; i++) {
        mfccMean[i] += mfccs[t][i];
      }
    }
    for (int i = 0; i < 40; i++) {
      mfccMean[i] /= numFrames;
    }

    // 5. Run inference
    return await _tfliteService.predict(mfccMean);
  }
}
