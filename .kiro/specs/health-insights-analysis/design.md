# Design Document: Health Insights Analysis

## Overview

The Health Insights Analysis feature provides users with AI-powered digestive health assessment based on their recent meal logs, stool reports, and symptom records. The system collects data from the last 3 days, formats it into a structured prompt for Gemini AI, receives a JSON response with health scoring and recommendations, and displays the results in an intuitive UI.

The feature is designed to work seamlessly in both guest and authenticated modes, with graceful fallbacks for error conditions.

## Architecture

### Component Structure

```
InsightsScreen (StatefulWidget)
├── State Management (Riverpod Providers)
│   ├── isAnalyzingProvider (loading state)
│   └── currentAnalysisProvider (analysis result)
├── Data Layer
│   ├── GeminiService (AI analysis)
│   ├── MealRepository (meal data)
│   ├── LogRepository (stool & symptom logs)
│   ├── AllergenRepository (user allergens)
│   └── UserProfileRepository (user profile)
└── UI Layer
    ├── Loading State
    ├── Empty State
    └── Content State (analysis results)
```

### Data Flow

1. **Initialization**: Screen opens → Auto-trigger analysis
2. **Data Collection**: Fetch meals, logs, profile from repositories
3. **Filtering**: Filter data to last 3 days (72 hours)
4. **Prompt Construction**: Format data into Turkish AI prompt
5. **AI Analysis**: Send to Gemini → Receive JSON response
6. **Parsing**: Extract and validate JSON → Create AnalysisResult
7. **Display**: Show score, insights, recommendations

## Components and Interfaces

### 1. AnalysisResult Model

```dart
class AnalysisResult {
  final int score;              // 0-100
  final String status;          // excellent, good, fair, poor
  final String summary;         // 2-3 sentence overview
  final List<String> positives; // Good behaviors
  final List<String> negatives; // Areas of concern
  final List<String> recommendations; // Actionable advice
  
  AnalysisResult({
    required this.score,
    required this.status,
    required this.summary,
    required this.positives,
    required this.negatives,
    required this.recommendations,
  });
  
  factory AnalysisResult.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
}
```

### 2. Analysis Service

```dart
class HealthAnalysisService {
  final GeminiService _gemini;
  final MealRepository _mealRepo;
  final LogRepository _logRepo;
  final AllergenRepository _allergenRepo;
  final UserProfileRepository _profileRepo;
  
  Future<AnalysisResult> performAnalysis();
  String _buildPrompt(AnalysisData data);
  AnalysisResult _parseResponse(String response);
  AnalysisResult _getMockResult();
}
```

### 3. Data Collection

```dart
class AnalysisData {
  final List<MealAnalysis> meals;
  final List<HealthLog> stoolLogs;
  final List<HealthLog> symptomLogs;
  final UserProfile? profile;
  final List<String> allergens;
  
  bool get hasData => meals.isNotEmpty || stoolLogs.isNotEmpty || symptomLogs.isNotEmpty;
}
```

### 4. UI Components

- **ScoreHero**: Circular badge with score, color, and status label
- **SummaryCard**: AI-generated summary text
- **InsightsRow**: Side-by-side positives and negatives
- **RecommendationsList**: Actionable advice cards
- **LoadingState**: Progress indicator with message
- **EmptyState**: No data message with CTA

## Data Models

### Time Window Filtering

```dart
DateTime now = DateTime.now();
DateTime cutoff = now.subtract(const Duration(days: 3));

List<T> filterByTimeWindow<T extends HasTimestamp>(List<T> items) {
  return items.where((item) => item.createdAt.isAfter(cutoff)).toList();
}
```

### Prompt Structure

```
ANALİZ İÇİN VERİLER (Son 3 Gün):

KULLANICI: {age} Yaş, {gender}
BİLİNEN ALERJİLER: {allergens}

TÜKETİLEN BESİNLER:
[{timestamp}] {meal_summary}: {ingredients} (Risk: {risk_level})
...

DIŞKI KAYITLARI (Bristol Skalası 1-7):
[{timestamp}] Tip {bristol_type} (Not: {notes})
...

SEMPTOMLAR:
[{timestamp}] {symptom_type} - Şiddet: {severity}/10 (Not: {notes})
...

GÖREV:
Bu veriler ışığında sindirim sistemi sağlığını 100 üzerinden puanla ve kişiye özel öneriler sun.

KURALLAR:
1. Puanlama (0-100):
   - 0-40: Ciddi sorunlar
   - 41-70: Orta durum
   - 71-100: İyi durum
2. SADECE JSON formatında yanıt ver.

JSON FORMATI:
{
  "score": 75,
  "status": "good",
  "summary": "...",
  "positives": ["..."],
  "negatives": ["..."],
  "recommendations": ["..."]
}
```

### JSON Parsing

```dart
AnalysisResult _parseResponse(String response) {
  try {
    // Extract JSON from potentially messy AI response
    final jsonStart = response.indexOf('{');
    final jsonEnd = response.lastIndexOf('}');
    
    if (jsonStart == -1 || jsonEnd == -1) {
      throw FormatException('No JSON found in response');
    }
    
    final jsonStr = response.substring(jsonStart, jsonEnd + 1);
    final json = jsonDecode(jsonStr);
    
    // Validate required fields
    if (!json.containsKey('score') || !json.containsKey('status')) {
      throw FormatException('Missing required fields');
    }
    
    // Validate score range
    final score = json['score'] as int;
    if (score < 0 || score > 100) {
      throw RangeError('Score must be between 0 and 100');
    }
    
    // Validate status enum
    const validStatuses = ['excellent', 'good', 'fair', 'poor'];
    if (!validStatuses.contains(json['status'])) {
      throw FormatException('Invalid status value');
    }
    
    return AnalysisResult.fromJson(json);
  } catch (e) {
    print('Parse error: $e');
    return _getMockResult();
  }
}
```

### Score-to-Color Mapping

```dart
Color getStatusColor(int score) {
  if (score >= 80) return EnteraColors.success;  // Green
  if (score >= 60) return EnteraColors.primary;  // Blue
  if (score >= 40) return EnteraColors.warning;  // Orange
  return EnteraColors.error;                      // Red
}

String getStatusLabel(int score) {
  if (score >= 80) return 'Mükemmel';
  if (score >= 60) return 'İyi Durumda';
  if (score >= 40) return 'Düzensiz';
  return 'Dikkat Gerekiyor';
}
```

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Time Window Filtering Consistency

*For any* collection of health records (meals, stool logs, symptoms) with various timestamps, when filtering by the 3-day time window, all returned records should have timestamps within the last 72 hours from the current time.

**Validates: Requirements 1.1, 1.2, 1.3**

### Property 2: Prompt Contains All Required Data

*For any* valid AnalysisData object with non-empty meals, stool logs, or symptom logs, the constructed AI prompt should contain all meal summaries, all stool log Bristol values, and all symptom types with their severity values.

**Validates: Requirements 2.2, 2.3, 2.4**

### Property 3: JSON Parsing Round-Trip

*For any* valid AnalysisResult object, converting it to JSON and then parsing it back should produce an equivalent AnalysisResult with the same score, status, summary, positives, negatives, and recommendations.

**Validates: Requirements 4.2**

### Property 4: Score Range Validation

*For any* parsed AnalysisResult, the score value should always be between 0 and 100 (inclusive).

**Validates: Requirements 4.4**

### Property 5: Status Enum Validation

*For any* parsed AnalysisResult, the status value should be one of the four valid values: "excellent", "good", "fair", or "poor".

**Validates: Requirements 4.5**

### Property 6: Score-to-Color Mapping Consistency

*For any* integer score between 0 and 100, the color mapping function should return: green for 80-100, blue for 60-79, orange for 40-59, and red for 0-39.

**Validates: Requirements 5.2**

### Property 7: Score-to-Label Mapping Consistency

*For any* integer score between 0 and 100, the label mapping function should return: "Mükemmel" for 80-100, "İyi Durumda" for 60-79, "Düzensiz" for 40-59, and "Dikkat Gerekiyor" for 0-39.

**Validates: Requirements 5.3**

### Property 8: Loading State Prevents Concurrent Analysis

*For any* analysis execution, if the loading state is true, attempting to trigger another analysis should be ignored until the current analysis completes.

**Validates: Requirements 7.3**

### Property 9: Error Handling Fallback

*For any* exception thrown during AI service call or JSON parsing, the system should catch the error and return a valid mock AnalysisResult instead of crashing.

**Validates: Requirements 8.1, 8.2**

## Error Handling

### Error Scenarios

1. **No API Key**: Display mock result with message
2. **Network Failure**: Catch exception → Display mock result
3. **Invalid JSON**: Parse error → Display mock result
4. **No Data**: Show empty state with CTA
5. **Repository Unavailable**: Catch exception → Show error message

### Fallback Strategy

```dart
try {
  // Attempt real analysis
  final response = await gemini.chat(prompt);
  final result = _parseResponse(response);
  return result;
} catch (e) {
  print('Analysis error: $e');
  // Always return valid result to prevent UI crash
  return _getMockResult();
}
```

### Mock Result

```dart
AnalysisResult _getMockResult() {
  return AnalysisResult(
    score: 65,
    status: 'fair',
    summary: 'Son 3 günde lif tüketimi düşük görünüyor. Su alımınızı artırmanız sindirim kalitenizi yükseltecektir.',
    positives: ['Düzenli yemek saatleri', 'Şeker tüketimi az'],
    negatives: ['Yetersiz su', 'Lif eksikliği'],
    recommendations: [
      'Günde en az 2 litre su için.',
      'Öğünlerinize yeşil sebze ekleyin.',
      'Probiyotik içeren besinler tüketin.'
    ],
  );
}
```

## Testing Strategy

### Unit Tests

Unit tests will verify specific examples and edge cases:

- Empty data handling (no meals, no logs)
- Single meal analysis
- Multiple meals with allergen matches
- Invalid JSON responses
- Score boundary values (0, 40, 60, 80, 100)
- Status enum validation
- Color/label mapping for each score range
- Error handling for network failures
- Mock result structure

### Property-Based Tests

Property-based tests will verify universal properties across randomized inputs:

- **Time Window Filtering**: Generate random timestamps, verify all filtered results are within 3 days
- **Prompt Construction**: Generate random meals/logs, verify all data appears in prompt
- **JSON Round-Trip**: Generate random AnalysisResults, verify encode→decode preserves data
- **Score Validation**: Generate random scores, verify range constraints
- **Status Validation**: Generate random statuses, verify enum constraints
- **Color Mapping**: Generate random scores, verify correct color for each range
- **Label Mapping**: Generate random scores, verify correct label for each range
- **Concurrent Analysis Prevention**: Simulate concurrent calls, verify only one executes
- **Error Fallback**: Simulate various errors, verify mock result is always returned

Each property test should run a minimum of 100 iterations to ensure comprehensive coverage through randomization.

### Test Configuration

- Framework: Flutter's built-in test framework + `test` package
- Property testing library: `test` package with custom generators
- Minimum iterations per property test: 100
- Each test must reference its design property using format:
  ```dart
  // Feature: health-insights-analysis, Property 1: Time Window Filtering Consistency
  ```

### Integration Tests

- Full analysis flow from screen open to result display
- Repository integration (meal, log, allergen, profile)
- Gemini service integration (with mock responses)
- UI state transitions (loading → empty/content)
- Navigation flows (back button, empty state CTA)
