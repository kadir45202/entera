/// Health analysis result model with JSON serialization
class AnalysisResult {
  final int score;
  final String status; // excellent, good, fair, poor
  final String summary;
  final List<String> positives;
  final List<String> negatives;
  final List<String> recommendations;

  AnalysisResult({
    required this.score,
    required this.status,
    required this.summary,
    required this.positives,
    required this.negatives,
    required this.recommendations,
  }) {
    // Validate score range (0-100)
    if (score < 0 || score > 100) {
      throw RangeError('Score must be between 0 and 100, got: $score');
    }

    // Validate status enum
    const validStatuses = ['excellent', 'good', 'fair', 'poor'];
    if (!validStatuses.contains(status)) {
      throw ArgumentError(
          'Status must be one of $validStatuses, got: $status');
    }
  }

  /// Create AnalysisResult from JSON with validation
  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    // Validate required fields exist
    if (!json.containsKey('score')) {
      throw FormatException('Missing required field: score');
    }
    if (!json.containsKey('status')) {
      throw FormatException('Missing required field: status');
    }
    if (!json.containsKey('summary')) {
      throw FormatException('Missing required field: summary');
    }
    if (!json.containsKey('positives')) {
      throw FormatException('Missing required field: positives');
    }
    if (!json.containsKey('negatives')) {
      throw FormatException('Missing required field: negatives');
    }
    if (!json.containsKey('recommendations')) {
      throw FormatException('Missing required field: recommendations');
    }

    // Parse and validate score
    final score = json['score'];
    if (score is! int) {
      throw FormatException('Score must be an integer, got: ${score.runtimeType}');
    }

    // Parse and validate status
    final status = json['status'];
    if (status is! String) {
      throw FormatException('Status must be a string, got: ${status.runtimeType}');
    }

    // Parse summary
    final summary = json['summary'];
    if (summary is! String) {
      throw FormatException('Summary must be a string, got: ${summary.runtimeType}');
    }

    // Parse lists
    final positives = json['positives'];
    if (positives is! List) {
      throw FormatException('Positives must be a list, got: ${positives.runtimeType}');
    }

    final negatives = json['negatives'];
    if (negatives is! List) {
      throw FormatException('Negatives must be a list, got: ${negatives.runtimeType}');
    }

    final recommendations = json['recommendations'];
    if (recommendations is! List) {
      throw FormatException('Recommendations must be a list, got: ${recommendations.runtimeType}');
    }

    return AnalysisResult(
      score: score,
      status: status,
      summary: summary,
      positives: List<String>.from(positives.map((e) => e.toString())),
      negatives: List<String>.from(negatives.map((e) => e.toString())),
      recommendations: List<String>.from(recommendations.map((e) => e.toString())),
    );
  }

  /// Convert AnalysisResult to JSON
  Map<String, dynamic> toJson() {
    return {
      'score': score,
      'status': status,
      'summary': summary,
      'positives': positives,
      'negatives': negatives,
      'recommendations': recommendations,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AnalysisResult) return false;

    return score == other.score &&
        status == other.status &&
        summary == other.summary &&
        _listEquals(positives, other.positives) &&
        _listEquals(negatives, other.negatives) &&
        _listEquals(recommendations, other.recommendations);
  }

  @override
  int get hashCode {
    return Object.hash(
      score,
      status,
      summary,
      Object.hashAll(positives),
      Object.hashAll(negatives),
      Object.hashAll(recommendations),
    );
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
