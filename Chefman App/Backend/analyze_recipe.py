"""
Recipe Analysis using OpenAI API
Analyzes recipes to calculate calories and identify suitable diet types
"""

import json
from typing import Dict, List, Optional

def analyze_recipe_with_openai(openai_client, recipe_data: Dict) -> Dict:
    """
    Analyze recipe using OpenAI API to calculate calories and identify diet types
    
    Args:
        openai_client: OpenAI client instance
        recipe_data: Dictionary containing recipe information (title, ingredients, servings, etc.)
    
    Returns:
        Dictionary with 'calories_per_serving' and 'diet_types' keys
    """
    if not openai_client:
        return {
            "calories_per_serving": None,
            "diet_types": []
        }
    
    try:
        # Prepare recipe information for analysis
        ingredients_text = ""
        for ing in recipe_data.get('ingredients', []):
            ing_name = ing.get('ingredient_name', '')
            amount = ing.get('amount', '')
            unit = ing.get('unit', '')
            ingredients_text += f"- {ing_name}: {amount} {unit}\n"
        
        servings = recipe_data.get('servings', 1)
        title = recipe_data.get('title', '')
        description = recipe_data.get('description', '')
        
        # Create prompt for OpenAI
        prompt = f"""Analyze the following recipe and provide:
1. Estimated calories per serving (as an integer)
2. Suitable diet types from this list: Keto, GLP-1, Vegan, Vegetarian, Paleo, Mediterranean, Low-Carb, High-Protein, Gluten-Free, Dairy-Free, Low-Sodium, Heart-Healthy

Recipe Title: {title}
Description: {description}
Servings: {servings}

Ingredients:
{ingredients_text}

Please respond in JSON format only, with this exact structure:
{{
    "calories_per_serving": <integer>,
    "diet_types": ["<diet_type1>", "<diet_type2>", ...]
}}

Only include diet types that are clearly suitable based on the ingredients. If unsure, omit that diet type.
Return only the JSON, no additional text."""

        # Call OpenAI API
        response = openai_client.chat.completions.create(
            model="gpt-3.5-turbo",
            messages=[
                {"role": "system", "content": "You are a nutrition expert. Analyze recipes and provide accurate calorie estimates and diet type classifications. Always respond with valid JSON only."},
                {"role": "user", "content": prompt}
            ],
            temperature=0.3,
            max_tokens=300
        )
        
        # Parse response
        response_text = response.choices[0].message.content.strip()
        
        # Try to extract JSON from response
        # Remove markdown code blocks if present
        if response_text.startswith("```"):
            response_text = response_text.split("```")[1]
            if response_text.startswith("json"):
                response_text = response_text[4:]
            response_text = response_text.strip()
        
        # Parse JSON
        analysis_result = json.loads(response_text)
        
        return {
            "calories_per_serving": analysis_result.get("calories_per_serving"),
            "diet_types": analysis_result.get("diet_types", [])
        }
        
    except json.JSONDecodeError as e:
        print(f"❌ Failed to parse OpenAI response as JSON: {e}")
        if 'response_text' in locals():
            print(f"Response text: {response_text}")
        return {
            "calories_per_serving": None,
            "diet_types": []
        }
    except Exception as e:
        print(f"❌ Error analyzing recipe with OpenAI: {str(e)}")
        return {
            "calories_per_serving": None,
            "diet_types": []
        }

def analyze_recipe_simple(recipe_data: Dict) -> Dict:
    """
    Simple rule-based analysis as fallback when OpenAI is not available
    """
    ingredients = recipe_data.get('ingredients', [])
    diet_types = []
    
    # Simple diet type detection based on ingredients
    ingredient_names = [ing.get('ingredient_name', '').lower() for ing in ingredients]
    all_ingredients_text = ' '.join(ingredient_names)
    
    # Check for vegan (no animal products)
    animal_keywords = ['meat', 'chicken', 'beef', 'pork', 'fish', 'egg', 'milk', 'cheese', 'butter', 'cream']
    if not any(keyword in all_ingredients_text for keyword in animal_keywords):
        diet_types.append("Vegan")
        diet_types.append("Vegetarian")
    
    # Check for vegetarian (no meat but may have dairy/eggs)
    meat_keywords = ['meat', 'chicken', 'beef', 'pork', 'fish']
    if not any(keyword in all_ingredients_text for keyword in meat_keywords):
        if "Vegetarian" not in diet_types:
            diet_types.append("Vegetarian")
    
    # Check for gluten-free (no wheat, flour, bread)
    gluten_keywords = ['wheat', 'flour', 'bread', 'pasta', 'noodle']
    if not any(keyword in all_ingredients_text for keyword in gluten_keywords):
        diet_types.append("Gluten-Free")
    
    # Check for dairy-free
    dairy_keywords = ['milk', 'cheese', 'butter', 'cream', 'yogurt']
    if not any(keyword in all_ingredients_text for keyword in dairy_keywords):
        diet_types.append("Dairy-Free")
    
    # Simple calorie estimation (very rough)
    # This is a placeholder - real calculation would need nutritional database
    calories_per_serving = None
    
    return {
        "calories_per_serving": calories_per_serving,
        "diet_types": diet_types
    }

