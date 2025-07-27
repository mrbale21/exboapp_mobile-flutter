import 'dart:math';

class SimilarityCalculator {
  double computeCosineSimilarity(
      Map<String, double> vector1, Map<String, double> vector2) {
    final dotProduct = _dotProduct(vector1, vector2);
    final magnitude1 = _magnitude(vector1);
    final magnitude2 = _magnitude(vector2);

    if (magnitude1 == 0 || magnitude2 == 0) {
      return 0;
    }

    return dotProduct / (magnitude1 * magnitude2);
  }

  double _dotProduct(Map<String, double> vector1, Map<String, double> vector2) {
    double sum = 0;
    for (var term in vector1.keys) {
      if (vector2.containsKey(term)) {
        sum += vector1[term]! * vector2[term]!;
      }
    }
    return sum;
  }

  double _magnitude(Map<String, double> vector) {
    double sum = 0;
    for (var value in vector.values) {
      sum += value * value;
    }
    return sqrt(sum);
  }
}
