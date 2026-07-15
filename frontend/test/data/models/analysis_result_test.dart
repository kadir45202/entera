import 'dart:convert';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:entera/data/models/analysis_result.dart';

void main() {
  group('AnalysisResult', () {
    // Feature: health-insights-analysis, Property 3: JSON Parsing Round-Trip
    // Validates: Requirements 4.2
    test('Property: JSON round-trip preserves all fields', () {
      final random = Random(42); // Fixed seed for reproducibility
      const iterations = 100;

      for (int i = 0; i < iterations; i++) {
        // Generate random valid AnalysisResult
        final original = _generateRandomAnalysisResult(random);

        // Convert to JSON and back
        final json = original.toJson();
        final jsonString = jsonEncode(json);
        final decodedJson = jsonDecode(jsonString) as Map<String, dynamic>;
        final roundTripped = AnalysisResult.fromJson(decodedJson);

        // Verify all fields are preserved
        expect(roundTripped.score, equals(original.score),
            reason: 'Score should be preserved in round-trip');
        expect(roundTripped.status, equals(original.status),
            reason: 'Status should be preserved in round-trip');
        expect(roundTripped.summary, equals(original.summary),
            reason: 'Summary should be preserved in round-trip');
        expect(roundTripped.positives, equals(original.positives),
            reason: 'Positives should be preserved in round-trip');
        expect(roundTripped.negatives, equals(original.negatives),
            reason: 'Negatives should be preserved in round-trip');
        expect(roundTripped.recommendations, equals(original.recommendations),
            reason: 'Recommendations should be preserved in round-trip');

        // Verify using equality operator
        expect(roundTripped, equals(original),
            reason: 'Round-tripped object should equal original');
      }
    });

    group('Score validation', () {
      // Requirements: 4.4
      test('accepts valid score at lower boundary (0)', () {
        final result = AnalysisResult(
          score: 0,
          status: 'poor',
          summary: 'Test',
          positives: [],
          negatives: [],
          recommendations: ['Test'],
        );
        expect(result.score, equals(0));
      });

      test('accepts valid score at upper boundary (100)', () {
        final result = AnalysisResult(
          score: 100,
          status: 'excellent',
          summary: 'Test',
          positives: [],
          negatives: [],
          recommendations: ['Test'],
        );
        expect(result.score, equals(100));
      });

      test('accepts valid score in middle range (50)', () {
        final result = AnalysisResult(
          score: 50,
          status: 'fair',
          summary: 'Test',
          positives: [],
          negatives: [],
          recommendations: ['Test'],
        );
        expect(result.score, equals(50));
      });

      test('rejects score below 0', () {
        expect(
          () => AnalysisResult(
            score: -1,
            status: 'poor',
            summary: 'Test',
            positives: [],
            negatives: [],
            recommendations: ['Test'],
          ),
          throwsA(isA<RangeError>()),
        );
      });

      test('rejects score above 100', () {
        expect(
          () => AnalysisResult(
            score: 101,
            status: 'excellent',
            summary: 'Test',
            positives: [],
            negatives: [],
            recommendations: ['Test'],
          ),
          throwsA(isA<RangeError>()),
        );
      });

      test('fromJson rejects invalid score type', () {
        expect(
          () => AnalysisResult.fromJson({
            'score': 'not a number',
            'status': 'good',
            'summary': 'Test',
            'positives': [],
            'negatives': [],
            'recommendations': ['Test'],
          }),
          throwsA(isA<FormatException>()),
        );
      });
    });

    group('Status validation', () {
      // Requirements: 4.5
      test('accepts "excellent" status', () {
        final result = AnalysisResult(
          score: 90,
          status: 'excellent',
          summary: 'Test',
          positives: [],
          negatives: [],
          recommendations: ['Test'],
        );
        expect(result.status, equals('excellent'));
      });

      test('accepts "good" status', () {
        final result = AnalysisResult(
          score: 70,
          status: 'good',
          summary: 'Test',
          positives: [],
          negatives: [],
          recommendations: ['Test'],
        );
        expect(result.status, equals('good'));
      });

      test('accepts "fair" status', () {
        final result = AnalysisResult(
          score: 50,
          status: 'fair',
          summary: 'Test',
          positives: [],
          negatives: [],
          recommendations: ['Test'],
        );
        expect(result.status, equals('fair'));
      });

      test('accepts "poor" status', () {
        final result = AnalysisResult(
          score: 30,
          status: 'poor',
          summary: 'Test',
          positives: [],
          negatives: [],
          recommendations: ['Test'],
        );
        expect(result.status, equals('poor'));
      });

      test('rejects invalid status', () {
        expect(
          () => AnalysisResult(
            score: 50,
            status: 'invalid',
            summary: 'Test',
            positives: [],
            negatives: [],
            recommendations: ['Test'],
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('fromJson rejects invalid status type', () {
        expect(
          () => AnalysisResult.fromJson({
            'score': 50,
            'status': 123,
            'summary': 'Test',
            'positives': [],
            'negatives': [],
            'recommendations': ['Test'],
          }),
          throwsA(isA<FormatException>()),
        );
      });
    });

    group('JSON parsing edge cases', () {
      // Requirements: 4.4, 4.5
      test('fromJson throws on missing score field', () {
        expect(
          () => AnalysisResult.fromJson({
            'status': 'good',
            'summary': 'Test',
            'positives': [],
            'negatives': [],
            'recommendations': ['Test'],
          }),
          throwsA(isA<FormatException>()),
        );
      });

      test('fromJson throws on missing status field', () {
        expect(
          () => AnalysisResult.fromJson({
            'score': 50,
            'summary': 'Test',
            'positives': [],
            'negatives': [],
            'recommendations': ['Test'],
          }),
          throwsA(isA<FormatException>()),
        );
      });

      test('fromJson throws on missing summary field', () {
        expect(
          () => AnalysisResult.fromJson({
            'score': 50,
            'status': 'good',
            'positives': [],
            'negatives': [],
            'recommendations': ['Test'],
          }),
          throwsA(isA<FormatException>()),
        );
      });

      test('fromJson throws on missing positives field', () {
        expect(
          () => AnalysisResult.fromJson({
            'score': 50,
            'status': 'good',
            'summary': 'Test',
            'negatives': [],
            'recommendations': ['Test'],
          }),
          throwsA(isA<FormatException>()),
        );
      });

      test('fromJson throws on missing negatives field', () {
        expect(
          () => AnalysisResult.fromJson({
            'score': 50,
            'status': 'good',
            'summary': 'Test',
            'positives': [],
            'recommendations': ['Test'],
          }),
          throwsA(isA<FormatException>()),
        );
      });

      test('fromJson throws on missing recommendations field', () {
        expect(
          () => AnalysisResult.fromJson({
            'score': 50,
            'status': 'good',
            'summary': 'Test',
            'positives': [],
            'negatives': [],
          }),
          throwsA(isA<FormatException>()),
        );
      });

      test('fromJson handles empty lists', () {
        final result = AnalysisResult.fromJson({
          'score': 50,
          'status': 'fair',
          'summary': 'Test summary',
          'positives': [],
          'negatives': [],
          'recommendations': ['At least one recommendation'],
        });
        expect(result.positives, isEmpty);
        expect(result.negatives, isEmpty);
        expect(result.recommendations, hasLength(1));
      });

      test('fromJson converts list items to strings', () {
        final result = AnalysisResult.fromJson({
          'score': 50,
          'status': 'fair',
          'summary': 'Test summary',
          'positives': ['Good behavior', 123, true],
          'negatives': ['Bad behavior'],
          'recommendations': ['Recommendation'],
        });
        expect(result.positives, equals(['Good behavior', '123', 'true']));
      });
    });

    group('toJson', () {
      test('produces valid JSON structure', () {
        final result = AnalysisResult(
          score: 75,
          status: 'good',
          summary: 'Test summary',
          positives: ['Positive 1', 'Positive 2'],
          negatives: ['Negative 1'],
          recommendations: ['Rec 1', 'Rec 2', 'Rec 3'],
        );

        final json = result.toJson();

        expect(json['score'], equals(75));
        expect(json['status'], equals('good'));
        expect(json['summary'], equals('Test summary'));
        expect(json['positives'], equals(['Positive 1', 'Positive 2']));
        expect(json['negatives'], equals(['Negative 1']));
        expect(json['recommendations'], equals(['Rec 1', 'Rec 2', 'Rec 3']));
      });
    });

    group('Equality', () {
      test('equal objects are equal', () {
        final result1 = AnalysisResult(
          score: 75,
          status: 'good',
          summary: 'Test',
          positives: ['A', 'B'],
          negatives: ['C'],
          recommendations: ['D'],
        );

        final result2 = AnalysisResult(
          score: 75,
          status: 'good',
          summary: 'Test',
          positives: ['A', 'B'],
          negatives: ['C'],
          recommendations: ['D'],
        );

        expect(result1, equals(result2));
        expect(result1.hashCode, equals(result2.hashCode));
      });

      test('different objects are not equal', () {
        final result1 = AnalysisResult(
          score: 75,
          status: 'good',
          summary: 'Test',
          positives: ['A'],
          negatives: [],
          recommendations: ['D'],
        );

        final result2 = AnalysisResult(
          score: 76,
          status: 'good',
          summary: 'Test',
          positives: ['A'],
          negatives: [],
          recommendations: ['D'],
        );

        expect(result1, isNot(equals(result2)));
      });
    });
  });
}

/// Generate a random valid AnalysisResult for property testing
AnalysisResult _generateRandomAnalysisResult(Random random) {
  // Generate random score (0-100)
  final score = random.nextInt(101);

  // Generate random valid status
  const validStatuses = ['excellent', 'good', 'fair', 'poor'];
  final status = validStatuses[random.nextInt(validStatuses.length)];

  // Generate random summary
  final summary = _generateRandomString(random, 50, 200);

  // Generate random lists
  final positives = _generateRandomStringList(random, 0, 5);
  final negatives = _generateRandomStringList(random, 0, 5);
  final recommendations = _generateRandomStringList(random, 1, 5);

  return AnalysisResult(
    score: score,
    status: status,
    summary: summary,
    positives: positives,
    negatives: negatives,
    recommendations: recommendations,
  );
}

/// Generate a random string of given length range
String _generateRandomString(Random random, int minLength, int maxLength) {
  final length = minLength + random.nextInt(maxLength - minLength + 1);
  const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 .,!?';
  return List.generate(length, (_) => chars[random.nextInt(chars.length)]).join();
}

/// Generate a random list of strings
List<String> _generateRandomStringList(Random random, int minItems, int maxItems) {
  final count = minItems + random.nextInt(maxItems - minItems + 1);
  return List.generate(count, (_) => _generateRandomString(random, 10, 50));
}
