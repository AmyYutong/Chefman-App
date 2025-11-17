# AI 菜谱匹配助手使用说明

## 功能概述

AI 菜谱匹配助手可以根据用户提供的以下信息，智能匹配最适合的菜谱：

1. **饮食需求**：如 Vegan、Keto、Gluten-Free 等
2. **可用材料**：用户手头已有的食材
3. **可用工具**：用户拥有的烹饪工具

## API 端点

### POST `/recipes/match`

根据用户需求匹配菜谱

#### 请求体

```json
{
  "diet_requirements": ["Vegan", "Gluten-Free"],
  "available_ingredients": ["tomato", "onion", "garlic"],
  "available_equipment": ["oven", "pan"],
  "limit": 10
}
```

#### 参数说明

- `diet_requirements` (可选): 饮食需求列表
  - 支持的饮食类型：Keto, GLP-1, Vegan, Vegetarian, Paleo, Mediterranean, Low-Carb, High-Protein, Gluten-Free, Dairy-Free, Low-Sodium, Heart-Healthy
- `available_ingredients` (可选): 可用材料列表
- `available_equipment` (可选): 可用工具列表
- `limit` (可选): 返回结果数量，默认 10

#### 响应示例

```json
[
  {
    "recipe": {
      "id": 123,
      "title": "番茄意面",
      "description": "美味的素食意面",
      "ingredients": [...],
      "steps": [...],
      "equipment": [...],
      "diet_types": ["Vegan", "Vegetarian"],
      ...
    },
    "match_score": 0.85,
    "match_reason": "符合饮食需求: Vegan；使用您提供的材料: tomato, onion, garlic"
  }
]
```

#### 响应字段说明

- `recipe`: 完整的菜谱信息
- `match_score`: 匹配分数 (0.0 - 1.0)，分数越高匹配度越高
- `match_reason`: 匹配理由说明

## 匹配算法

### 评分权重

1. **饮食需求匹配** (40% 权重)
   - 如果菜谱符合所有要求的饮食类型，得满分
   - 部分匹配按比例给分
   - 如果菜谱有冲突的饮食类型，会扣分

2. **材料匹配** (40% 权重)
   - 计算可用材料覆盖菜谱所需材料的比例
   - 支持模糊匹配（关键词匹配）

3. **工具匹配** (20% 权重)
   - 计算可用工具覆盖菜谱所需工具的比例
   - 如果菜谱不需要特殊工具，得满分

### AI 增强匹配

如果配置了 OpenAI API Key，系统会使用 GPT-3.5-turbo 进行更智能的匹配：

- 当菜谱数量 ≤ 20 时，使用 AI 增强匹配
- AI 会综合考虑所有因素，给出更准确的评分
- 如果 AI 不可用，自动回退到基础匹配算法

## 使用示例

### cURL 示例

```bash
curl -X POST "http://127.0.0.1:8000/recipes/match" \
  -H "Content-Type: application/json" \
  -d '{
    "diet_requirements": ["Vegan"],
    "available_ingredients": ["tomato", "onion", "garlic", "pasta"],
    "available_equipment": ["pot", "pan"],
    "limit": 5
  }'
```

### Python 示例

```python
import requests

url = "http://127.0.0.1:8000/recipes/match"
data = {
    "diet_requirements": ["Vegan", "Gluten-Free"],
    "available_ingredients": ["tomato", "onion", "garlic"],
    "available_equipment": ["oven"],
    "limit": 10
}

response = requests.post(url, json=data)
matched_recipes = response.json()

for match in matched_recipes:
    print(f"菜谱: {match['recipe']['title']}")
    print(f"匹配分数: {match['match_score']}")
    print(f"匹配理由: {match['match_reason']}")
    print()
```

### JavaScript 示例

```javascript
const response = await fetch('http://127.0.0.1:8000/recipes/match', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    diet_requirements: ['Vegan'],
    available_ingredients: ['tomato', 'onion', 'garlic'],
    available_equipment: ['oven'],
    limit: 10
  })
});

const matchedRecipes = await response.json();
matchedRecipes.forEach(match => {
  console.log(`菜谱: ${match.recipe.title}`);
  console.log(`匹配分数: ${match.match_score}`);
  console.log(`匹配理由: ${match.match_reason}`);
});
```

## 注意事项

1. **无需认证**：此 API 端点不需要用户登录，任何人都可以使用
2. **性能考虑**：如果数据库中有大量菜谱，建议设置合理的 `limit` 值
3. **AI 功能**：AI 增强匹配需要配置 OpenAI API Key，否则使用基础匹配算法
4. **匹配精度**：材料匹配使用关键词匹配，可能不够精确，建议提供准确的材料名称

## 故障排除

### 问题：返回空列表

- 检查数据库中是否有菜谱
- 尝试放宽匹配条件（减少饮食需求、增加可用材料）

### 问题：匹配分数都很低

- 可能是可用材料或工具太少
- 尝试提供更多相关材料
- 检查饮食需求是否过于严格

### 问题：AI 匹配不工作

- 检查是否设置了 `OPENAI_API_KEY` 环境变量
- 查看服务器日志确认 OpenAI 客户端是否初始化成功
- 如果 AI 不可用，系统会自动使用基础匹配算法

## 未来改进

- [ ] 支持更精确的材料匹配（同义词、别名）
- [ ] 支持材料替代建议
- [ ] 支持用户偏好学习（基于历史选择）
- [ ] 支持多语言材料名称匹配
- [ ] 添加材料数量匹配（不仅匹配材料名称，还考虑数量）

