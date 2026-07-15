# Requirements Document

## Introduction

The Health Insights Analysis feature provides users with AI-powered analysis of their digestive health based on their meal logs, stool reports, and symptom records from the last 3 days. The system generates a health score (0-100) and personalized recommendations to improve digestive wellness.

## Glossary

- **System**: The Health Insights Analysis feature within the Entera mobile application
- **User**: A person using the Entera app to track digestive health
- **Health_Data**: Collection of meals, stool logs, and symptom records
- **AI_Service**: Gemini AI service used for health analysis
- **Analysis_Result**: Structured output containing score, status, summary, positives, negatives, and recommendations
- **Time_Window**: The last 3 days (72 hours) from current time

## Requirements

### Requirement 1: Data Collection and Filtering

**User Story:** As a user, I want the system to analyze my recent health data, so that I can understand my current digestive health status.

#### Acceptance Criteria

1. WHEN the analysis is triggered, THE System SHALL retrieve all meal records from the last 3 days
2. WHEN the analysis is triggered, THE System SHALL retrieve all stool log records from the last 3 days
3. WHEN the analysis is triggered, THE System SHALL retrieve all symptom records from the last 3 days
4. WHEN the analysis is triggered, THE System SHALL retrieve the user's profile information including age, gender, and known allergens
5. IF no data exists within the Time_Window, THEN THE System SHALL display an empty state message

### Requirement 2: AI Prompt Construction

**User Story:** As a user, I want my health data to be properly formatted for AI analysis, so that I receive accurate and relevant insights.

#### Acceptance Criteria

1. WHEN constructing the AI prompt, THE System SHALL include user profile information (age, gender, allergens)
2. WHEN constructing the AI prompt, THE System SHALL include all meals with timestamps, ingredients, and risk levels
3. WHEN constructing the AI prompt, THE System SHALL include all stool logs with timestamps, Bristol scale values, and notes
4. WHEN constructing the AI prompt, THE System SHALL include all symptom logs with timestamps, types, severity values, and notes
5. WHEN constructing the AI prompt, THE System SHALL format the data in Turkish language
6. WHEN constructing the AI prompt, THE System SHALL request a JSON response with specific fields: score, status, summary, positives, negatives, recommendations

### Requirement 3: AI Analysis Execution

**User Story:** As a user, I want the AI to analyze my health data, so that I receive a comprehensive health assessment.

#### Acceptance Criteria

1. WHEN the AI service is configured, THE System SHALL send the formatted prompt to the Gemini AI service
2. WHEN the AI service is not configured, THE System SHALL display a mock result for testing purposes
3. IF the AI service call fails, THEN THE System SHALL display a mock result to prevent blocking the user
4. WHEN the AI analysis is in progress, THE System SHALL display a loading indicator
5. WHEN the AI analysis completes, THE System SHALL parse the JSON response into an Analysis_Result object

### Requirement 4: Response Parsing

**User Story:** As a user, I want the AI response to be correctly parsed, so that I can view my health insights properly.

#### Acceptance Criteria

1. WHEN parsing the AI response, THE System SHALL extract the JSON object from the response text
2. WHEN parsing the AI response, THE System SHALL decode the JSON into an Analysis_Result with score, status, summary, positives, negatives, and recommendations
3. IF the JSON parsing fails, THEN THE System SHALL fallback to a mock result
4. WHEN parsing is successful, THE System SHALL validate that the score is between 0 and 100
5. WHEN parsing is successful, THE System SHALL validate that the status is one of: "excellent", "good", "fair", "poor"

### Requirement 5: Score Display

**User Story:** As a user, I want to see my digestive health score prominently displayed, so that I can quickly understand my health status.

#### Acceptance Criteria

1. WHEN displaying the analysis result, THE System SHALL show the health score as a large number (0-100)
2. WHEN displaying the score, THE System SHALL use color coding: green for 80-100, blue for 60-79, orange for 40-59, red for 0-39
3. WHEN displaying the score, THE System SHALL show a status label: "Mükemmel" for 80-100, "İyi Durumda" for 60-79, "Düzensiz" for 40-59, "Dikkat Gerekiyor" for 0-39
4. WHEN displaying the score, THE System SHALL present it in a circular badge with colored border

### Requirement 6: Insights Display

**User Story:** As a user, I want to see detailed analysis of my health data, so that I understand what I'm doing well and what needs improvement.

#### Acceptance Criteria

1. WHEN displaying the analysis result, THE System SHALL show a summary section with the AI-generated summary text
2. WHEN displaying the analysis result, THE System SHALL show a "positives" section listing good health behaviors
3. WHEN displaying the analysis result, THE System SHALL show a "negatives" section listing areas of concern
4. WHEN displaying the analysis result, THE System SHALL show a recommendations section with actionable advice
5. IF any section has no items, THEN THE System SHALL display a placeholder indicator

### Requirement 7: User Interactions

**User Story:** As a user, I want to control when analysis happens, so that I can refresh my insights when I add new data.

#### Acceptance Criteria

1. WHEN the insights screen opens, THE System SHALL automatically trigger analysis
2. WHEN the user taps the refresh button, THE System SHALL re-run the analysis
3. WHILE analysis is in progress, THE System SHALL disable the refresh button
4. WHEN the user taps the back button, THE System SHALL navigate to the home screen
5. WHEN the user taps "Veri Ekle" in the empty state, THE System SHALL navigate to the home screen

### Requirement 8: Error Handling

**User Story:** As a user, I want the app to handle errors gracefully, so that I can still use the feature even when issues occur.

#### Acceptance Criteria

1. IF the AI service call throws an exception, THEN THE System SHALL catch the error and display a mock result
2. IF the JSON parsing fails, THEN THE System SHALL fallback to a mock result
3. IF the data repositories are unavailable, THEN THE System SHALL display an appropriate error message
4. WHEN any error occurs, THE System SHALL log the error for debugging purposes
5. WHEN the loading state changes, THE System SHALL check if the widget is still mounted before updating state
