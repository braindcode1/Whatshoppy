import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class LocalAiPrediction {
  const LocalAiPrediction({
    required this.category,
    required this.confidence,
    required this.scores,
    required this.normalization,
  });

  final String category;
  final double confidence;
  final List<double> scores;
  final String normalization;
}

class LocalAiService {
  static Interpreter? _interpreter;
  static List<String> _classNames = [];
  static const int _inputSize = 224;

  static Future<void> loadModel() async {
    _interpreter ??= await Interpreter.fromAsset(
      'assets/model/whatshoppy_category_model.tflite',
    );

    final labelsJson = await rootBundle.loadString(
      'assets/model/class_names.json',
    );

    _classNames = List<String>.from(jsonDecode(labelsJson));

    final inputTensor = _interpreter!.getInputTensor(0);
    final outputTensor = _interpreter!.getOutputTensor(0);

    debugPrint('Local AI input tensor shape: ${inputTensor.shape}');
    debugPrint('Local AI input tensor type: ${inputTensor.type}');
    debugPrint('Local AI output tensor shape: ${outputTensor.shape}');
    debugPrint('Local AI output tensor type: ${outputTensor.type}');
    debugPrint('Local AI class names: $_classNames');
  }

  static Future<LocalAiPrediction> predictCategory(File imageFile) async {
    await loadModel();

    final bytes = await imageFile.readAsBytes();
    final originalImage = img.decodeImage(bytes);

    if (originalImage == null) {
      throw Exception('Invalid image');
    }

    final resizedImage = img.copyResize(
      originalImage,
      width: _inputSize,
      height: _inputSize,
      interpolation: img.Interpolation.linear,
    );

    final bestPrediction = _runPrediction(
      resizedImage,
      normalization: 'EfficientNet raw RGB 0..255',
      normalize: (value) => value.toDouble(),
    );

    debugPrint(
      'Local AI selected normalization: ${bestPrediction.normalization}',
    );

    return bestPrediction;
  }

  static LocalAiPrediction _runPrediction(
    img.Image image, {
    required String normalization,
    required double Function(num value) normalize,
  }) {
    final input = List.generate(
      1,
      (_) => List.generate(
        _inputSize,
        (y) => List.generate(_inputSize, (x) {
          final pixel = image.getPixel(x, y);

          return <double>[
            normalize(pixel.r.toDouble()),
            normalize(pixel.g.toDouble()),
            normalize(pixel.b.toDouble()),
          ];
        }),
      ),
    );

    final outputLength = _interpreter!.getOutputTensor(0).shape.last;
    final output = List.generate(1, (_) => List.filled(outputLength, 0.0));

    _interpreter!.run(input, output);

    final scores = output[0].cast<double>();
    int bestIndex = 0;

    for (int i = 1; i < scores.length; i++) {
      if (scores[i] > scores[bestIndex]) {
        bestIndex = i;
      }
    }

    final category = _classNames.length > bestIndex
        ? _classNames[bestIndex]
        : 'unknown';

    final confidence = _confidenceForIndex(scores, bestIndex);

    debugPrint('Local AI normalization: $normalization');
    debugPrint('Local AI output scores: $scores');
    debugPrint('Local AI prediction: $category ($confidence)');
    debugPrint('Local AI class names: $_classNames');

    return LocalAiPrediction(
      category: category,
      confidence: confidence,
      scores: scores,
      normalization: normalization,
    );
  }

  static double _confidenceForIndex(List<double> scores, int index) {
    final sum = scores.fold<double>(0, (total, score) => total + score);

    final looksLikeProbabilities =
        scores.every((score) => score >= 0 && score <= 1) &&
        sum > 0.98 &&
        sum < 1.02;

    if (looksLikeProbabilities) {
      return scores[index];
    }

    final maxScore = scores.reduce((a, b) => a > b ? a : b);

    final expScores = scores
        .map((score) => math.exp(score - maxScore))
        .toList(growable: false);

    final expSum = expScores.fold<double>(0, (total, score) => total + score);

    return expScores[index] / expSum;
  }
}