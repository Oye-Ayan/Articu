#!/usr/bin/env python3
"""
ArticuliCare - Phase 2: Embedded Graph Front-End & Pediatric Acoustic Architecture
Builds and exports an on-device speech disorder screening model with:
- Pure TFLITE_BUILTINS STFT via DFT-Convolution (Zero SELECT_TF_OPS / Flex ops)
- Pediatric acoustic tuning (16kHz, 512 N_fft, 256 hop, 64 Mel bins: 80Hz - 7600Hz)
- Deterministic window padding: exactly 187 temporal frames [1, 187, 64, 1]
- MobileNet-style Depthwise-Separable 2D CNN
- Float16 Post-Training Quantization (Preserves DFT basis precision without -48dB noise)
"""

import os
import numpy as np
import tensorflow as tf
from tensorflow.keras import layers, models

# ---------------------------------------------------------------------------
# Pediatric Acoustic Hyperparameters
# ---------------------------------------------------------------------------
SAMPLE_RATE = 16000
INPUT_SAMPLES = 48000       # 3.0 seconds @ 16kHz
N_FFT = 512                 # 32 ms window
HOP_LENGTH = 256            # 16 ms hop
NUM_MEL_BINS = 64
F_MIN = 80.0
F_MAX = 7600.0
PAD_SAMPLES = 128           # 48000 + 128 = 48128 -> (48128 - 512)//256 + 1 = 187 frames
NUM_FRAMES = 187
NUM_CLASSES = 2             # 0: Typical articulation, 1: Speech Sound Disorder


def create_dft_kernels(n_fft=N_FFT):
    """
    Constructs fixed real (cosine) and imaginary (sine) basis kernels
    modulated with a periodic Hann window.
    Shape: (n_fft, 1, 1, num_spectrogram_bins = n_fft // 2 + 1 = 257)
    """
    num_bins = n_fft // 2 + 1
    # Periodic Hann window: w[n] = 0.5 - 0.5 * cos(2 * pi * n / n_fft)
    n = np.arange(n_fft, dtype=np.float32)
    window = 0.5 - 0.5 * np.cos(2.0 * np.pi * n / n_fft)

    # Basis matrices
    real_kernel = np.zeros((n_fft, num_bins), dtype=np.float32)
    imag_kernel = np.zeros((n_fft, num_bins), dtype=np.float32)

    for k in range(num_bins):
        angle = 2.0 * np.pi * k * n / n_fft
        real_kernel[:, k] = window * np.cos(angle)
        imag_kernel[:, k] = -window * np.sin(angle)

    # Reshape for Conv2D: (height=n_fft, width=1, in_channels=1, out_channels=num_bins)
    real_kernel_2d = real_kernel.reshape((n_fft, 1, 1, num_bins))
    imag_kernel_2d = imag_kernel.reshape((n_fft, 1, 1, num_bins))
    return real_kernel_2d, imag_kernel_2d


def create_mel_matrix(sample_rate=SAMPLE_RATE, n_fft=N_FFT, num_mel_bins=NUM_MEL_BINS, f_min=F_MIN, f_max=F_MAX):
    """
    Creates a Slaney-normalized triangular Mel filterbank matrix of shape (257, 64).
    Reshapes to (1, 1, 257, 64) for direct 1x1 Conv2D projection in TFLite.
    """
    num_bins = n_fft // 2 + 1
    fft_freqs = np.linspace(0.0, sample_rate / 2.0, num_bins, dtype=np.float32)

    # Convert Hz to Mel (Slaney / HTK)
    def hz_to_mel(hz):
        return 2595.0 * np.log10(1.0 + hz / 700.0)

    def mel_to_hz(mel):
        return 700.0 * (10.0 ** (mel / 2595.0) - 1.0)

    min_mel = hz_to_mel(f_min)
    max_mel = hz_to_mel(f_max)
    mel_points = np.linspace(min_mel, max_mel, num_mel_bins + 2)
    hz_points = mel_to_hz(mel_points)

    mel_weights = np.zeros((num_bins, num_mel_bins), dtype=np.float32)

    for i in range(num_mel_bins):
        left = hz_points[i]
        center = hz_points[i + 1]
        right = hz_points[i + 2]

        # Triangular filter
        for j in range(num_bins):
            freq = fft_freqs[j]
            if left <= freq <= center:
                mel_weights[j, i] = (freq - left) / (center - left)
            elif center < freq <= right:
                mel_weights[j, i] = (right - freq) / (right - center)

        # Slaney area normalization
        band_width = right - left
        if band_width > 0:
            mel_weights[:, i] *= (2.0 / band_width)

    # Reshape for 1x1 Conv2D: (kernel_h=1, kernel_w=1, in_channels=257, out_channels=64)
    return mel_weights.reshape((1, 1, num_bins, num_mel_bins))


class EmbeddedDftMelSpectrogram(layers.Layer):
    """
    Pure TFLITE_BUILTINS Audio Front-End.
    Executes STFT and Mel-spectrogram projection using only Conv2D, Square, Add, and Log.
    Produces deterministic output shape: [Batch, 187, 64, 1].
    """
    def __init__(self, **kwargs):
        super(EmbeddedDftMelSpectrogram, self).__init__(**kwargs)

        real_kernel, imag_kernel = create_dft_kernels(N_FFT)
        mel_matrix = create_mel_matrix(SAMPLE_RATE, N_FFT, NUM_MEL_BINS, F_MIN, F_MAX)

        # Fixed, non-trainable constant filter tensors
        self.real_kernel = tf.constant(real_kernel, dtype=tf.float32)
        self.imag_kernel = tf.constant(imag_kernel, dtype=tf.float32)
        self.mel_kernel = tf.constant(mel_matrix, dtype=tf.float32)

    def call(self, raw_audio):
        # 1. Deterministic Padding: 48,000 -> 48,128 samples
        # Guarantees exactly NUM_FRAMES = 187 frames with valid 512 kernel and 256 stride
        padded_audio = tf.pad(raw_audio, [[0, 0], [0, PAD_SAMPLES]])

        # 2. Reshape to 4D for 2D Convolutions: [Batch, Time=48128, Width=1, Channel=1]
        x = tf.reshape(padded_audio, [-1, INPUT_SAMPLES + PAD_SAMPLES, 1, 1])

        # 3. DFT Convolutions -> [Batch, 187, 1, 257]
        real_stft = tf.nn.conv2d(x, self.real_kernel, strides=[1, HOP_LENGTH, 1, 1], padding="VALID")
        imag_stft = tf.nn.conv2d(x, self.imag_kernel, strides=[1, HOP_LENGTH, 1, 1], padding="VALID")

        # 4. Power Spectrogram = Real^2 + Imag^2
        power_spec = tf.math.square(real_stft) + tf.math.square(imag_stft)

        # 5. Mel Projection via 1x1 Conv2D -> [Batch, 187, 1, 64]
        mel_spec = tf.nn.conv2d(power_spec, self.mel_kernel, strides=[1, 1, 1, 1], padding="VALID")

        # 6. Log Compression: ln(mel_spec + 1e-5)
        log_mel = tf.math.log(mel_spec + 1e-5)

        # 7. Reshape to standard 2D feature map [Batch, 187, 64, 1] for CNN processing
        out = tf.reshape(log_mel, [-1, NUM_FRAMES, NUM_MEL_BINS, 1])
        return out


def build_articuli_care_model():
    """
    Constructs end-to-end model with embedded DFT-Mel front-end
    and depthwise-separable 2D CNN acoustic classifier.
    """
    inputs = layers.Input(shape=(INPUT_SAMPLES,), dtype=tf.float32, name="audio_pcm")

    # Front-end: [B, 48000] -> [B, 187, 64, 1]
    spec = EmbeddedDftMelSpectrogram(name="dft_mel_frontend")(inputs)

    # Stem: 3x3 Conv with stride 2 -> [B, 94, 32, 32]
    x = layers.Conv2D(32, (3, 3), strides=(2, 2), padding="same", activation="relu")(spec)
    x = layers.BatchNormalization()(x)

    # Block 1: SeparableConv -> [B, 47, 16, 64]
    x = layers.SeparableConv2D(64, (3, 3), padding="same", activation="relu")(x)
    x = layers.BatchNormalization()(x)
    x = layers.MaxPooling2D((2, 2))(x)
    x = layers.Dropout(0.2)(x)

    # Block 2: SeparableConv -> [B, 23, 8, 128]
    x = layers.SeparableConv2D(128, (3, 3), padding="same", activation="relu")(x)
    x = layers.BatchNormalization()(x)
    x = layers.MaxPooling2D((2, 2))(x)
    x = layers.Dropout(0.25)(x)

    # Temporal Feature Aggregation
    x = layers.GlobalAveragePooling2D()(x)
    x = layers.Dense(64, activation="relu")(x)
    x = layers.Dropout(0.3)(x)
    outputs = layers.Dense(NUM_CLASSES, activation="softmax", name="probabilities")(x)

    model = models.Model(inputs=inputs, outputs=outputs, name="articuli_care_v2")
    return model


def export_fp16_tflite(model, output_path):
    """
    Exports model to TFLite with Float16 quantization and fixed input signature.
    Guarantees pure TFLITE_BUILTINS and preserves STFT basis numerical precision.
    """
    os.makedirs(os.path.dirname(output_path), exist_ok=True)

    # Fixed signature
    run_model = tf.function(lambda x: model(x))
    concrete_func = run_model.get_concrete_function(
        tf.TensorSpec([1, INPUT_SAMPLES], tf.float32, name="audio_pcm")
    )

    converter = tf.lite.TFLiteConverter.from_concrete_functions([concrete_func])

    # Float16 Quantization: Prevents -48dB INT8 quantization noise on DFT basis
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    converter.target_spec.supported_types = [tf.float16]
    converter.target_spec.supported_ops = [tf.lite.OpsSet.TFLITE_BUILTINS]

    tflite_model = converter.convert()

    with open(output_path, "wb") as f:
        f.write(tflite_model)

    size_kb = len(tflite_model) / 1024.0
    print(f"\nModel exported to: {output_path}")
    print(f"Binary Footprint: {size_kb:.2f} KB (Target: < 400 KB)")
    return output_path


if __name__ == "__main__":
    print("Building ArticuliCare Embedded Audio Architecture...")
    model = build_articuli_care_model()
    model.summary()

    output_tflite_path = "assets/models/articuli_care_v2.tflite"
    export_fp16_tflite(model, output_tflite_path)
