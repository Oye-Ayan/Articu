import 'dart:math';
import 'package:fftea/fftea.dart';
import 'dart:typed_data';

class LibrosaMfcc {
  final int sr;
  final int nFft;
  final int hopLength;
  final int nMels;
  final int nMfcc;
  final double fMin;
  final double fMax;

  late final List<double> _window;
  late final List<List<double>> _melBasis;

  LibrosaMfcc({
    this.sr = 16000,
    this.nFft = 2048,
    this.hopLength = 512,
    this.nMels = 128,
    this.nMfcc = 40,
    this.fMin = 0.0,
    double? fMax,
  }) : fMax = fMax ?? (sr / 2.0) {
    _initWindow();
    _initMelBasis();
  }

  void _initWindow() {
    _window = List<double>.filled(nFft, 0.0);
    for (int i = 0; i < nFft; i++) {
      // Periodic Hann window (fftbins=True)
      _window[i] = 0.5 - 0.5 * cos(2.0 * pi * i / nFft);
    }
  }

  double _hzToMel(double freq) {
    final double fMinSlaney = 0.0;
    final double fSp = 200.0 / 3.0;
    final double minLogHz = 1000.0;
    final double minLogMel = (minLogHz - fMinSlaney) / fSp;
    final double logStep = log(6.4) / 27.0;

    if (freq >= minLogHz) {
      return minLogMel + log(freq / minLogHz) / logStep;
    } else {
      return (freq - fMinSlaney) / fSp;
    }
  }

  double _melToHz(double mel) {
    final double fMinSlaney = 0.0;
    final double fSp = 200.0 / 3.0;
    final double minLogHz = 1000.0;
    final double minLogMel = (minLogHz - fMinSlaney) / fSp;
    final double logStep = log(6.4) / 27.0;

    if (mel >= minLogMel) {
      return minLogHz * exp(logStep * (mel - minLogMel));
    } else {
      return fMinSlaney + fSp * mel;
    }
  }

  void _initMelBasis() {
    final double minMel = _hzToMel(fMin);
    final double maxMel = _hzToMel(fMax);
    final List<double> melF = List<double>.filled(nMels + 2, 0.0);
    
    for (int i = 0; i < nMels + 2; i++) {
      double m = minMel + (maxMel - minMel) * i / (nMels + 1);
      melF[i] = _melToHz(m);
    }

    final int nFftBins = (nFft ~/ 2) + 1;
    final List<double> fftFreqs = List<double>.filled(nFftBins, 0.0);
    for (int i = 0; i < nFftBins; i++) {
      fftFreqs[i] = i * sr / nFft;
    }

    final List<double> fDiff = List<double>.filled(nMels + 1, 0.0);
    for (int i = 0; i < nMels + 1; i++) {
      fDiff[i] = melF[i + 1] - melF[i];
    }

    _melBasis = List.generate(nMels, (_) => List<double>.filled(nFftBins, 0.0));
    
    for (int i = 0; i < nMels; i++) {
      for (int j = 0; j < nFftBins; j++) {
        double lower = (fftFreqs[j] - melF[i]) / fDiff[i];
        double upper = (melF[i + 2] - fftFreqs[j]) / fDiff[i + 1];
        double weight = max(0.0, min(lower, upper));
        
        // Slaney normalization
        double enorm = 2.0 / (melF[i + 2] - melF[i]);
        _melBasis[i][j] = weight * enorm;
      }
    }
  }

  List<double> padReflect(List<double> y, int padLen) {
    if (y.isEmpty) return [];
    
    List<double> padded = List<double>.filled(y.length + 2 * padLen, 0.0);
    
    // Copy original
    for (int i = 0; i < y.length; i++) {
      padded[padLen + i] = y[i];
    }
    
    // Left pad
    for (int i = 0; i < padLen; i++) {
      int idx = i + 1;
      if (idx >= y.length) idx = y.length - 1; // handle edge cases safely
      padded[padLen - 1 - i] = y[idx];
    }
    
    // Right pad
    for (int i = 0; i < padLen; i++) {
      int idx = y.length - 2 - i;
      if (idx < 0) idx = 0;
      padded[padLen + y.length + i] = y[idx];
    }
    
    return padded;
  }

  List<List<double>> _powerToDb(List<List<double>> S, {double amin = 1e-10, double topDb = 80.0}) {
    List<List<double>> logSpec = List.generate(S.length, (_) => List<double>.filled(S[0].length, 0.0));
    double maxVal = -double.infinity;

    for (int i = 0; i < S.length; i++) {
      for (int j = 0; j < S[i].length; j++) {
        double val = 10.0 * log(max(amin, S[i][j])) / ln10;
        logSpec[i][j] = val;
        if (val > maxVal) maxVal = val;
      }
    }

    if (topDb > 0) {
      for (int i = 0; i < logSpec.length; i++) {
        for (int j = 0; j < logSpec[i].length; j++) {
          if (logSpec[i][j] < maxVal - topDb) {
            logSpec[i][j] = maxVal - topDb;
          }
        }
      }
    }
    return logSpec;
  }

  List<double> _dct2Ortho(List<double> x, int numCoefs) {
    int N = x.length;
    List<double> result = List<double>.filled(numCoefs, 0.0);
    double factor0 = sqrt(1.0 / (4.0 * N));
    double factor = sqrt(1.0 / (2.0 * N));

    for (int k = 0; k < numCoefs; k++) {
      double sum = 0.0;
      for (int n = 0; n < N; n++) {
        sum += x[n] * cos(pi * k * (2.0 * n + 1.0) / (2.0 * N));
      }
      sum *= 2.0;
      
      if (k == 0) {
        result[k] = sum * factor0;
      } else {
        result[k] = sum * factor;
      }
    }
    return result;
  }

  List<List<double>> computeMfcc(List<double> y) {
    // 1. Pad audio
    List<double> yPadded = padReflect(y, nFft ~/ 2);
    
    // 2. Compute frames and STFT
    final fft = FFT(nFft);
    int numFrames = 1 + (y.length ~/ hopLength);
    int nFftBins = (nFft ~/ 2) + 1;
    
    // S[time][freq]
    List<List<double>> powerSpec = List.generate(numFrames, (_) => List<double>.filled(nFftBins, 0.0));
    
    for (int i = 0; i < numFrames; i++) {
      int start = i * hopLength;
      Float64x2List frame = Float64x2List(nFft);
      
      for (int j = 0; j < nFft; j++) {
        double val = yPadded[start + j] * _window[j];
        frame[j] = Float64x2(val, 0.0);
      }
      
      fft.inPlaceFft(frame);
      
      for (int j = 0; j < nFftBins; j++) {
        double real = frame[j].x;
        double imag = frame[j].y;
        powerSpec[i][j] = real * real + imag * imag;
      }
    }

    // 3. Mel Transform
    // melSpec[time][mel]
    List<List<double>> melSpec = List.generate(numFrames, (_) => List<double>.filled(nMels, 0.0));
    for (int t = 0; t < numFrames; t++) {
      for (int m = 0; m < nMels; m++) {
        double sum = 0.0;
        for (int j = 0; j < nFftBins; j++) {
          sum += powerSpec[t][j] * _melBasis[m][j];
        }
        melSpec[t][m] = sum;
      }
    }

    // 4. Power to DB
    List<List<double>> logMelSpec = _powerToDb(melSpec);

    // 5. DCT-II Ortho
    List<List<double>> mfcc = List.generate(numFrames, (_) => List<double>.filled(nMfcc, 0.0));
    for (int t = 0; t < numFrames; t++) {
      mfcc[t] = _dct2Ortho(logMelSpec[t], nMfcc);
    }

    return mfcc;
  }
}
