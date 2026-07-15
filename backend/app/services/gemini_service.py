import base64
from typing import List, Optional
from dataclasses import dataclass

import google.generativeai as genai

from app.core.config import settings


@dataclass
class MealIngredient:
    """Detected ingredient from AI analysis."""
    name: str
    confidence: float


@dataclass
class MealAllergen:
    """Detected allergen from AI analysis."""
    name: str
    trigger_ingredient: str
    confidence: float


@dataclass
class MealAnalysisResult:
    """Result from Gemini meal analysis."""
    detected_ingredients: List[MealIngredient]
    detected_allergens: List[MealAllergen]
    risk_level: str


# Common allergens for detection
COMMON_ALLERGENS = [
    "gluten", "wheat", "dairy", "milk", "lactose", "eggs", "egg",
    "peanuts", "peanut", "tree nuts", "almonds", "walnuts", "cashews",
    "soy", "soybean", "fish", "shellfish", "shrimp", "crab", "lobster",
    "sesame", "mustard", "celery", "lupin", "mollusks", "sulfites"
]


async def analyze_meal_image(image_base64: str) -> MealAnalysisResult:
    """
    Analyze a meal image using Google Gemini Vision.
    
    Args:
        image_base64: Base64 encoded image data
        
    Returns:
        MealAnalysisResult with detected ingredients and allergens
    """
    # If no API key configured, return mock response
    if not settings.gemini_api_key:
        return _get_mock_analysis()
    
    try:
        # Configure Gemini
        genai.configure(api_key=settings.gemini_api_key)
        model = genai.GenerativeModel('gemini-1.5-flash')
        
        # Decode image
        image_data = base64.b64decode(image_base64)
        
        # Create prompt for food analysis
        prompt = """Analyze this food image and provide:
1. A list of identified ingredients with confidence scores (0-1)
2. Any potential allergens found with the triggering ingredient

Respond in this exact JSON format:
{
    "ingredients": [
        {"name": "ingredient name", "confidence": 0.95}
    ],
    "allergens": [
        {"name": "allergen name", "trigger_ingredient": "ingredient that contains it", "confidence": 0.9}
    ]
}

Be thorough but accurate. Only include ingredients you can clearly identify."""

        # Call Gemini
        response = model.generate_content([
            prompt,
            {"mime_type": "image/jpeg", "data": image_data}
        ])
        
        # Parse response
        return _parse_gemini_response(response.text)
        
    except Exception as e:
        # Log error and return mock for development
        print(f"Gemini API error: {e}")
        return _get_mock_analysis()


def _parse_gemini_response(response_text: str) -> MealAnalysisResult:
    """Parse Gemini's JSON response into structured data."""
    import json
    
    try:
        # Extract JSON from response (handle markdown code blocks)
        text = response_text.strip()
        if text.startswith("```"):
            lines = text.split("\n")
            text = "\n".join(lines[1:-1])
        
        data = json.loads(text)
        
        ingredients = [
            MealIngredient(name=i["name"], confidence=i.get("confidence", 0.8))
            for i in data.get("ingredients", [])
        ]
        
        allergens = [
            MealAllergen(
                name=a["name"],
                trigger_ingredient=a.get("trigger_ingredient", "unknown"),
                confidence=a.get("confidence", 0.8)
            )
            for a in data.get("allergens", [])
        ]
        
        # Determine risk level
        risk_level = "none"
        if allergens:
            max_confidence = max(a.confidence for a in allergens)
            if max_confidence >= 0.8:
                risk_level = "high"
            elif max_confidence >= 0.5:
                risk_level = "medium"
            else:
                risk_level = "low"
        
        return MealAnalysisResult(
            detected_ingredients=ingredients,
            detected_allergens=allergens,
            risk_level=risk_level
        )
        
    except (json.JSONDecodeError, KeyError) as e:
        print(f"Error parsing Gemini response: {e}")
        return _get_mock_analysis()


def _get_mock_analysis() -> MealAnalysisResult:
    """Return mock analysis for development/testing."""
    return MealAnalysisResult(
        detected_ingredients=[
            MealIngredient(name="bread", confidence=0.95),
            MealIngredient(name="cheese", confidence=0.90),
            MealIngredient(name="tomato", confidence=0.85),
            MealIngredient(name="lettuce", confidence=0.80),
        ],
        detected_allergens=[
            MealAllergen(name="gluten", trigger_ingredient="bread", confidence=0.95),
            MealAllergen(name="dairy", trigger_ingredient="cheese", confidence=0.90),
        ],
        risk_level="medium"
    )
