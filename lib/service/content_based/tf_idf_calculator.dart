import 'dart:math';

class TfIdfCalculator {
  Map<String, double> computeTFIDFVector(
      String document, List<String> allDocuments) {
    final Map<String, int> termFrequency = _computeTermFrequency(document);
    final Map<String, double> tfidfVector = {};

    for (var term in termFrequency.keys) {
      double tf = termFrequency[term]!.toDouble();
      double idf = _computeIDF(term, allDocuments);
      tfidfVector[term] = tf * idf;
    }

    return tfidfVector;
  }

  Map<String, int> _computeTermFrequency(String document) {
    final Map<String, int> frequency = {};
    final terms = document.split(RegExp(r'\s+'));

    for (var term in terms) {
      term = term.toLowerCase();
      if (frequency.containsKey(term)) {
        frequency[term] = frequency[term]! + 1;
      } else {
        frequency[term] = 1;
      }
    }

    return frequency;
  }

  double _computeIDF(String term, List<String> allDocuments) {
    double documentCountWithTerm = 0;
    for (var doc in allDocuments) {
      if (doc.contains(term)) {
        documentCountWithTerm++;
      }
    }

    return documentCountWithTerm == 0
        ? 0
        : log(allDocuments.length / documentCountWithTerm);
  }
}
