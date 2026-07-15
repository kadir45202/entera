"""Tests for meal analysis service."""
import pytest
from unittest.mock import patch, MagicMock

from app.services.gemini_service import (
    analyze_meal_image, 
    _parse_gemini_response, 
    _get_mock_analysis,
    MealAnalysisResult,
    MealIngredient,
    MealAllergen
)
from app.services.meal_service import check_user_allergens
from app.models.allergen import Allergen


class TestGeminiService:
    """Tests for Gemini Vision integration."""
    
    def test_mock_analysis_returns_valid_result(self):
        """Test that mock analysis returns proper structure."""
        result = _get_mock_analysis()
        
        assert isinstance(result, MealAnalysisResult)
        assert len(result.detected_ingredients) > 0
        assert len(result.detected_allergens) > 0
        assert result.risk_level in ["none", "low", "medium", "high"]
    
    def test_parse_valid_json_response(self):
        """Test parsing a valid Gemini response."""
        response = '''
        {
            "ingredients": [
                {"name": "chicken", "confidence": 0.95},
                {"name": "rice", "confidence": 0.90}
            ],
            "allergens": [
                {"name": "gluten", "trigger_ingredient": "soy sauce", "confidence": 0.7}
            ]
        }
        '''
        
        result = _parse_gemini_response(response)
        
        assert len(result.detected_ingredients) == 2
        assert result.detected_ingredients[0].name == "chicken"
        assert result.detected_ingredients[0].confidence == 0.95
        assert len(result.detected_allergens) == 1
        assert result.detected_allergens[0].name == "gluten"
    
    def test_parse_json_in_markdown_code_block(self):
        """Test parsing JSON wrapped in markdown code blocks."""
        response = '''```json
{
    "ingredients": [{"name": "pasta", "confidence": 0.9}],
    "allergens": []
}
```'''
        
        result = _parse_gemini_response(response)
        
        assert len(result.detected_ingredients) == 1
        assert result.detected_ingredients[0].name == "pasta"
        assert result.risk_level == "none"  # No allergens
    
    def test_parse_invalid_json_returns_mock(self):
        """Test that invalid JSON returns mock analysis."""
        result = _parse_gemini_response("not valid json at all")
        
        # Should return mock analysis
        assert isinstance(result, MealAnalysisResult)
        assert len(result.detected_ingredients) > 0
    
    def test_risk_level_calculation_high(self):
        """Test high risk level for high confidence allergens."""
        response = '''
        {
            "ingredients": [{"name": "bread", "confidence": 0.9}],
            "allergens": [{"name": "gluten", "trigger_ingredient": "bread", "confidence": 0.95}]
        }
        '''
        
        result = _parse_gemini_response(response)
        assert result.risk_level == "high"
    
    def test_risk_level_calculation_medium(self):
        """Test medium risk level for medium confidence allergens."""
        response = '''
        {
            "ingredients": [{"name": "sauce", "confidence": 0.8}],
            "allergens": [{"name": "soy", "trigger_ingredient": "sauce", "confidence": 0.6}]
        }
        '''
        
        result = _parse_gemini_response(response)
        assert result.risk_level == "medium"


class TestMealService:
    """Tests for meal allergen cross-reference logic."""
    
    @pytest.mark.asyncio
    async def test_check_user_allergens_direct_match(self):
        """Test that direct allergen matches are detected."""
        detected = [
            MealAllergen(name="gluten", trigger_ingredient="bread", confidence=0.9)
        ]
        
        user_allergens = [
            MagicMock(spec=Allergen, name="Gluten", trigger_keywords=["gluten", "wheat"])
        ]
        user_allergens[0].name = "Gluten"
        user_allergens[0].trigger_keywords = ["gluten", "wheat"]
        
        warnings = await check_user_allergens(detected, user_allergens)
        
        assert len(warnings) == 1
        assert "Gluten" in warnings[0] or "gluten" in warnings[0]
    
    @pytest.mark.asyncio
    async def test_check_user_allergens_no_match(self):
        """Test that non-matching allergens return no warnings."""
        detected = [
            MealAllergen(name="peanut", trigger_ingredient="sauce", confidence=0.9)
        ]
        
        user_allergens = [
            MagicMock(spec=Allergen)
        ]
        user_allergens[0].name = "Gluten"
        user_allergens[0].trigger_keywords = ["gluten", "wheat"]
        
        warnings = await check_user_allergens(detected, user_allergens)
        
        assert len(warnings) == 0
    
    @pytest.mark.asyncio
    async def test_check_user_allergens_keyword_match(self):
        """Test that keyword-based matches work."""
        detected = [
            MealAllergen(name="wheat flour", trigger_ingredient="bread", confidence=0.9)
        ]
        
        user_allergens = [
            MagicMock(spec=Allergen)
        ]
        user_allergens[0].name = "Gluten"
        user_allergens[0].trigger_keywords = ["gluten", "wheat"]
        
        warnings = await check_user_allergens(detected, user_allergens)
        
        assert len(warnings) == 1
    
    @pytest.mark.asyncio
    async def test_check_user_allergens_empty_profile(self):
        """Test with no user allergens."""
        detected = [
            MealAllergen(name="gluten", trigger_ingredient="bread", confidence=0.9)
        ]
        
        warnings = await check_user_allergens(detected, [])
        
        assert len(warnings) == 0


# Run with: pytest tests/test_meal_analysis.py -v
