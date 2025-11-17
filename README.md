# Chefman Studio App

Chefman Studio App is a modern iOS application for recipe sharing and management.  
It enables users to create, share, and save recipes, and provides AI-powered personalized recommendations.

---

## 1. Overview

Chefman Studio is a full-featured social recipe application designed for food lovers, creators, and everyday cooks.  
Users can publish their own recipes, explore others’ creations, and interact through likes, comments, and follows.  
The app also integrates AI to analyze nutrition, detect diet types, and recommend recipes based on ingredients and tools.

---

## 2. Core Features

### 2.1 User Features
- User registration and login (JWT authentication)  
- Profile management (avatar, bio, gender, etc.)  
- Follow and unfollow other users  
- View followers and following lists  

### 2.2 Recipe Features
- Create recipes with title, description, images, ingredients, steps, and required tools  
- Browse and search recipes  
- View detailed recipe pages  
- Like, comment, and favorite recipes  
- Add recipes to a personal to-do list and mark them as completed  

### 2.3 AI Features
- Automatically calculate calorie information  
- Identify suitable diet types (Keto, Vegan, GLP-1, etc.)  
- Recommend recipes based on available ingredients and kitchen tools  

### 2.4 Additional Features
- Upload recipe, step, and profile images  
- Support for cooking step videos  
- Step-by-step cooking guidance  
- Real-time interaction statistics (likes, comments, favorites)  

---

## 3. Tech Stack

### Backend
- Framework: FastAPI (Python)  
- Database: Firebase Firestore  
- Authentication: JWT (JSON Web Tokens)  
- Password Encryption: bcrypt  
- AI Integration: OpenAI GPT-3.5-turbo  
- File Storage: Local system (can be extended to cloud)  

### Frontend
- Framework: SwiftUI  
- Language: Swift  
- Minimum iOS Version: 15.0+  
- Dependency Management: Swift Package Manager  
- Firebase Core: For app initialization  

---

## 4. Project Structure

Chefman Studio App/
├── Backend/
│ ├── main.py
│ ├── firebase_db.py
│ ├── analyze_recipe.py
│ ├── image_storage.py
│ ├── requirements.txt
│ ├── README_RUN.md
│ ├── README_OPENAI_SETUP.md
│ ├── favorites_and_todo_guide.md
│ └── uploads/
│
├── ChefmanApp/
│ ├── ChefmanApp/
│ │ ├── ChefmanApp.swift
│ │ ├── MainCode.swift
│ │ ├── MainAppViews.swift
│ │ ├── LoginView.swift
│ │ ├── SignUpView.swift
│ │ ├── DetailedSignUpView.swift
│ │ ├── RecipeDetailView.swift
│ │ ├── UploadRecipeView.swift
│ │ ├── StepByStepView.swift
│ │ ├── StepDetailView.swift
│ │ ├── UserProfileView.swift
│ │ ├── APIClient.swift
│ │ ├── APIConfig.swift
│ │ ├── RecipeModel.swift
│ │ ├── UserStorage.swift
│ │ ├── ChefmanLogo.swift
│ │ └── Assets.xcassets/
│ └── ChefmanApp.xcodeproj/
│
└── README.md


---

## 5. Quick Start Guide

### 5.1 Prerequisites
- Python 3.8 or higher  
- Xcode 14.0 or higher  
- Firebase project (with service account key)  
- OpenAI API key (optional for AI features)  

### 5.2 Backend Setup

1. Navigate to the backend directory:
   cd Backend
  Install dependencies:

  pip3 install -r requirements.txt


  Configure Firebase:

  Place your Firebase service key (e.g. firebase-adminsdk.json) in the Backend folder.

  Set the environment variable:

  export GOOGLE_APPLICATION_CREDENTIALS="firebase-adminsdk.json"


  (Optional) Configure OpenAI:

  export OPENAI_API_KEY="your-api-key-here"


  Run the backend server:

  uvicorn main:app --reload --host 127.0.0.1 --port 8000


  Access the API:

  Documentation: http://127.0.0.1:8000/docs

  Redoc UI: http://127.0.0.1:8000/redoc

5.3 iOS App Setup

  Open Xcode and load:

  ChefmanApp/ChefmanApp.xcodeproj


  Configure the API URL in APIConfig.swift:

  #if DEBUG
  static let baseURL = "http://127.0.0.1:8000"
  #else
  static let baseURL = "https://your-production-api.com"
  #endif


  Run the application:

  Select your simulator or connected device

  Press Command + R to build and launch

  For real-device testing:

  Replace 127.0.0.1 with your Mac’s local IP (e.g. http://192.168.1.100:8000)

  Ensure both Mac and iPhone are on the same Wi-Fi network

  Allow port 8000 through the firewall

6. API Reference
  Authentication

  POST /register – Register a new user

  POST /login – User login

  GET /users/me – Get current user info

  PUT /users/me – Update user info

  Recipes

  GET /recipes – Retrieve all recipes

  GET /recipes/{recipe_id} – Retrieve a specific recipe

  POST /recipes – Create a new recipe

  GET /users/me/recipes – Get current user’s recipes

  Interactions

  POST /recipes/{recipe_id}/like – Like a recipe

  DELETE /recipes/{recipe_id}/like – Remove like

  POST /favorites?recipe_id={id} – Add to favorites

  DELETE /favorites/{recipe_id} – Remove from favorites

  POST /todo-list?recipe_id={id} – Add to to-do list

  DELETE /todo-list/{recipe_id} – Remove from to-do list

  PUT /todo-list/{recipe_id}/complete – Mark recipe as completed

  POST /recipes/{recipe_id}/comments – Add a comment

  GET /recipes/{recipe_id}/comments – Retrieve comments

  User Social Features

  POST /users/{user_id}/follow – Follow a user

  DELETE /users/{user_id}/follow – Unfollow a user

  GET /users/me/followers – Get followers

  GET /users/me/following – Get following

  GET /users/{user_id}/profile – Get user profile

  File Upload

  POST /upload/image – Upload images (recipes, steps, or profiles)

7. Database Design (Firestore)

  users – User profiles and authentication

  recipes – Recipe details and metadata

  likes – Like records

  comments – Recipe comments

  favorites – Saved recipes

  todo_list – To-do recipes with completion status

  follows – User follow relationships

  Refer to Backend/favorites_and_todo_guide.md for detailed schema definitions.

8. Security

  JWT token-based authentication

  Passwords hashed with bcrypt

  All endpoints (except register/login) require authentication

  User data is securely isolated by account

9. Development Guidelines
  Adding New Features

  Add new endpoints in Backend/main.py

  Update APIClient.swift to include the corresponding API calls

  Create or update SwiftUI views in ChefmanApp

  Coding Standards

  Follow Swift official style guide

  Follow PEP 8 for Python code

  Use descriptive variable and function names

  Write meaningful inline comments

10. Troubleshooting
  Backend

  Error: ModuleNotFoundError: No module named 'firebase_admin'
  Fix:

  pip3 install -r requirements.txt


  Error: Firebase connection failed

  Check if the service key file exists

  Ensure the environment variable is correctly set

  Error: Port 8000 in use

  lsof -ti:8000
    kill -9 $(lsof -ti:8000)

  iOS

  Error: Cannot connect to server

  Ensure the backend is running

  Check APIConfig.swift for the correct base URL

  Use your Mac’s IP for real-device testing

  Error: Build or compile failure
  Clean the build folder (Command + Shift + K)
  Rebuild the project (Command + B)

11. License

  This project is private and not open to public contribution or distribution.

12. Support

  If you encounter any issues:
  Check backend server logs
  Review Xcode console output
  Visit the API documentation at http://127.0.0.1:8000/docs

13. Test Account
  Username: Test1115
  Password: Test1115

  You can also try the create account page to create an account yourself and login

Last Updated: November 2024