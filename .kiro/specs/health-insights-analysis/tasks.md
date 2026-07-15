# Implementation Plan: Health Insights Analysis

## Overview

This plan implements the Health Insights Analysis feature that provides AI-powered digestive health assessment. The implementation will refactor the existing `insights_screen.dart` file to properly integrate with repositories, correctly parse JSON responses, and display results with proper error handling.

## Tasks

- [x] 1. Create AnalysisResult model with JSON serialization
  - Create `AnalysisResult` class with all required fields (score, status, summary, positives, negatives, recommendations)
  - Implement `fromJson` factory constructor with validation
  - Implement `toJson` method for serialization
  - Add validation for score range (0-100) and status enum
  - _Requirements: 4.2, 4.4, 4.5_

- [x] 1.1 Write property test for AnalysisResult JSON round-trip
  - **Property 3: JSON Parsing Round-Trip**
  - **Validates: Requirements 4.2**

- [x] 1.2 Write unit tests for AnalysisResult validation
  - Test score range validation (0-100)
  - Test status enum validation
  - Test edge cases (null values, missing fields)
  - _Requirements: 4.4, 4.5_

- [x] 2. Implement data collection and filtering logic
  - [x] 2.1 Create time window filtering function
    - Implement `filterByTimeWindow` to get records from last 3 days
    - Apply to meals, stool logs, and symptom logs
    - _Requirements: 1.1, 1.2, 1.3_

  - [x] 2.2 Write property test for time window filtering
    - **Property 1: Time Window Filtering Consistency**
    - **Validates: Requirements 1.1, 1.2, 1.3**

  - [x] 2.3 Implement data collection from repositories
    - Fetch meals from MealRepository
    - Fetch logs from LogRepository (stool and symptom)
    - Fetch user profile from UserProfileRepository
    - Fetch allergens from AllergenRepository
    - _Requirements: 1.1, 1.2, 1.3, 1.4_

  - [x] 2.4 Write unit tests for data collection
    - Test empty data handling
    - Test single record collection
    - Test multiple records collection
    - _Requirements: 1.1, 1.2, 1.3, 1.4_

- [ ] 3. Implement AI prompt construction
  - [ ] 3.1 Create prompt builder function
    - Format user profile information (age, gender, allergens)
    - Format meals with timestamps, ingredients, risk levels
    - Format stool logs with Bristol scale values
    - Format symptom logs with types and severity
    - Use Turkish language for all text
    - Include JSON schema in prompt
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6_

  - [ ] 3.2 Write property test for prompt completeness
    - **Property 2: Prompt Contains All Required Data**
    - **Validates: Requirements 2.2, 2.3, 2.4**

  - [ ] 3.3 Write unit tests for prompt formatting
    - Test prompt with empty data sections
    - Test prompt with full data
    - Test Turkish language formatting
    - Test JSON schema inclusion
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6_

- [ ] 4. Implement JSON response parsing
  - [ ] 4.1 Create JSON extraction function
    - Extract JSON from AI response text (handle markdown code blocks)
    - Find first `{` and last `}` in response
    - Return extracted JSON string
    - _Requirements: 4.1_

  - [ ] 4.2 Create response parsing function
    - Call JSON extraction
    - Decode JSON using `jsonDecode`
    - Validate required fields exist
    - Create AnalysisResult from JSON
    - Handle parsing errors with fallback to mock result
    - _Requirements: 4.1, 4.2, 4.3_

  - [ ] 4.3 Write property test for score validation
    - **Property 4: Score Range Validation**
    - **Validates: Requirements 4.4**

  - [ ] 4.4 Write property test for status validation
    - **Property 5: Status Enum Validation**
    - **Validates: Requirements 4.5**

  - [ ] 4.5 Write unit tests for JSON parsing edge cases
    - Test malformed JSON
    - Test missing fields
    - Test invalid score values
    - Test invalid status values
    - Test fallback to mock result
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5_

- [ ] 5. Implement score display logic
  - [ ] 5.1 Create color mapping function
    - Map score ranges to colors: 80-100→green, 60-79→blue, 40-59→orange, 0-39→red
    - Return appropriate EnteraColors constant
    - _Requirements: 5.2_

  - [ ] 5.2 Write property test for color mapping
    - **Property 6: Score-to-Color Mapping Consistency**
    - **Validates: Requirements 5.2**

  - [ ] 5.3 Create label mapping function
    - Map score ranges to Turkish labels
    - Return appropriate status label
    - _Requirements: 5.3_

  - [ ] 5.4 Write property test for label mapping
    - **Property 7: Score-to-Label Mapping Consistency**
    - **Validates: Requirements 5.3**

  - [ ] 5.5 Write unit tests for score display
    - Test boundary values (0, 40, 60, 80, 100)
    - Test mid-range values
    - _Requirements: 5.2, 5.3_

- [ ] 6. Checkpoint - Ensure all core logic tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 7. Implement analysis execution flow
  - [ ] 7.1 Create performAnalysis function
    - Check if already analyzing (prevent concurrent execution)
    - Set loading state to true
    - Clear previous result
    - Collect and filter data
    - Check if data exists (show empty state if not)
    - Build AI prompt
    - Call Gemini service
    - Parse response
    - Update result state
    - Handle all errors with try-catch
    - Set loading state to false in finally block
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 8.1, 8.2, 8.4, 8.5_

  - [ ] 7.2 Write property test for concurrent analysis prevention
    - **Property 8: Loading State Prevents Concurrent Analysis**
    - **Validates: Requirements 7.3**

  - [ ] 7.3 Write property test for error handling
    - **Property 9: Error Handling Fallback**
    - **Validates: Requirements 8.1, 8.2**

  - [ ] 7.4 Write unit tests for analysis flow
    - Test successful analysis
    - Test empty data handling
    - Test AI service not configured
    - Test network error handling
    - Test parsing error handling
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 8.1, 8.2, 8.3_

- [ ] 8. Refactor InsightsScreen UI
  - [ ] 8.1 Update state management
    - Use existing `isAnalyzingProvider` for loading state
    - Use existing `currentAnalysisProvider` for result state
    - Trigger analysis in `initState`
    - _Requirements: 7.1_

  - [ ] 8.2 Implement loading state UI
    - Show CircularProgressIndicator
    - Show "Yapay Zeka Analiz Ediyor..." message
    - Show subtitle message
    - _Requirements: 3.4_

  - [ ] 8.3 Implement empty state UI
    - Show analytics icon
    - Show "Yeterli Veri Yok" title
    - Show explanation text
    - Show "Veri Ekle" button that navigates to home
    - _Requirements: 1.5, 7.5_

  - [ ] 8.4 Implement content state UI
    - Build score hero with circular badge
    - Build summary card
    - Build positives/negatives row
    - Build recommendations list
    - Use color mapping for score display
    - Use label mapping for status display
    - _Requirements: 5.1, 5.2, 5.3, 6.1, 6.2, 6.3, 6.4_

  - [ ] 8.5 Implement refresh functionality
    - Add refresh button to AppBar
    - Disable button while loading
    - Call performAnalysis on tap
    - _Requirements: 7.2, 7.3_

  - [ ] 8.6 Implement navigation
    - Back button navigates to home
    - Empty state button navigates to home
    - _Requirements: 7.4, 7.5_

  - [ ] 8.7 Write widget tests for UI states
    - Test loading state renders correctly
    - Test empty state renders correctly
    - Test content state renders correctly
    - Test refresh button behavior
    - Test navigation behavior
    - _Requirements: 3.4, 5.1, 6.1, 6.2, 6.3, 6.4, 7.2, 7.4, 7.5_

- [ ] 9. Create mock result function
  - Implement `_getMockResult()` with realistic Turkish data
  - Use for fallback when AI service unavailable or errors occur
  - _Requirements: 3.2, 8.1, 8.2_

- [ ] 9.1 Write unit test for mock result structure
  - Test mock result has valid score
  - Test mock result has valid status
  - Test mock result has all required fields
  - _Requirements: 3.2_

- [ ] 10. Final checkpoint - Integration testing
  - Run full analysis flow end-to-end
  - Test with real Gemini API (if configured)
  - Test with mock data
  - Verify all error scenarios
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- All tasks are required for comprehensive implementation
- Each task references specific requirements for traceability
- Property tests validate universal correctness properties
- Unit tests validate specific examples and edge cases
- The existing `insights_screen.dart` file will be completely refactored
- All JSON parsing must use `dart:convert` which is already imported
- Error handling is critical - always fallback to mock result instead of crashing
- Turkish language must be used for all user-facing text
- The feature must work in both guest and authenticated modes
