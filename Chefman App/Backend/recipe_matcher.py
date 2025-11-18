"""
AI Recipe Matcher
根据用户的饮食需求、材料和工具，匹配最适合的菜谱
"""

import json
from typing import Dict, List, Optional, Tuple
from firebase_db import db, doc_to_dict


def calculate_recipe_score(
    recipe: Dict,
    diet_requirements: List[str],
    available_ingredients: List[str],
    available_equipment: List[str],
    openai_client=None
) -> float:
    """
    计算菜谱的匹配分数
    
    Args:
        recipe: 菜谱数据
        diet_requirements: 饮食需求列表（如 ["Vegan", "Gluten-Free"]）
        available_ingredients: 可用材料列表
        available_equipment: 可用工具列表
        openai_client: OpenAI客户端（可选，用于增强匹配）
    
    Returns:
        匹配分数 (0.0 - 1.0)
    """
    score = 0.0
    max_score = 0.0
    
    # 1. 饮食需求匹配 (权重: 40%)
    diet_weight = 0.4
    max_score += diet_weight
    
    recipe_diet_types = recipe.get('diet_types', [])
    if diet_requirements:
        # 计算匹配的饮食类型数量
        matched_diets = set(diet_requirements) & set(recipe_diet_types)
        if matched_diets:
            # 如果菜谱符合所有要求的饮食类型，得满分
            if len(matched_diets) == len(diet_requirements):
                score += diet_weight
            else:
                # 部分匹配，按比例给分
                score += diet_weight * (len(matched_diets) / len(diet_requirements))
        # 如果菜谱有不符合的饮食类型（比如要求Vegan但菜谱有肉），扣分
        conflicting_diets = set(recipe_diet_types) - set(diet_requirements)
        if conflicting_diets and not matched_diets:
            score -= diet_weight * 0.5  # 严重冲突，扣分
    else:
        # 没有饮食要求，给基础分
        score += diet_weight * 0.5
    
    # 2. 材料匹配 (权重: 40%)
    ingredient_weight = 0.4
    max_score += ingredient_weight
    
    recipe_ingredients = [ing.get('ingredient_name', '').lower() for ing in recipe.get('ingredients', [])]
    if available_ingredients:
        available_ingredients_lower = [ing.lower() for ing in available_ingredients]
        
        # 计算可用材料覆盖的菜谱材料比例
        matched_ingredients = []
        for recipe_ing in recipe_ingredients:
            # 模糊匹配：检查是否包含关键词
            for avail_ing in available_ingredients_lower:
                if avail_ing in recipe_ing or recipe_ing in avail_ing:
                    matched_ingredients.append(recipe_ing)
                    break
        
        if recipe_ingredients:
            ingredient_match_ratio = len(matched_ingredients) / len(recipe_ingredients)
            score += ingredient_weight * ingredient_match_ratio
        else:
            score += ingredient_weight * 0.5
    else:
        # 没有材料限制，给基础分
        score += ingredient_weight * 0.5
    
    # 3. 工具匹配 (权重: 20%)
    equipment_weight = 0.2
    max_score += equipment_weight
    
    recipe_equipment = [eq.get('equipment_name', '').lower() for eq in recipe.get('equipment', [])]
    if available_equipment:
        available_equipment_lower = [eq.lower() for eq in available_equipment]
        
        # 计算可用工具覆盖的菜谱工具比例
        matched_equipment = []
        for recipe_eq in recipe_equipment:
            for avail_eq in available_equipment_lower:
                if avail_eq in recipe_eq or recipe_eq in avail_eq:
                    matched_equipment.append(recipe_eq)
                    break
        
        if recipe_equipment:
            equipment_match_ratio = len(matched_equipment) / len(recipe_equipment)
            score += equipment_weight * equipment_match_ratio
        else:
            # 菜谱不需要特殊工具，给满分
            score += equipment_weight
    else:
        # 没有工具限制，给基础分
        score += equipment_weight * 0.5
    
    # 确保分数在 0.0 - 1.0 范围内
    score = max(0.0, min(1.0, score))
    
    return score


def match_recipes_with_ai(
    openai_client,
    diet_requirements: List[str],
    available_ingredients: List[str],
    available_equipment: List[str],
    recipe_descriptions: List[Dict]
) -> List[Tuple[Dict, float]]:
    """
    使用OpenAI增强匹配算法
    
    Args:
        openai_client: OpenAI客户端
        diet_requirements: 饮食需求
        available_ingredients: 可用材料
        available_equipment: 可用工具
        recipe_descriptions: 菜谱描述列表（包含id, title, ingredients, equipment, diet_types）
    
    Returns:
        排序后的菜谱列表（菜谱数据，匹配分数）
    """
    if not openai_client or not recipe_descriptions:
        return []
    
    try:
        # 准备提示词
        diet_text = ", ".join(diet_requirements) if diet_requirements else "无特殊要求"
        ingredients_text = ", ".join(available_ingredients) if available_ingredients else "无限制"
        equipment_text = ", ".join(available_equipment) if available_equipment else "无限制"
        
        # 准备菜谱列表
        recipes_text = ""
        for i, recipe in enumerate(recipe_descriptions[:20]):  # 限制数量以避免token过多
            recipe_info = f"""
菜谱 {i+1}:
- ID: {recipe.get('id')}
- 标题: {recipe.get('title', '')}
- 材料: {', '.join([ing.get('ingredient_name', '') for ing in recipe.get('ingredients', [])])}
- 工具: {', '.join([eq.get('equipment_name', '') for eq in recipe.get('equipment', [])])}
- 饮食类型: {', '.join(recipe.get('diet_types', []))}
"""
            recipes_text += recipe_info
        
        prompt = f"""你是一个专业的食谱推荐助手。根据用户的需求，为以下菜谱评分（0-100分），并返回JSON格式的结果。

用户需求：
- 饮食需求: {diet_text}
- 可用材料: {ingredients_text}
- 可用工具: {equipment_text}

菜谱列表:
{recipes_text}

请为每个菜谱评分，考虑：
1. 饮食需求匹配度（40%权重）
2. 材料可用性（40%权重）
3. 工具可用性（20%权重）

返回JSON格式，结构如下：
{{
    "scores": [
        {{"id": <recipe_id>, "score": <0-100>}},
        ...
    ]
}}

只返回JSON，不要其他文字。"""

        response = openai_client.chat.completions.create(
            model="gpt-3.5-turbo",
            messages=[
                {"role": "system", "content": "你是一个专业的食谱推荐助手。根据用户需求为菜谱评分，返回JSON格式。"},
                {"role": "user", "content": prompt}
            ],
            temperature=0.3,
            max_tokens=2000
        )
        
        response_text = response.choices[0].message.content.strip()
        
        # 清理响应文本
        if response_text.startswith("```"):
            response_text = response_text.split("```")[1]
            if response_text.startswith("json"):
                response_text = response_text[4:]
            response_text = response_text.strip()
        
        result = json.loads(response_text)
        scores_dict = {item['id']: item['score'] / 100.0 for item in result.get('scores', [])}
        
        # 将分数应用到菜谱
        scored_recipes = []
        for recipe in recipe_descriptions:
            recipe_id = recipe.get('id')
            if recipe_id in scores_dict:
                scored_recipes.append((recipe, scores_dict[recipe_id]))
            else:
                # 如果没有AI评分，使用基础算法
                score = calculate_recipe_score(
                    recipe, diet_requirements, available_ingredients, available_equipment
                )
                scored_recipes.append((recipe, score))
        
        return scored_recipes
        
    except Exception as e:
        print(f"❌ AI匹配错误: {str(e)}")
        # 回退到基础算法
        scored_recipes = []
        for recipe in recipe_descriptions:
            score = calculate_recipe_score(
                recipe, diet_requirements, available_ingredients, available_equipment
            )
            scored_recipes.append((recipe, score))
        return scored_recipes


def find_matching_recipes(
    diet_requirements: Optional[List[str]] = None,
    available_ingredients: Optional[List[str]] = None,
    available_equipment: Optional[List[str]] = None,
    limit: int = 10,
    openai_client=None
) -> List[Tuple[Dict, float]]:
    """
    从数据库中查找匹配的菜谱
    
    Args:
        diet_requirements: 饮食需求列表
        available_ingredients: 可用材料列表
        available_equipment: 可用工具列表
        limit: 返回结果数量限制
        openai_client: OpenAI客户端（可选）
    
    Returns:
        排序后的菜谱列表（菜谱数据，匹配分数）
    """
    # 默认值
    diet_requirements = diet_requirements or []
    available_ingredients = available_ingredients or []
    available_equipment = available_equipment or []
    
    # 从Firestore获取所有菜谱
    recipes_ref = db.collection('recipes')
    all_recipes = []
    
    # Use .get() with limit instead of .stream() for better performance
    try:
        docs = recipes_ref.limit(1000).get()  # Limit to 1000 for performance
        for doc in docs:
            recipe_data = doc_to_dict(doc)
            if recipe_data:
                # 转换ID
                doc_id = doc.id
                if doc_id.isdigit():
                    recipe_id = int(doc_id)
                else:
                    recipe_id = abs(hash(doc_id)) % (10**9)
                recipe_data['id'] = recipe_id
                all_recipes.append(recipe_data)
    except Exception as e:
        print(f"⚠️ Error loading recipes: {e}")
    
    if not all_recipes:
        return []
    
    # 使用AI增强匹配（如果可用）
    if openai_client and len(all_recipes) <= 20:
        scored_recipes = match_recipes_with_ai(
            openai_client,
            diet_requirements,
            available_ingredients,
            available_equipment,
            all_recipes
        )
    else:
        # 使用基础匹配算法
        scored_recipes = []
        for recipe in all_recipes:
            score = calculate_recipe_score(
                recipe,
                diet_requirements,
                available_ingredients,
                available_equipment
            )
            scored_recipes.append((recipe, score))
    
    # 按分数排序（降序）
    scored_recipes.sort(key=lambda x: x[1], reverse=True)
    
    # 返回前limit个结果
    return scored_recipes[:limit]

