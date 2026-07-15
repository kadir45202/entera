from typing import List

from app.models.allergen import Allergen
from app.services.gemini_service import MealAllergen


async def check_user_allergens(
    detected_allergens: List[MealAllergen],
    user_allergens: List[Allergen]
) -> List[str]:
    """
    Cross-reference detected allergens with user's allergen profile.
    
    Args:
        detected_allergens: Allergens detected by AI in the meal
        user_allergens: User's saved allergen intolerances
        
    Returns:
        List of warning messages for matching allergens
    """
    warnings = []
    
    # Get user's allergen names and keywords
    user_allergen_names = set()
    user_trigger_keywords = set()
    
    for allergen in user_allergens:
        user_allergen_names.add(allergen.name.lower())
        for keyword in allergen.trigger_keywords:
            user_trigger_keywords.add(keyword.lower())
    
    # Check each detected allergen
    for detected in detected_allergens:
        detected_name = detected.name.lower()
        
        # Direct match
        if detected_name in user_allergen_names:
            warnings.append(
                f"⚠️ {detected.name} detected in {detected.trigger_ingredient} "
                f"(matches your allergen profile)"
            )
            continue
        
        # Check against trigger keywords
        for keyword in user_trigger_keywords:
            if keyword in detected_name or detected_name in keyword:
                warnings.append(
                    f"⚠️ {detected.name} detected in {detected.trigger_ingredient} "
                    f"(may trigger {keyword} sensitivity)"
                )
                break
    
    return warnings
