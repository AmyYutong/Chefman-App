# OpenAI API Setup for Recipe Analysis

This application uses OpenAI's GPT API to automatically analyze recipes and calculate:
- Calories per serving
- Suitable diet types (Keto, GLP-1, Vegan, Vegetarian, etc.)

## Setup Instructions

### 1. Get OpenAI API Key

1. Go to [OpenAI Platform](https://platform.openai.com/)
2. Sign up or log in
3. Navigate to API Keys section
4. Create a new API key
5. Copy the API key (it starts with `sk-`)

### 2. Set Environment Variable

#### On macOS/Linux:
```bash
export OPENAI_API_KEY="your-api-key-here"
```

#### On Windows (Command Prompt):
```cmd
set OPENAI_API_KEY=your-api-key-here
```

#### On Windows (PowerShell):
```powershell
$env:OPENAI_API_KEY="your-api-key-here"
```

### 3. For Permanent Setup

Add the environment variable to your shell configuration file:

#### For bash/zsh (macOS/Linux):
```bash
echo 'export OPENAI_API_KEY="your-api-key-here"' >> ~/.bashrc
# or for zsh:
echo 'export OPENAI_API_KEY="your-api-key-here"' >> ~/.zshrc
```

#### For Windows:
Add it through System Properties > Environment Variables

### 4. Install Dependencies

```bash
cd Backend
pip install -r requirements.txt
```

This will install `openai==1.3.0` along with other dependencies.

### 5. Verify Setup

Start the backend server:
```bash
cd Backend
uvicorn main:app --reload
```

You should see one of these messages:
- `✅ OpenAI client initialized` - Success!
- `⚠️ OPENAI_API_KEY not found in environment variables` - Check your environment variable setup
- `⚠️ OpenAI library not available` - Run `pip install openai`

## How It Works

When a recipe is created:
1. The backend sends recipe information (title, ingredients, servings) to OpenAI
2. OpenAI analyzes the recipe and returns:
   - Estimated calories per serving
   - List of suitable diet types
3. This information is stored in Firebase and displayed in the app

## Supported Diet Types

- **Keto** - Ketogenic diet
- **GLP-1** - GLP-1 diet (for weight management)
- **Vegan** - No animal products
- **Vegetarian** - No meat, may include dairy/eggs
- **Paleo** - Paleolithic diet
- **Mediterranean** - Mediterranean diet
- **Low-Carb** - Low carbohydrate diet
- **High-Protein** - High protein diet
- **Gluten-Free** - No gluten
- **Dairy-Free** - No dairy products
- **Low-Sodium** - Low sodium diet
- **Heart-Healthy** - Heart-healthy diet

## Fallback Behavior

If OpenAI API is not available or fails:
- The system will use a simple rule-based analysis
- This provides basic diet type detection (Vegan, Vegetarian, Gluten-Free, Dairy-Free)
- Calories will not be calculated in fallback mode

## Cost Considerations

- OpenAI API usage is charged per token
- Recipe analysis typically uses ~200-300 tokens per recipe
- Check [OpenAI Pricing](https://openai.com/pricing) for current rates
- Consider setting usage limits in your OpenAI account

## Troubleshooting

### "OPENAI_API_KEY not found"
- Make sure you've set the environment variable
- Restart your terminal/server after setting the variable
- Check that the variable name is exactly `OPENAI_API_KEY`

### "OpenAI library not available"
- Run: `pip install openai`
- Make sure you're in the correct Python environment

### API Errors
- Check your OpenAI account has credits
- Verify the API key is correct
- Check OpenAI status page for service issues

