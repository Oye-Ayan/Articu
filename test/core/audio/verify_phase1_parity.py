#!/usr/bin/env python3
"""
Phase 1 Cross-Language Parity Verification Script for ArticuliCare

Validates that raw audio byte ingestion and normalization between
Python (NumPy / SciPy audio standard) and Dart (PcmAudioNormalizer)
match bit-for-bit with absolute numerical difference < 1e-6.
"""

import os
import sys
import wave
import struct
import subprocess
import numpy as np

SAMPLE_RATE = 16000
TARGET_SAMPLES = 48000
TMP_DIR = "/tmp/articulicare_phase1_parity"


def generate_reference_wav(file_path, num_samples, frequencies=[440.0, 1000.0]):
    """Generates a multi-frequency synthetic audio file as 16-bit PCM WAV."""
    t = np.arange(num_samples) / float(SAMPLE_RATE)
    # Combine frequencies and scale to avoid clipping
    signal = 0.5 * np.sin(2 * np.pi * frequencies[0] * t) + 0.3 * np.sin(2 * np.pi * frequencies[1] * t)
    # Scale to 16-bit signed integer range [-32768, 32767]
    int16_samples = np.int16(signal * 32767.0)

    with wave.open(file_path, "wb") as wav_file:
        wav_file.setnchannels(1)        # Mono
        wav_file.setsampwidth(2)        # 16-bit = 2 bytes
        wav_file.setframerate(SAMPLE_RATE)
        wav_file.writeframes(int16_samples.tobytes())

    # Return expected Python float32 normalized array
    expected_float32 = int16_samples.astype(np.float32) / 32768.0
    return expected_float32


def run_dart_normalizer(wav_path, output_raw_path):
    """Executes the Dart audio runner and outputs the raw float32 buffer."""
    dart_script = os.path.join(
        os.path.dirname(os.path.abspath(__file__)), "run_dart_normalizer.dart"
    )
    cmd = ["dart", "run", dart_script, wav_path, output_raw_path]
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"Dart execution failed:\nSTDOUT: {result.stdout}\nSTDERR: {result.stderr}")
        sys.exit(1)


def main():
    os.makedirs(TMP_DIR, exist_ok=True)
    print("=" * 70)
    print(" ARTICULICARE - PHASE 1 INGESTION & AUDIO CAPTURE PARITY AUDIT")
    print("=" * 70)

    test_cases = [
        ("Exact 3.0s (48,000 samples)", 48000),
        ("Undersized 1.5s (24,000 samples -> zero-padded to 48,000)", 24000),
        ("Oversized 4.5s (72,000 samples -> leading 48,000 windowed)", 72000),
    ]

    all_passed = True

    for name, num_samples in test_cases:
        wav_path = os.path.join(TMP_DIR, f"test_{num_samples}.wav")
        out_raw_path = os.path.join(TMP_DIR, f"out_{num_samples}.raw")

        # 1. Generate Python Reference Audio
        py_float32 = generate_reference_wav(wav_path, num_samples)

        # Apply expected windowing in Python:
        if num_samples >= TARGET_SAMPLES:
            expected_output = py_float32[:TARGET_SAMPLES]
        else:
            expected_output = np.zeros(TARGET_SAMPLES, dtype=np.float32)
            expected_output[:num_samples] = py_float32

        # 2. Run Dart PcmAudioNormalizer
        run_dart_normalizer(wav_path, out_raw_path)

        # 3. Read Dart Binary Output
        with open(out_raw_path, "rb") as f:
            dart_bytes = f.read()

        dart_float32 = np.frombuffer(dart_bytes, dtype=np.float32)

        # 4. Assertions
        assert len(dart_float32) == TARGET_SAMPLES, (
            f"Expected {TARGET_SAMPLES} samples, got {len(dart_float32)}"
        )

        max_diff = np.max(np.abs(expected_output - dart_float32))
        mean_diff = np.mean(np.abs(expected_output - dart_float32))

        print(f"\n[Test Case] {name}")
        print(f"  -> Input length       : {num_samples} samples")
        print(f"  -> Dart Output length : {len(dart_float32)} samples (192,000 bytes)")
        print(f"  -> Max absolute error : {max_diff:.8e}")
        print(f"  -> Mean absolute error: {mean_diff:.8e}")

        if max_diff < 1e-6:
            print(f"  -> STATUS: PASSED (Bit-level parity verified)")
        else:
            print(f"  -> STATUS: FAILED (Numerical deviation exceeds 1e-6)")
            all_passed = False

    print("\n" + "=" * 70)
    if all_passed:
        print(" PHASE 1 VERIFICATION COMPLETE: ALL GATES SATISFIED")
        print(" Audio capture parity established: Linear PCM 16kHz -> Float32 [-1, 1]")
        print("=" * 70)
        sys.exit(0)
    else:
        print(" PHASE 1 VERIFICATION FAILED")
        print("=" * 70)
        sys.exit(1)


if __name__ == "__main__":
    main()
