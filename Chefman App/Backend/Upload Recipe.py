from datetime import datetime, timezone
from firebase_db import db

def utc_now():
    return datetime.now(timezone.utc)

recipes = [
    {
        "title": "Citrus Herb Salmon with Roasted Vegetables",
        "description": "Bright, zesty salmon coated in a citrus-herb glaze and baked alongside tender roasted vegetables. Balanced flavors and simple techniques make this dish perfect for midweek dinners or entertaining.",
        "image_url": None,
        "recipe_type": "Dish",
        "cuisine_type": "Modern American",
        "prep_time": "15 min",
        "cook_time": "25 min",
        "total_time": "40 min",
        "servings": 2,
        "difficulty": "Moderate",
        "ingredients": [
            {"ingredient_name": "Fresh salmon fillets", "amount": "180", "unit": "g", "notes": "2 pieces"},
            {"ingredient_name": "Olive oil", "amount": "30", "unit": "ml", "notes": None},
            {"ingredient_name": "Fresh lemon juice", "amount": "20", "unit": "ml", "notes": None},
            {"ingredient_name": "Orange zest", "amount": "5", "unit": "g", "notes": None},
            {"ingredient_name": "Dijon mustard", "amount": "15", "unit": "g", "notes": None},
            {"ingredient_name": "Honey", "amount": "10", "unit": "g", "notes": None},
            {"ingredient_name": "Garlic cloves (minced)", "amount": "8", "unit": "g", "notes": "approx. 2 cloves"},
            {"ingredient_name": "Fresh dill (chopped)", "amount": "6", "unit": "g", "notes": None},
            {"ingredient_name": "Fresh parsley (chopped)", "amount": "6", "unit": "g", "notes": None},
            {"ingredient_name": "Sea salt", "amount": "4", "unit": "g", "notes": None},
            {"ingredient_name": "Black pepper", "amount": "2", "unit": "g", "notes": None},
            {"ingredient_name": "Baby potatoes", "amount": "250", "unit": "g", "notes": None},
            {"ingredient_name": "Carrots (wedges)", "amount": "150", "unit": "g", "notes": None},
            {"ingredient_name": "Brussels sprouts", "amount": "120", "unit": "g", "notes": None},
            {"ingredient_name": "Red onion (wedges)", "amount": "60", "unit": "g", "notes": None},
            {"ingredient_name": "Extra olive oil for vegetables", "amount": "20", "unit": "ml", "notes": None},
            {"ingredient_name": "Smoked paprika", "amount": "3", "unit": "g", "notes": None}
        ],
        "steps": [
            {"step_number": 1, "description": "Toss potatoes, carrots, Brussels sprouts, and red onion with 20 ml olive oil, smoked paprika, half the salt, and half the pepper. Spread evenly on the baking sheet.", "duration": "5 min", "temperature": None, "notes": "Ensure vegetables are evenly coated.", "image_url": None, "video_url": None},
            {"step_number": 2, "description": "Place the sheet in the preheated oven; roast vegetables for 15 minutes to give them a head start.", "duration": "15 min", "temperature": "200°C / 392°F", "notes": None, "image_url": None, "video_url": None},
            {"step_number": 3, "description": "In a bowl, whisk remaining olive oil, lemon juice, orange zest, Dijon mustard, honey, minced garlic, dill, parsley, salt, and pepper into a thick glaze.", "duration": "5 min", "temperature": None, "notes": "Mixture should be emulsified.", "image_url": None, "video_url": None},
            {"step_number": 4, "description": "Pat salmon fillets dry, then brush both sides generously with the citrus herb glaze.", "duration": "2 min", "temperature": None, "notes": "Reserve some glaze for topping.", "image_url": None, "video_url": None},
            {"step_number": 5, "description": "Remove tray, nestle glazed salmon among the vegetables, brush remaining glaze on top. Return to oven for 10 minutes, or until salmon flakes easily and veggies are tender.", "duration": "10 min", "temperature": "200°C / 392°F", "notes": None, "image_url": None, "video_url": None},
            {"step_number": 6, "description": "Let salmon rest 3 minutes. Plate with roasted vegetables, spoon any tray juices on top, and garnish with fresh dill if desired.", "duration": "3 min", "temperature": None, "notes": None, "image_url": None, "video_url": None}
        ],
        "equipment": [
            {"equipment_name": "Chef's knife", "brand": None, "is_chefman": False},
            {"equipment_name": "Mixing bowl", "brand": None, "is_chefman": False},
            {"equipment_name": "Baking sheet with parchment", "brand": None, "is_chefman": False},
            {"equipment_name": "Pastry brush", "brand": None, "is_chefman": False},
            {"equipment_name": "Measuring spoons/cups", "brand": None, "is_chefman": False},
            {"equipment_name": "Oven", "brand": None, "is_chefman": False}
        ],
        "creator_id": 1024,
        "creator_username": "chef_amelia"
    },
    {
        "title": "Spiced Coconut Lentil Stew",
        "description": "Comforting red lentil stew infused with coconut milk, warm spices, and hearty vegetables. Naturally vegan and protein-rich—great for meal prep.",
        "image_url": None,
        "recipe_type": "Dish",
        "cuisine_type": "Global Fusion",
        "prep_time": "15 min",
        "cook_time": "30 min",
        "total_time": "45 min",
        "servings": 4,
        "difficulty": "Easy",
        "ingredients": [
            {"ingredient_name": "Olive oil", "amount": "20", "unit": "ml", "notes": None},
            {"ingredient_name": "Yellow onion (diced)", "amount": "120", "unit": "g", "notes": None},
            {"ingredient_name": "Carrot (diced)", "amount": "80", "unit": "g", "notes": None},
            {"ingredient_name": "Celery stalk (diced)", "amount": "70", "unit": "g", "notes": None},
            {"ingredient_name": "Garlic (minced)", "amount": "10", "unit": "g", "notes": "approx. 3 cloves"},
            {"ingredient_name": "Fresh ginger (grated)", "amount": "8", "unit": "g", "notes": None},
            {"ingredient_name": "Red lentils (rinsed)", "amount": "220", "unit": "g", "notes": None},
            {"ingredient_name": "Diced tomatoes (canned)", "amount": "400", "unit": "g", "notes": None},
            {"ingredient_name": "Vegetable broth", "amount": "750", "unit": "ml", "notes": None},
            {"ingredient_name": "Coconut milk (full fat)", "amount": "200", "unit": "ml", "notes": None},
            {"ingredient_name": "Ground cumin", "amount": "5", "unit": "g", "notes": None},
            {"ingredient_name": "Ground coriander", "amount": "4", "unit": "g", "notes": None},
            {"ingredient_name": "Smoked paprika", "amount": "3", "unit": "g", "notes": None},
            {"ingredient_name": "Turmeric powder", "amount": "2", "unit": "g", "notes": None},
            {"ingredient_name": "Sea salt", "amount": "5", "unit": "g", "notes": "adjust to taste"},
            {"ingredient_name": "Black pepper", "amount": "2", "unit": "g", "notes": None},
            {"ingredient_name": "Baby spinach", "amount": "80", "unit": "g", "notes": None},
            {"ingredient_name": "Fresh cilantro (chopped)", "amount": "10", "unit": "g", "notes": "for garnish"},
            {"ingredient_name": "Lime wedges", "amount": None, "unit": "", "notes": "for serving"}
        ],
        "steps": [
            {"step_number": 1, "description": "Warm olive oil in a heavy pot over medium heat. Add onion, carrot, and celery; sauté 5 minutes until softened.", "duration": "5 min", "temperature": None, "notes": None, "image_url": None, "video_url": None},
            {"step_number": 2, "description": "Stir in garlic and ginger; cook 1 minute until fragrant.", "duration": "1 min", "temperature": None, "notes": None, "image_url": None, "video_url": None},
            {"step_number": 3, "description": "Add cumin, coriander, smoked paprika, and turmeric. Toast spices for 1 minute.", "duration": "1 min", "temperature": None, "notes": "Keep stirring to prevent burning.", "image_url": None, "video_url": None},
            {"step_number": 4, "description": "Add red lentils, diced tomatoes with juices, vegetable broth, salt, and pepper. Bring to a gentle boil.", "duration": "3 min", "temperature": "Medium-high", "notes": None, "image_url": None, "video_url": None},
            {"step_number": 5, "description": "Reduce heat, cover, and simmer 20 minutes until lentils are tender.", "duration": "20 min", "temperature": "Low simmer", "notes": "Stir occasionally to avoid sticking.", "image_url": None, "video_url": None},
            {"step_number": 6, "description": "Stir in coconut milk and baby spinach. Simmer 3 minutes until spinach wilts.", "duration": "3 min", "temperature": "Low", "notes": None, "image_url": None, "video_url": None},
            {"step_number": 7, "description": "Adjust seasoning. Serve with cilantro and lime wedges.", "duration": "2 min", "temperature": None, "notes": None, "image_url": None, "video_url": None}
        ],
        "equipment": [
            {"equipment_name": "Chef's knife", "brand": None, "is_chefman": False},
            {"equipment_name": "Cutting board", "brand": None, "is_chefman": False},
            {"equipment_name": "Heavy pot or Dutch oven", "brand": None, "is_chefman": False},
            {"equipment_name": "Wooden spoon", "brand": None, "is_chefman": False},
            {"equipment_name": "Measuring cups/spoons", "brand": None, "is_chefman": False}
        ],
        "creator_id": 2048,
        "creator_username": "plantbased_lucas"
    },
    {
        "title": "Crispy Air-Fried Chicken Tacos",
        "description": "Juicy chicken thighs marinated with chili-lime seasoning, air-fried until crisp, then tucked into warm tortillas with charred corn salsa and avocado crema.",
        "image_url": None,
        "recipe_type": "Dish",
        "cuisine_type": "Tex-Mex",
        "prep_time": "20 min",
        "cook_time": "18 min",
        "total_time": "38 min",
        "servings": 4,
        "difficulty": "Moderate",
        "ingredients": [
            {"ingredient_name": "Boneless skinless chicken thighs", "amount": "600", "unit": "g", "notes": "trimmed"},
            {"ingredient_name": "Olive oil", "amount": "25", "unit": "ml", "notes": None},
            {"ingredient_name": "Fresh lime juice", "amount": "20", "unit": "ml", "notes": None},
            {"ingredient_name": "Chili powder", "amount": "6", "unit": "g", "notes": None},
            {"ingredient_name": "Ground cumin", "amount": "4", "unit": "g", "notes": None},
            {"ingredient_name": "Garlic powder", "amount": "3", "unit": "g", "notes": None},
            {"ingredient_name": "Smoked paprika", "amount": "3", "unit": "g", "notes": None},
            {"ingredient_name": "Sea salt", "amount": "5", "unit": "g", "notes": None},
            {"ingredient_name": "Black pepper", "amount": "2", "unit": "g", "notes": None},
            {"ingredient_name": "Corn kernels (fresh or frozen)", "amount": "200", "unit": "g", "notes": None},
            {"ingredient_name": "Red bell pepper (diced)", "amount": "100", "unit": "g", "notes": None},
            {"ingredient_name": "Red onion (minced)", "amount": "60", "unit": "g", "notes": None},
            {"ingredient_name": "Cilantro (chopped)", "amount": "12", "unit": "g", "notes": None},
            {"ingredient_name": "Avocado", "amount": "150", "unit": "g", "notes": "1 medium"},
            {"ingredient_name": "Greek yogurt", "amount": "80", "unit": "g", "notes": None},
            {"ingredient_name": "Warm corn tortillas", "amount": "8", "unit": "", "notes": None},
            {"ingredient_name": "Extra lime wedges", "amount": None, "unit": "", "notes": "for serving"}
        ],
        "steps": [
            {"step_number": 1, "description": "Combine olive oil, lime juice, chili powder, cumin, garlic powder, smoked paprika, salt, and pepper. Toss with chicken thighs; marinate 15 minutes.", "duration": "15 min", "temperature": None, "notes": "Can marinate up to 4 hours refrigerated.", "image_url": None, "video_url": None},
            {"step_number": 2, "description": "Preheat air fryer to 190°C / 375°F. Arrange chicken in a single layer.", "duration": "3 min", "temperature": "190°C / 375°F", "notes": None, "image_url": None, "video_url": None},
            {"step_number": 3, "description": "Air fry chicken 9 minutes, flip, and cook 7–9 minutes more until internal temp hits 74°C / 165°F. Rest 5 minutes before slicing.", "duration": "18 min", "temperature": "190°C / 375°F", "notes": "Adjust time per fryer model.", "image_url": None, "video_url": None},
            {"step_number": 4, "description": "Meanwhile char corn in a skillet over high heat until edges are browned. Mix with red bell pepper, red onion, cilantro, pinch of salt, and squeeze of lime.", "duration": "6 min", "temperature": "High", "notes": None, "image_url": None, "video_url": None},
            {"step_number": 5, "description": "Blend avocado with Greek yogurt, remaining lime juice, and pinch of salt to make crema.", "duration": "3 min", "temperature": None, "notes": None, "image_url": None, "video_url": None},
            {"step_number": 6, "description": "Warm tortillas, layer sliced chicken, charred corn salsa, and drizzle avocado crema. Serve with lime wedges.", "duration": "3 min", "temperature": None, "notes": None, "image_url": None, "video_url": None}
        ],
        "equipment": [
            {"equipment_name": "Mixing bowl", "brand": None, "is_chefman": False},
            {"equipment_name": "Air fryer", "brand": "Chefman TurboFry", "is_chefman": True},
            {"equipment_name": "Skillet", "brand": None, "is_chefman": False},
            {"equipment_name": "Blender or immersion blender", "brand": None, "is_chefman": False},
            {"equipment_name": "Tongs", "brand": None, "is_chefman": False}
        ],
        "creator_id": 3050,
        "creator_username": "chef_maya"
    },
    {
        "title": "Matcha Yogurt Parfait with Granola Crunch",
        "description": "Layered parfait featuring earthy matcha yogurt, toasted almond granola, and honey-lime berries. A refreshing breakfast or dessert with antioxidants and texture.",
        "image_url": None,
        "recipe_type": "Dessert",
        "cuisine_type": "Japanese-inspired",
        "prep_time": "10 min",
        "cook_time": "8 min",
        "total_time": "18 min",
        "servings": 2,
        "difficulty": "Easy",
        "ingredients": [
            {"ingredient_name": "Rolled oats", "amount": "80", "unit": "g", "notes": None},
            {"ingredient_name": "Sliced almonds", "amount": "30", "unit": "g", "notes": None},
            {"ingredient_name": "Unsweetened shredded coconut", "amount": "20", "unit": "g", "notes": None},
            {"ingredient_name": "Maple syrup", "amount": "30", "unit": "ml", "notes": None},
            {"ingredient_name": "Coconut oil (melted)", "amount": "15", "unit": "ml", "notes": None},
            {"ingredient_name": "Greek yogurt (plain)", "amount": "300", "unit": "g", "notes": None},
            {"ingredient_name": "Matcha powder (culinary grade)", "amount": "4", "unit": "g", "notes": None},
            {"ingredient_name": "Honey", "amount": "20", "unit": "ml", "notes": None},
            {"ingredient_name": "Vanilla extract", "amount": "2", "unit": "ml", "notes": None},
            {"ingredient_name": "Fresh strawberries (sliced)", "amount": "100", "unit": "g", "notes": None},
            {"ingredient_name": "Fresh blueberries", "amount": "80", "unit": "g", "notes": None},
            {"ingredient_name": "Fresh lime juice", "amount": "10", "unit": "ml", "notes": None},
            {"ingredient_name": "Chia seeds", "amount": "6", "unit": "g", "notes": "optional garnish"}
        ],
        "steps": [
            {"step_number": 1, "description": "Preheat oven to 170°C / 338°F. Combine oats, almonds, coconut, map