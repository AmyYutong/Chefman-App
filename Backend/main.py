# FastAPI Backend using Firebase Firestore
# This replaces the MySQL-based main.py

from fastapi import FastAPI, Depends, HTTPException, status, UploadFile, File, Form, Query
from fastapi.security import OAuth2PasswordBearer
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
from pydantic import BaseModel
from passlib.context import CryptContext
from datetime import datetime, timedelta, date
from jose import JWTError, jwt
from typing import Optional, List, Dict, Any
import firebase_db
from firebase_db import db, convert_to_firestore_datetime, doc_to_dict
from firebase_admin import firestore
import bcrypt
import os
import json
try:
    from openai import OpenAI
    OPENAI_AVAILABLE = True
except ImportError:
    OPENAI_AVAILABLE = False
    print("⚠️ OpenAI library not available. Recipe analysis will be disabled.")
from analyze_recipe import analyze_recipe_with_openai, analyze_recipe_simple
from recipe_matcher import find_matching_recipes

app = FastAPI(title="Chefman Studio API", version="1.0.0")

# Initialize OpenAI client (if API key is available)
openai_client = None
if OPENAI_AVAILABLE:
    openai_api_key = os.getenv("OPENAI_API_KEY")
    if openai_api_key:
        openai_client = OpenAI(api_key=openai_api_key)
        print("✅ OpenAI client initialized")
    else:
        print("⚠️ OPENAI_API_KEY not found in environment variables")

# Mount static files for serving images
app.mount("/images", StaticFiles(directory="uploads"), name="images")

# Password hashing
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# JWT settings
SECRET_KEY = "your-secret-key-change-this-in-production"
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30

# OAuth2 scheme
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="login")

# Pydantic schemas (same as before)
class UserCreate(BaseModel):
    username: str
    email: str
    password: str
    phone_number: Optional[str] = None
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    gender: str = "Not specified"
    birth_date: Optional[str] = None
    bio: Optional[str] = None
    profile_image_url: Optional[str] = None
    address: Optional[str] = None
    city: Optional[str] = None
    country: Optional[str] = None
    postal_code: Optional[str] = None

class UserLogin(BaseModel):
    username: str
    password: str

class UserUpdate(BaseModel):
    username: Optional[str] = None
    email: Optional[str] = None
    phone_number: Optional[str] = None
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    gender: Optional[str] = None
    birth_date: Optional[datetime] = None
    bio: Optional[str] = None
    profile_image_url: Optional[str] = None
    address: Optional[str] = None
    city: Optional[str] = None
    country: Optional[str] = None
    postal_code: Optional[str] = None

class UserResponse(BaseModel):
    id: int
    username: str
    email: str
    phone_number: Optional[str] = None
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    gender: str = "Not specified"
    birth_date: Optional[datetime] = None
    bio: Optional[str] = None
    profile_image_url: Optional[str] = None
    address: Optional[str] = None
    city: Optional[str] = None
    country: Optional[str] = None
    postal_code: Optional[str] = None
    is_verified: bool = False
    is_active: bool = True
    last_login_at: Optional[datetime] = None
    created_at: datetime
    updated_at: Optional[datetime] = None

class Token(BaseModel):
    access_token: str
    token_type: str

class AuthResponse(BaseModel):
    access_token: str
    token_type: str
    user: UserResponse

class RecipeIngredientCreate(BaseModel):
    ingredient_name: str
    amount: Optional[str] = None
    unit: str = "g"
    notes: Optional[str] = None

class RecipeStepCreate(BaseModel):
    step_number: int
    description: str
    duration: Optional[str] = None
    temperature: Optional[str] = None
    notes: Optional[str] = None
    image_url: Optional[str] = None  # 步骤图片（可选）
    video_url: Optional[str] = None  # 步骤视频（可选）

class RecipeEquipmentCreate(BaseModel):
    equipment_name: str
    brand: Optional[str] = None
    is_chefman: bool = False

class RecipeCreate(BaseModel):
    title: str
    description: Optional[str] = None
    image_url: Optional[str] = None
    recipe_type: str = "Dish"
    cuisine_type: str = "Other"
    prep_time: Optional[str] = None
    cook_time: Optional[str] = None
    total_time: Optional[str] = None
    servings: int = 1
    difficulty: str = "Easy"
    ingredients: List[RecipeIngredientCreate] = []
    steps: List[RecipeStepCreate] = []
    equipment: List[RecipeEquipmentCreate] = []

class RecipeIngredientResponse(BaseModel):
    id: Optional[int] = None
    ingredient_name: str
    amount: Optional[str] = None
    unit: str = "g"
    notes: Optional[str] = None

class RecipeStepResponse(BaseModel):
    id: Optional[int] = None
    step_number: int
    description: str
    duration: Optional[str] = None
    temperature: Optional[str] = None
    notes: Optional[str] = None
    image_url: Optional[str] = None  # 步骤图片（可选）
    video_url: Optional[str] = None  # 步骤视频（可选）

class RecipeEquipmentResponse(BaseModel):
    id: Optional[int] = None
    equipment_name: str
    brand: Optional[str] = None
    is_chefman: bool = False

class RecipeResponse(BaseModel):
    id: int
    title: str
    description: Optional[str] = None
    image_url: Optional[str] = None
    recipe_type: str
    cuisine_type: str
    prep_time: Optional[str] = None
    cook_time: Optional[str] = None
    total_time: Optional[str] = None
    servings: int
    difficulty: str
    created_at: datetime
    updated_at: Optional[datetime] = None
    ingredients: List[RecipeIngredientResponse] = []
    steps: List[RecipeStepResponse] = []
    equipment: List[RecipeEquipmentResponse] = []
    creator_id: Optional[int] = None
    creator_username: Optional[str] = None
    likes_count: Optional[int] = 0
    comments_count: Optional[int] = 0
    favorites_count: Optional[int] = 0
    calories_per_serving: Optional[int] = None
    diet_types: Optional[List[str]] = []

class CommentCreate(BaseModel):
    content: str

class CommentResponse(BaseModel):
    id: int
    user_id: int
    recipe_id: int
    content: str
    created_at: datetime
    updated_at: datetime
    user: dict

class RecipeMatchRequest(BaseModel):
    diet_requirements: Optional[List[str]] = []
    available_ingredients: Optional[List[str]] = []
    available_equipment: Optional[List[str]] = []
    limit: int = 10

class MatchedRecipeResponse(BaseModel):
    recipe: RecipeResponse
    match_score: float
    match_reason: Optional[str] = None

# Helper functions
def verify_password(plain_password, hashed_password):
    """验证密码，直接使用 bcrypt 避免 passlib 版本问题"""
    if not hashed_password:
        print("❌ 密码哈希为空")
        return False
    
    # 检查哈希格式
    if not hashed_password.startswith('$2b$') and not hashed_password.startswith('$2a$'):
        print(f"❌ 密码哈希格式错误: {hashed_password[:20]}...")
        return False
    
    # 限制密码长度
    if len(plain_password.encode('utf-8')) > 72:
        plain_password = plain_password[:72]
    
    try:
        # 直接使用 bcrypt 验证
        import bcrypt
        # 确保哈希是字符串类型
        if isinstance(hashed_password, bytes):
            hashed_password = hashed_password.decode('utf-8')
        
        result = bcrypt.checkpw(plain_password.encode('utf-8'), hashed_password.encode('utf-8'))
        if not result:
            print(f"❌ 密码验证失败: 密码长度={len(plain_password)}, 哈希长度={len(hashed_password)}")
        return result
    except Exception as e:
        print(f"❌ Password verification error: {e}")
        print(f"   密码类型: {type(plain_password)}, 哈希类型: {type(hashed_password)}")
        # 如果 bcrypt 失败，尝试使用 passlib 作为后备
        try:
            return pwd_context.verify(plain_password, hashed_password)
        except Exception as e2:
            print(f"❌ Passlib 验证也失败: {e2}")
            return False

def get_password_hash(password):
    """生成密码哈希，直接使用 bcrypt"""
    if len(password.encode('utf-8')) > 72:
        password = password[:72]
    try:
        # 直接使用 bcrypt 生成哈希
        import bcrypt
        return bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
    except Exception as e:
        print(f"❌ Password hashing error: {e}")
        # 如果 bcrypt 失败，使用 passlib 作为后备
        return pwd_context.hash(password)

def authenticate_user(username: str, password: str):
    """Authenticate user from Firestore"""
    users_ref = db.collection('users')
    query = users_ref.where('username', '==', username).limit(1).stream()
    
    for doc in query:
        user_data = doc_to_dict(doc)
        password_hash = user_data.get('password_hash', '')
        
        # Debug logging
        print(f"🔍 登录尝试: 用户名={username}")
        print(f"🔍 密码哈希存在: {bool(password_hash)}")
        print(f"🔍 密码哈希长度: {len(password_hash) if password_hash else 0}")
        
        if user_data:
            is_valid = verify_password(password, password_hash)
            print(f"🔍 密码验证结果: {is_valid}")
            if is_valid:
                return user_data
            else:
                print(f"❌ 密码验证失败: 用户名={username}")
        else:
            print(f"❌ 用户数据为空: 用户名={username}")
    
    print(f"❌ 未找到用户: 用户名={username}")
    return None

def create_access_token(data: dict, expires_delta: timedelta = None):
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=15)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

def get_current_user(token: str = Depends(oauth2_scheme)):
    """Get current user from JWT token"""
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        username: str = payload.get("sub")
        if username is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception
    
    # Get user from Firestore
    users_ref = db.collection('users')
    query = users_ref.where('username', '==', username).limit(1).stream()
    
    for doc in query:
        user_data = doc_to_dict(doc)
        if user_data:
            # Convert to dict format for compatibility
            return user_data
    raise credentials_exception

def find_recipe_document(recipe_id: int):
    """Find a recipe document by recipe_id (tries multiple methods)"""
    recipes_ref = db.collection('recipes')
    
    # Method 1: Try to find by document ID (as string)
    recipe_doc = recipes_ref.document(str(recipe_id)).get()
    if recipe_doc.exists:
        return recipe_doc
    
    # Method 2: Try to find by querying the 'id' field
    query = recipes_ref.where('id', '==', recipe_id).limit(1).stream()
    for doc in query:
        return doc
    
    # Method 3: Try to find by document ID that matches the integer or hash
    all_docs = recipes_ref.stream()
    for doc in all_docs:
        doc_id = doc.id
        # Check if document ID matches recipe_id
        if doc_id.isdigit() and int(doc_id) == recipe_id:
            return doc
        # Check if hash of document ID matches recipe_id
        elif abs(hash(doc_id)) % (10**9) == recipe_id:
            return doc
    
    # Not found
    return None

def parse_creator_id(creator_id_value):
    """Parse creator_id to integer, handling string or integer inputs"""
    if creator_id_value is None:
        return None
    if isinstance(creator_id_value, int):
        return creator_id_value
    if isinstance(creator_id_value, str):
        # Try to parse as integer
        if creator_id_value.isdigit():
            return int(creator_id_value)
        # If it's a Firestore document ID (non-numeric), convert to hash
        return abs(hash(creator_id_value)) % (10**9)
    # For any other type, try to convert
    try:
        return int(creator_id_value)
    except (ValueError, TypeError):
        return None

def get_recipe_counts(recipe_id: int) -> dict:
    """Get likes, comments, favorites, and completed count for a recipe"""
    likes_ref = db.collection('likes')
    comments_ref = db.collection('comments')
    favorites_ref = db.collection('favorites')
    todos_ref = db.collection('todo_list')
    
    # Count likes
    likes_query = likes_ref.where('recipe_id', '==', recipe_id).stream()
    likes_count = len(list(likes_query))
    
    # Count comments
    comments_query = comments_ref.where('recipe_id', '==', recipe_id).stream()
    comments_count = len(list(comments_query))
    
    # Count favorites
    favorites_query = favorites_ref.where('recipe_id', '==', recipe_id).stream()
    favorites_count = len(list(favorites_query))
    
    # Count completed (todo items with completed=True)
    completed_query = todos_ref.where('recipe_id', '==', recipe_id).where('completed', '==', True).stream()
    todo_count = len(list(completed_query))
    
    return {
        'likes_count': likes_count,
        'comments_count': comments_count,
        'favorites_count': favorites_count,
        'todo_count': todo_count
    }

# API Endpoints

@app.get("/")
def read_root():
    return {"message": "Chefman Studio API", "version": "1.0.0", "database": "Firebase Firestore"}

@app.post("/register", response_model=UserResponse)
def register(user: UserCreate):
    """Register a new user"""
    users_ref = db.collection('users')
    
    try:
        # Check if username already exists
        username_query = users_ref.where('username', '==', user.username).limit(1).stream()
        if any(username_query):
            raise HTTPException(status_code=400, detail="Username already exists")
        
        # Check if email already exists
        email_query = users_ref.where('email', '==', user.email).limit(1).stream()
        if any(email_query):
            raise HTTPException(status_code=400, detail="Email already exists")
        
        # Check if phone number already exists (if provided)
        if user.phone_number:
            phone_query = users_ref.where('phone_number', '==', user.phone_number).limit(1).stream()
            if any(phone_query):
                raise HTTPException(status_code=400, detail="Phone number already exists")
        
        # Hash the password
        print(f"🔍 注册请求: 用户名='{user.username}', 密码长度={len(user.password)}")
        print(f"🔍 注册密码字节: {user.password.encode('utf-8')}")
        print(f"🔍 注册密码repr: {repr(user.password)}")
        hashed_password = get_password_hash(user.password)
        print(f"🔍 注册: 用户名={user.username}, 密码长度={len(user.password)}, 哈希={hashed_password[:30]}...")
        
        # Parse birth_date
        birth_date_parsed = None
        if user.birth_date:
            try:
                birth_date_parsed = datetime.strptime(user.birth_date, "%Y-%m-%d").date()
                birth_date_parsed = convert_to_firestore_datetime(birth_date_parsed)
            except ValueError as e:
                raise HTTPException(status_code=400, detail=f"Invalid birth date format: {str(e)}")
        
        # Create user data
        now = datetime.now()
        user_data = {
            'username': user.username,
            'email': user.email,
            'password': user.password,  # 存储明文密码用于显示（仅用于调试/测试）
            'password_hash': hashed_password,  # 存储密码哈希用于验证
            'phone_number': user.phone_number,
            'first_name': user.first_name,
            'last_name': user.last_name,
            'gender': user.gender,
            'birth_date': birth_date_parsed,
            'bio': user.bio,
            'profile_image_url': user.profile_image_url,
            'address': user.address,
            'city': user.city,
            'country': user.country,
            'postal_code': user.postal_code,
            'is_verified': False,
            'is_active': True,
            'last_login_at': None,
            'created_at': now,
            'updated_at': now
        }
        
        # Add to Firestore (use auto-generated ID)
        # If this fails, user won't be created (atomic operation)
        doc_ref = users_ref.add(user_data)[1]
        doc_id = doc_ref.id
        
        # Get the created document to return
        created_doc = users_ref.document(doc_id).get()
        if not created_doc.exists:
            raise HTTPException(status_code=500, detail="Failed to create user")
        
        user_data = doc_to_dict(created_doc)
        
        # Ensure ID is an integer for UserResponse
        # If doc_id is not a digit, we need to use a numeric ID
        # For now, try to convert, if fails, use hash of string as fallback
        try:
            user_id = int(doc_id) if doc_id.isdigit() else abs(hash(doc_id)) % (10**9)
        except:
            user_id = abs(hash(doc_id)) % (10**9)
        
        user_data['id'] = user_id
        
        # Convert to UserResponse format
        # 排除 password_hash 和 password（安全考虑，不返回密码相关字段）
        user_response_data = {k: v for k, v in user_data.items() if k not in ['password_hash', 'password']}
        
        # Ensure all required fields are present
        if 'created_at' not in user_response_data:
            user_response_data['created_at'] = now
        if 'updated_at' not in user_response_data:
            user_response_data['updated_at'] = now
        
        return UserResponse(**user_response_data)
        
    except HTTPException:
        # Re-raise HTTP exceptions (validation errors)
        raise
    except Exception as e:
        # If any other error occurs, log it and return error
        # User is NOT created at this point
        print(f"❌ Registration error: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")

@app.post("/login", response_model=AuthResponse)
def login(user_credentials: UserLogin):
    """Login user"""
    # Debug logging
    print(f"🔍 登录请求: 用户名='{user_credentials.username}', 密码长度={len(user_credentials.password)}")
    print(f"🔍 密码字节: {user_credentials.password.encode('utf-8')}")
    print(f"🔍 密码repr: {repr(user_credentials.password)}")
    
    user_data = authenticate_user(user_credentials.username, user_credentials.password)
    
    if not user_data:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # Get document ID for updating
    users_ref = db.collection('users')
    query = users_ref.where('username', '==', user_credentials.username).limit(1).stream()
    doc_id = None
    for doc in query:
        doc_id = doc.id
        break
    
    if doc_id:
        # Update last_login_at
        user_doc = users_ref.document(doc_id)
        user_doc.update({'last_login_at': datetime.now()})
        user_data['last_login_at'] = datetime.now()
    
    # Ensure ID is an integer for UserResponse
    user_id = user_data.get('id')
    if isinstance(user_id, str):
        # If ID is a string (Firestore document ID), convert to integer
        try:
            user_id = int(user_id) if user_id.isdigit() else abs(hash(user_id)) % (10**9)
        except:
            user_id = abs(hash(str(user_id))) % (10**9)
    elif not isinstance(user_id, int):
        # If ID is not an integer, convert it
        try:
            user_id = int(user_id) if str(user_id).isdigit() else abs(hash(str(user_id))) % (10**9)
        except:
            user_id = abs(hash(str(user_id))) % (10**9)
    
    user_data['id'] = user_id
    
    # Create access token
    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user_data['username']}, expires_delta=access_token_expires
    )
    
    # Create user response (exclude password_hash and password for security)
    user_response_data = {k: v for k, v in user_data.items() if k not in ['password_hash', 'password']}
    
    # Ensure all required fields are present
    if 'created_at' not in user_response_data:
        user_response_data['created_at'] = datetime.now()
    if 'updated_at' not in user_response_data:
        user_response_data['updated_at'] = datetime.now()
    
    user_response = UserResponse(**user_response_data)
    
    return AuthResponse(
        access_token=access_token,
        token_type="bearer",
        user=user_response
    )

@app.get("/users/me", response_model=UserResponse)
def read_users_me(current_user: dict = Depends(get_current_user)):
    """Get current user info"""
    user_data = {k: v for k, v in current_user.items() if k not in ['password_hash', 'password']}
    return UserResponse(**user_data)

@app.get("/users/{user_id}", response_model=UserResponse)
def get_user(user_id: int):
    """Get user by ID"""
    users_ref = db.collection('users')
    user_doc = users_ref.document(str(user_id)).get()
    
    if not user_doc.exists:
        raise HTTPException(status_code=404, detail="User not found")
    
    user_data = doc_to_dict(user_doc)
    if not user_data:
        raise HTTPException(status_code=404, detail="User not found")
    
    # Exclude password fields
    user_response_data = {k: v for k, v in user_data.items() if k not in ['password_hash', 'password']}
    return UserResponse(**user_response_data)

@app.get("/users/{user_id}/profile")
def get_user_profile(user_id: int, current_user: dict = Depends(get_current_user)):
    """Get user profile with statistics"""
    users_ref = db.collection('users')
    user_doc = users_ref.document(str(user_id)).get()
    
    if not user_doc.exists:
        raise HTTPException(status_code=404, detail="User not found")
    
    user_data = doc_to_dict(user_doc)
    if not user_data:
        raise HTTPException(status_code=404, detail="User not found")
    
    # Get user statistics
    # Get recipes created by this user
    recipes_ref = db.collection('recipes')
    user_recipes_query = recipes_ref.where('creator_id', '==', user_id).stream()
    recipes_count = len(list(user_recipes_query))
    
    # Get followers count
    follows_ref = db.collection('follows')
    followers_count = len(list(follows_ref.where('following_id', '==', user_id).stream()))
    
    # Get following count
    following_count = len(list(follows_ref.where('follower_id', '==', user_id).stream()))
    
    # Get total likes received
    user_recipes_query = recipes_ref.where('creator_id', '==', user_id).stream()
    recipe_ids = []
    for recipe_doc in user_recipes_query:
        doc_id = recipe_doc.id
        if doc_id.isdigit():
            recipe_id = int(doc_id)
        else:
            recipe_id = abs(hash(doc_id)) % (10**9)
        recipe_ids.append(recipe_id)
    
    total_likes = 0
    if recipe_ids:
        likes_ref = db.collection('likes')
        for recipe_id in recipe_ids:
            recipe_likes = likes_ref.where('recipe_id', '==', recipe_id).stream()
            total_likes += len(list(recipe_likes))
    
    return {
        "id": user_data.get('id', user_id),
        "username": user_data.get('username', 'Unknown'),
        "email": user_data.get('email'),
        "bio": user_data.get('bio'),
        "gender": user_data.get('gender'),
        "profile_image_url": user_data.get('profile_image_url'),
        "recipes_count": recipes_count,
        "followers_count": followers_count,
        "following_count": following_count,
        "total_likes_received": total_likes
    }

@app.get("/users/me/recipes")
def get_my_recipes(current_user: dict = Depends(get_current_user)):
    """Get recipes created by current user"""
    user_id = current_user['id']
    
    recipes_ref = db.collection('recipes')
    user_recipes_query = recipes_ref.where('creator_id', '==', user_id).stream()
    
    recipes = []
    for doc in user_recipes_query:
        recipe_data = doc_to_dict(doc)
        if recipe_data:
            # Use document ID as recipe_id
            doc_id = doc.id
            if doc_id.isdigit():
                recipe_id = int(doc_id)
            else:
                recipe_id = abs(hash(doc_id)) % (10**9)
            
            # Get counts for this recipe
            counts = get_recipe_counts(recipe_id)
            
            recipes.append(RecipeResponse(
                id=recipe_id,
                title=recipe_data['title'],
                description=recipe_data.get('description'),
                image_url=recipe_data.get('image_url'),
                recipe_type=recipe_data.get('recipe_type', 'Dish'),
                cuisine_type=recipe_data.get('cuisine_type', 'Other'),
                prep_time=recipe_data.get('prep_time'),
                cook_time=recipe_data.get('cook_time'),
                total_time=recipe_data.get('total_time'),
                servings=recipe_data.get('servings', 1),
                difficulty=recipe_data.get('difficulty', 'Easy'),
                created_at=recipe_data.get('created_at', datetime.now()),
                updated_at=recipe_data.get('updated_at'),
                ingredients=[RecipeIngredientResponse(**ing) for ing in recipe_data.get('ingredients', [])],
                steps=[RecipeStepResponse(**step) for step in recipe_data.get('steps', [])],
                equipment=[RecipeEquipmentResponse(**eq) for eq in recipe_data.get('equipment', [])],
                creator_id=parse_creator_id(recipe_data.get('creator_id')),
                creator_username=recipe_data.get('creator_username'),
                likes_count=counts['likes_count'],
                comments_count=counts['comments_count'],
                favorites_count=counts['favorites_count'],
                calories_per_serving=recipe_data.get('calories_per_serving'),
                diet_types=recipe_data.get('diet_types') if recipe_data.get('diet_types') is not None else []
            ))
    
    return recipes

@app.get("/users/{user_id}/recipes")
def get_user_recipes(user_id: int):
    """Get recipes created by a specific user"""
    recipes_ref = db.collection('recipes')
    user_recipes_query = recipes_ref.where('creator_id', '==', user_id).stream()
    
    recipes = []
    for doc in user_recipes_query:
        recipe_data = doc_to_dict(doc)
        if recipe_data:
            # Use document ID as recipe_id
            doc_id = doc.id
            if doc_id.isdigit():
                recipe_id = int(doc_id)
            else:
                recipe_id = abs(hash(doc_id)) % (10**9)
            
            # Get counts for this recipe
            counts = get_recipe_counts(recipe_id)
            
            recipes.append(RecipeResponse(
                id=recipe_id,
                title=recipe_data['title'],
                description=recipe_data.get('description'),
                image_url=recipe_data.get('image_url'),
                recipe_type=recipe_data.get('recipe_type', 'Dish'),
                cuisine_type=recipe_data.get('cuisine_type', 'Other'),
                prep_time=recipe_data.get('prep_time'),
                cook_time=recipe_data.get('cook_time'),
                total_time=recipe_data.get('total_time'),
                servings=recipe_data.get('servings', 1),
                difficulty=recipe_data.get('difficulty', 'Easy'),
                created_at=recipe_data.get('created_at', datetime.now()),
                updated_at=recipe_data.get('updated_at'),
                ingredients=[RecipeIngredientResponse(**ing) for ing in recipe_data.get('ingredients', [])],
                steps=[RecipeStepResponse(**step) for step in recipe_data.get('steps', [])],
                equipment=[RecipeEquipmentResponse(**eq) for eq in recipe_data.get('equipment', [])],
                creator_id=parse_creator_id(recipe_data.get('creator_id')),
                creator_username=recipe_data.get('creator_username'),
                likes_count=counts['likes_count'],
                comments_count=counts['comments_count'],
                favorites_count=counts['favorites_count'],
                calories_per_serving=recipe_data.get('calories_per_serving'),
                diet_types=recipe_data.get('diet_types') if recipe_data.get('diet_types') is not None else []
            ))
    
    return recipes

@app.get("/users", response_model=List[UserResponse])
def get_users():
    """Get all users"""
    users_ref = db.collection('users')
    users = []
    for doc in users_ref.stream():
        user_data = doc_to_dict(doc)
        if user_data:
            user_data = {k: v for k, v in user_data.items() if k not in ['password_hash', 'password']}
            users.append(UserResponse(**user_data))
    return users

@app.get("/check-username/{username}")
def check_username_availability(username: str):
    """Check if username is available"""
    users_ref = db.collection('users')
    query = users_ref.where('username', '==', username).limit(1).stream()
    available = not any(query)
    return {"available": available, "username": username}

@app.put("/users/me", response_model=UserResponse)
def update_user_profile(
    user_update: UserUpdate,
    current_user: dict = Depends(get_current_user)
):
    """Update user profile"""
    users_ref = db.collection('users')
    user_doc = users_ref.document(str(current_user['id']))
    
    # Build update data
    update_data = {'updated_at': datetime.now()}
    if user_update.username is not None:
        update_data['username'] = user_update.username
    if user_update.email is not None:
        update_data['email'] = user_update.email
    if user_update.gender is not None:
        update_data['gender'] = user_update.gender
    if user_update.birth_date is not None:
        update_data['birth_date'] = convert_to_firestore_datetime(user_update.birth_date)
    if user_update.bio is not None:
        update_data['bio'] = user_update.bio
    if user_update.profile_image_url is not None:
        update_data['profile_image_url'] = user_update.profile_image_url
    
    user_doc.update(update_data)
    
    # Get updated user
    updated_user = doc_to_dict(user_doc.get())
    updated_user = {k: v for k, v in updated_user.items() if k not in ['password_hash', 'password']}
    return UserResponse(**updated_user)

# Recipe endpoints
@app.post("/recipes", response_model=RecipeResponse)
def create_recipe(recipe: RecipeCreate, current_user: dict = Depends(get_current_user)):
    """Create a new recipe"""
    try:
        print(f"🔍 Creating recipe - Title: {recipe.title}")
        print(f"🔍 Creating recipe - User ID: {current_user.get('id')}")
        print(f"🔍 Creating recipe - Ingredients count: {len(recipe.ingredients)}")
        print(f"🔍 Creating recipe - Steps count: {len(recipe.steps)}")
        print(f"🔍 Creating recipe - Equipment count: {len(recipe.equipment)}")
        
        recipes_ref = db.collection('recipes')
        
        # Prepare recipe data
        now = datetime.now()
        recipe_data = {
            'title': recipe.title,
            'description': recipe.description,
            'image_url': recipe.image_url,
            'recipe_type': recipe.recipe_type,
            'cuisine_type': recipe.cuisine_type,
            'prep_time': recipe.prep_time if recipe.prep_time else None,
            'cook_time': recipe.cook_time if recipe.cook_time else None,
            'total_time': recipe.total_time if recipe.total_time else None,
            'servings': recipe.servings,
            'difficulty': recipe.difficulty,
            'ingredients': [ing.dict() for ing in recipe.ingredients],
            'steps': [step.dict() for step in recipe.steps],
            'equipment': [eq.dict() for eq in recipe.equipment],
            'creator_id': current_user['id'],
            'creator_username': current_user.get('username', 'Unknown'),
            'created_at': now,
            'updated_at': now
        }
        
        # Analyze recipe for calories and diet types
        print("🔍 Analyzing recipe with AI...")
        if openai_client:
            analysis = analyze_recipe_with_openai(openai_client, recipe_data)
        else:
            analysis = analyze_recipe_simple(recipe_data)
        
        calories_per_serving = analysis.get('calories_per_serving')
        diet_types = analysis.get('diet_types', [])
        
        print(f"📊 Recipe analysis: {calories_per_serving} calories/serving, Diet types: {diet_types}")
        
        # Add analysis results to recipe data
        recipe_data['calories_per_serving'] = calories_per_serving
        recipe_data['diet_types'] = diet_types
        
        # Add recipe to Firestore
        doc_ref = recipes_ref.add(recipe_data)[1]
        recipe_id = int(doc_ref.id) if doc_ref.id.isdigit() else abs(hash(doc_ref.id)) % (10**9)
        recipe_data['id'] = recipe_id
        
        print(f"✅ Recipe added to Firestore - Document ID: {doc_ref.id}, Recipe ID: {recipe_id}")
        
        # Get counts for this recipe (new recipe, so all counts are 0)
        counts = get_recipe_counts(recipe_id)
        
        # Convert to response format
        response = RecipeResponse(
            id=recipe_data['id'],
            title=recipe_data['title'],
            description=recipe_data.get('description'),
            image_url=recipe_data.get('image_url'),
            recipe_type=recipe_data['recipe_type'],
            cuisine_type=recipe_data['cuisine_type'],
            prep_time=recipe_data.get('prep_time'),
            cook_time=recipe_data.get('cook_time'),
            total_time=recipe_data.get('total_time'),
            servings=recipe_data['servings'],
            difficulty=recipe_data['difficulty'],
            created_at=recipe_data['created_at'],
            updated_at=recipe_data.get('updated_at'),
            ingredients=[RecipeIngredientResponse(**ing) for ing in recipe_data.get('ingredients', [])],
            steps=[RecipeStepResponse(**step) for step in recipe_data.get('steps', [])],
            equipment=[RecipeEquipmentResponse(**eq) for eq in recipe_data.get('equipment', [])],
            creator_id=parse_creator_id(recipe_data.get('creator_id')),
            creator_username=recipe_data.get('creator_username'),
            likes_count=counts['likes_count'],
            comments_count=counts['comments_count'],
            favorites_count=counts['favorites_count'],
            calories_per_serving=calories_per_serving,
            diet_types=diet_types
        )
        
        print(f"✅ Recipe created successfully - ID: {response.id}, Title: {response.title}")
        return response
        
    except Exception as e:
        print(f"❌ Error creating recipe: {str(e)}")
        print(f"❌ Error type: {type(e).__name__}")
        import traceback
        print(f"❌ Traceback: {traceback.format_exc()}")
        raise HTTPException(status_code=500, detail=f"Failed to create recipe: {str(e)}")

@app.get("/recipes", response_model=List[RecipeResponse])
def read_recipes(skip: int = 0, limit: int = 100):
    """Get all recipes"""
    try:
        recipes_ref = db.collection('recipes')
        recipes = []
        
        # Firestore doesn't have offset, so we'll get all and slice
        # Note: Firestore requires an index for order_by, so we'll just get all and sort in memory
        query = recipes_ref.limit(limit + skip).stream()
        
        all_recipes = list(query)
        seen_ids = set()  # Track seen recipe IDs to avoid duplicates
        for doc in all_recipes[skip:skip+limit]:
            recipe_data = doc_to_dict(doc)
            if recipe_data:
                # Use document ID as recipe_id (primary identifier)
                # Convert document ID to integer if possible, otherwise use hash
                doc_id = doc.id
                if doc_id.isdigit():
                    recipe_id = int(doc_id)
                else:
                    recipe_id = abs(hash(doc_id)) % (10**9)
                
                # Skip if we've already seen this recipe_id (avoid duplicates)
                if recipe_id in seen_ids:
                    continue
                seen_ids.add(recipe_id)
                
                # Get counts for this recipe
                counts = get_recipe_counts(recipe_id)
                
                recipes.append(RecipeResponse(
                    id=recipe_id,
                    title=recipe_data['title'],
                    description=recipe_data.get('description'),
                    image_url=recipe_data.get('image_url'),
                    recipe_type=recipe_data.get('recipe_type', 'Dish'),
                    cuisine_type=recipe_data.get('cuisine_type', 'Other'),
                    prep_time=recipe_data.get('prep_time'),
                    cook_time=recipe_data.get('cook_time'),
                    total_time=recipe_data.get('total_time'),
                    servings=recipe_data.get('servings', 1),
                    difficulty=recipe_data.get('difficulty', 'Easy'),
                    created_at=recipe_data.get('created_at', datetime.now()),
                    updated_at=recipe_data.get('updated_at'),
                    ingredients=[RecipeIngredientResponse(**ing) for ing in recipe_data.get('ingredients', [])],
                    steps=[RecipeStepResponse(**step) for step in recipe_data.get('steps', [])],
                    equipment=[RecipeEquipmentResponse(**eq) for eq in recipe_data.get('equipment', [])],
                    creator_id=parse_creator_id(recipe_data.get('creator_id')),
                    creator_username=recipe_data.get('creator_username'),
                    likes_count=counts['likes_count'],
                    comments_count=counts['comments_count'],
                    favorites_count=counts['favorites_count'],
                    calories_per_serving=recipe_data.get('calories_per_serving'),
                    diet_types=recipe_data.get('diet_types') if recipe_data.get('diet_types') is not None else []
                ))
        return recipes
    except Exception as e:
        print(f"❌ Error reading recipes: {str(e)}")
        print(f"❌ Error type: {type(e).__name__}")
        import traceback
        print(f"❌ Traceback: {traceback.format_exc()}")
        raise HTTPException(status_code=500, detail=f"Failed to read recipes: {str(e)}")

@app.get("/recipes/{recipe_id}", response_model=RecipeResponse)
def read_recipe(recipe_id: int):
    """Get a specific recipe"""
    recipe_doc = find_recipe_document(recipe_id)
    
    if not recipe_doc or not recipe_doc.exists:
        raise HTTPException(status_code=404, detail="Recipe not found")
    
    recipe_data = doc_to_dict(recipe_doc)
    
    # Use document ID as recipe_id for consistency
    doc_id = recipe_doc.id
    if doc_id.isdigit():
        actual_recipe_id = int(doc_id)
    else:
        actual_recipe_id = abs(hash(doc_id)) % (10**9)
    
    # Get creator information from users collection if creator_id exists
    creator_id_raw = recipe_data.get('creator_id')
    creator_id = parse_creator_id(creator_id_raw)
    creator_username = recipe_data.get('creator_username')
    
    # If creator_id exists but username is missing, fetch from users collection
    if creator_id and not creator_username:
        creator_doc = db.collection('users').document(str(creator_id)).get()
        if creator_doc.exists:
            creator_data = doc_to_dict(creator_doc)
            creator_username = creator_data.get('username', 'Unknown')
    
    # Get counts for this recipe
    counts = get_recipe_counts(actual_recipe_id)
    
    return RecipeResponse(
        id=actual_recipe_id,
        title=recipe_data['title'],
        description=recipe_data.get('description'),
        image_url=recipe_data.get('image_url'),
        recipe_type=recipe_data.get('recipe_type', 'Dish'),
        cuisine_type=recipe_data.get('cuisine_type', 'Other'),
        prep_time=recipe_data.get('prep_time'),
        cook_time=recipe_data.get('cook_time'),
        total_time=recipe_data.get('total_time'),
        servings=recipe_data.get('servings', 1),
        difficulty=recipe_data.get('difficulty', 'Easy'),
        created_at=recipe_data.get('created_at', datetime.now()),
        updated_at=recipe_data.get('updated_at'),
        ingredients=[RecipeIngredientResponse(**ing) for ing in recipe_data.get('ingredients', [])],
        steps=[RecipeStepResponse(**step) for step in recipe_data.get('steps', [])],
        equipment=[RecipeEquipmentResponse(**eq) for eq in recipe_data.get('equipment', [])],
        creator_id=creator_id,
        creator_username=creator_username,
        likes_count=counts['likes_count'],
        comments_count=counts['comments_count'],
        favorites_count=counts['favorites_count'],
        calories_per_serving=recipe_data.get('calories_per_serving'),
        diet_types=recipe_data.get('diet_types', [])
    )

# Comment endpoints
@app.post("/recipes/{recipe_id}/comments", response_model=CommentResponse)
def create_comment(
    recipe_id: int,
    comment: CommentCreate,
    current_user: dict = Depends(get_current_user)
):
    """Create a comment on a recipe"""
    # Check if recipe exists
    recipe_doc = find_recipe_document(recipe_id)
    if not recipe_doc or not recipe_doc.exists:
        raise HTTPException(status_code=404, detail="Recipe not found")
    
    # Create comment
    comments_ref = db.collection('comments')
    now = datetime.now()
    comment_data = {
        'user_id': current_user['id'],
        'recipe_id': recipe_id,
        'content': comment.content,
        'created_at': now,
        'updated_at': now
    }
    
    doc_ref = comments_ref.add(comment_data)[1]
    comment_data['id'] = int(doc_ref.id) if doc_ref.id.isdigit() else doc_ref.id
    
    return CommentResponse(
        id=comment_data['id'],
        user_id=comment_data['user_id'],
        recipe_id=comment_data['recipe_id'],
        content=comment_data['content'],
        created_at=comment_data['created_at'],
        updated_at=comment_data['updated_at'],
        user={
            'id': current_user['id'],
            'username': current_user['username'],
            'profile_image_url': current_user.get('profile_image_url')
        }
    )

@app.get("/recipes/{recipe_id}/comments", response_model=List[CommentResponse])
def get_recipe_comments(recipe_id: int):
    """Get comments for a recipe"""
    # Check if recipe exists
    recipe_doc = find_recipe_document(recipe_id)
    if not recipe_doc or not recipe_doc.exists:
        raise HTTPException(status_code=404, detail="Recipe not found")
    
    # Get comments
    comments_ref = db.collection('comments')
    comments_query = comments_ref.where('recipe_id', '==', recipe_id).stream()
    
    result = []
    for doc in comments_query:
        comment_data = doc_to_dict(doc)
        if comment_data:
            # Get user info
            user_doc = db.collection('users').document(str(comment_data['user_id'])).get()
            user_data = doc_to_dict(user_doc) if user_doc.exists else {}
            
            result.append(CommentResponse(
                id=comment_data['id'],
                user_id=comment_data['user_id'],
                recipe_id=comment_data['recipe_id'],
                content=comment_data['content'],
                created_at=comment_data.get('created_at', datetime.now()),
                updated_at=comment_data.get('updated_at', datetime.now()),
                user={
                    'id': user_data.get('id', comment_data['user_id']),
                    'username': user_data.get('username', 'Unknown'),
                    'profile_image_url': user_data.get('profile_image_url')
                }
            ))
    return result

@app.delete("/comments/{comment_id}")
def delete_comment(comment_id: int, current_user: dict = Depends(get_current_user)):
    """Delete a comment"""
    comments_ref = db.collection('comments')
    comment_doc = comments_ref.document(str(comment_id)).get()
    
    if not comment_doc.exists:
        raise HTTPException(status_code=404, detail="Comment not found")
    
    comment_data = doc_to_dict(comment_doc)
    if comment_data['user_id'] != current_user['id']:
        raise HTTPException(status_code=403, detail="Not authorized to delete this comment")
    
    comments_ref.document(str(comment_id)).delete()
    return {"message": "Comment deleted successfully"}

# Image upload endpoints (unchanged, no database dependency)
@app.post("/upload/image")
async def upload_image(
    file: UploadFile = File(...),
    category: str = Form("recipes"),
    current_user: dict = Depends(get_current_user)
):
    """Upload an image file"""
    try:
        from image_storage import image_storage
        image_info = await image_storage.save_image(file, category)
        return {
            "success": True,
            "image": image_info,
            "message": "Image uploaded successfully"
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to upload image: {str(e)}")

@app.delete("/images/{category}/{filename}")
async def delete_image(
    category: str,
    filename: str,
    current_user: dict = Depends(get_current_user)
):
    """Delete an image file"""
    try:
        from image_storage import image_storage
        success = image_storage.delete_image(category, filename)
        if success:
            return {"message": "Image deleted successfully"}
        else:
            raise HTTPException(status_code=404, detail="Image not found")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to delete image: {str(e)}")

@app.get("/images/{category}/{filename}")
async def get_image(category: str, filename: str):
    """Get image file"""
    from image_storage import image_storage
    image_path = image_storage.get_image_path(category, filename)
    if not image_path.exists():
        raise HTTPException(status_code=404, detail="Image not found")
    return FileResponse(str(image_path))

# Interaction APIs
@app.post("/favorites")
def add_favorite(recipe_id: int, current_user: dict = Depends(get_current_user)):
    """Add a recipe to favorites"""
    # Check if recipe exists using find_recipe_document
    recipe_doc = find_recipe_document(recipe_id)
    if not recipe_doc or not recipe_doc.exists:
        raise HTTPException(status_code=404, detail="Recipe not found")
    
    # Check if already favorited
    favorites_ref = db.collection('favorites')
    existing = favorites_ref.where('user_id', '==', current_user['id']).where('recipe_id', '==', recipe_id).limit(1).stream()
    if any(existing):
        raise HTTPException(status_code=400, detail="Recipe already in favorites")
    
    # Create favorite
    now = datetime.now()
    favorite_data = {
        'user_id': current_user['id'],
        'recipe_id': recipe_id,
        'created_at': now,
        'updated_at': now
    }
    doc_ref = favorites_ref.add(favorite_data)[1]
    
    return {
        "id": int(doc_ref.id) if doc_ref.id.isdigit() else doc_ref.id,
        "user_id": favorite_data['user_id'],
        "recipe_id": favorite_data['recipe_id'],
        "created_at": favorite_data['created_at'].isoformat()
    }

@app.delete("/favorites/{recipe_id}")
def remove_favorite(recipe_id: int, current_user: dict = Depends(get_current_user)):
    """Remove a recipe from favorites"""
    favorites_ref = db.collection('favorites')
    query = favorites_ref.where('user_id', '==', current_user['id']).where('recipe_id', '==', recipe_id).limit(1).stream()
    
    for doc in query:
        favorites_ref.document(doc.id).delete()
        return {"message": "Recipe removed from favorites"}
    
    raise HTTPException(status_code=404, detail="Favorite not found")

@app.get("/favorites", response_model=List[RecipeResponse])
def get_favorites(current_user: dict = Depends(get_current_user)):
    """Get user's favorite recipes"""
    favorites_ref = db.collection('favorites')
    favorites_query = favorites_ref.where('user_id', '==', current_user['id']).stream()
    
    recipe_ids = []
    for doc in favorites_query:
        favorite_data = doc.to_dict()
        recipe_ids.append(favorite_data['recipe_id'])
    
    if not recipe_ids:
        return []
    
    # Get recipes
    recipes = []
    for recipe_id in recipe_ids:
        recipe_doc = find_recipe_document(recipe_id)
        if recipe_doc and recipe_doc.exists:
            recipe_data = doc_to_dict(recipe_doc)
            
            # Ensure recipe_id is an integer
            if isinstance(recipe_id, str):
                try:
                    recipe_id = int(recipe_id) if recipe_id.isdigit() else abs(hash(recipe_id)) % (10**9)
                except:
                    recipe_id = abs(hash(str(recipe_id))) % (10**9)
            elif not isinstance(recipe_id, int):
                try:
                    recipe_id = int(recipe_id) if str(recipe_id).isdigit() else abs(hash(str(recipe_id))) % (10**9)
                except:
                    recipe_id = abs(hash(str(recipe_id))) % (10**9)
            
            # Get counts for this recipe
            counts = get_recipe_counts(recipe_id)
            
            recipes.append(RecipeResponse(
                id=recipe_id,
                title=recipe_data['title'],
                description=recipe_data.get('description'),
                image_url=recipe_data.get('image_url'),
                recipe_type=recipe_data.get('recipe_type', 'Dish'),
                cuisine_type=recipe_data.get('cuisine_type', 'Other'),
                prep_time=recipe_data.get('prep_time'),
                cook_time=recipe_data.get('cook_time'),
                total_time=recipe_data.get('total_time'),
                servings=recipe_data.get('servings', 1),
                difficulty=recipe_data.get('difficulty', 'Easy'),
                created_at=recipe_data.get('created_at', datetime.now()),
                updated_at=recipe_data.get('updated_at'),
                ingredients=[RecipeIngredientResponse(**ing) for ing in recipe_data.get('ingredients', [])],
                steps=[RecipeStepResponse(**step) for step in recipe_data.get('steps', [])],
                equipment=[RecipeEquipmentResponse(**eq) for eq in recipe_data.get('equipment', [])],
                creator_id=parse_creator_id(recipe_data.get('creator_id')),
                creator_username=recipe_data.get('creator_username'),
                likes_count=counts['likes_count'],
                comments_count=counts['comments_count'],
                favorites_count=counts['favorites_count'],
                calories_per_serving=recipe_data.get('calories_per_serving'),
                diet_types=recipe_data.get('diet_types') if recipe_data.get('diet_types') is not None else []
            ))
    return recipes

# Likes API
@app.post("/recipes/{recipe_id}/like")
def like_recipe(recipe_id: int, current_user: dict = Depends(get_current_user)):
    """Like a recipe"""
    recipe_doc = find_recipe_document(recipe_id)
    
    if not recipe_doc or not recipe_doc.exists:
        raise HTTPException(status_code=404, detail="Recipe not found")
    
    likes_ref = db.collection('likes')
    existing = likes_ref.where('user_id', '==', current_user['id']).where('recipe_id', '==', recipe_id).limit(1).stream()
    if any(existing):
        raise HTTPException(status_code=400, detail="Recipe already liked")
    
    now = datetime.now()
    like_data = {
        'user_id': current_user['id'],
        'recipe_id': recipe_id,
        'created_at': now,
        'updated_at': now
    }
    likes_ref.add(like_data)
    return {"message": "Recipe liked"}

@app.delete("/recipes/{recipe_id}/like")
def unlike_recipe(recipe_id: int, current_user: dict = Depends(get_current_user)):
    """Unlike a recipe"""
    recipe_doc = find_recipe_document(recipe_id)
    
    if not recipe_doc or not recipe_doc.exists:
        raise HTTPException(status_code=404, detail="Recipe not found")
    
    likes_ref = db.collection('likes')
    query = likes_ref.where('user_id', '==', current_user['id']).where('recipe_id', '==', recipe_id).limit(1).stream()
    
    for doc in query:
        likes_ref.document(doc.id).delete()
        return {"message": "Recipe unliked"}
    
    raise HTTPException(status_code=404, detail="Like not found")

@app.get("/recipes/{recipe_id}/likes")
def get_recipe_likes(recipe_id: int):
    """Get likes count for a recipe"""
    likes_ref = db.collection('likes')
    likes_query = likes_ref.where('recipe_id', '==', recipe_id).stream()
    likes_count = len(list(likes_query))
    return {"likes_count": likes_count}

# Todo List API
@app.post("/todo-list")
def add_to_todo_list(recipe_id: int, current_user: dict = Depends(get_current_user)):
    """Add a recipe to todo list"""
    # Check if recipe exists using find_recipe_document
    recipe_doc = find_recipe_document(recipe_id)
    if not recipe_doc or not recipe_doc.exists:
        raise HTTPException(status_code=404, detail="Recipe not found")
    
    todos_ref = db.collection('todo_list')
    existing = todos_ref.where('user_id', '==', current_user['id']).where('recipe_id', '==', recipe_id).limit(1).stream()
    if any(existing):
        raise HTTPException(status_code=400, detail="Recipe already in todo list")
    
    now = datetime.now()
    todo_data = {
        'user_id': current_user['id'],
        'recipe_id': recipe_id,
        'completed': False,  # Default to not completed
        'created_at': now,
        'updated_at': now
    }
    todos_ref.add(todo_data)
    return {"message": "Recipe added to todo list"}

@app.delete("/todo-list/{recipe_id}")
def remove_from_todo_list(recipe_id: int, current_user: dict = Depends(get_current_user)):
    """Remove a recipe from todo list"""
    todos_ref = db.collection('todo_list')
    query = todos_ref.where('user_id', '==', current_user['id']).where('recipe_id', '==', recipe_id).limit(1).stream()
    
    for doc in query:
        todos_ref.document(doc.id).delete()
        return {"message": "Recipe removed from todo list"}
    
    raise HTTPException(status_code=404, detail="Todo item not found")

@app.put("/todo-list/{recipe_id}/complete")
def toggle_todo_completion(recipe_id: int, completed: bool = Query(...), current_user: dict = Depends(get_current_user)):
    """Toggle completion status of a todo item"""
    todos_ref = db.collection('todo_list')
    query = todos_ref.where('user_id', '==', current_user['id']).where('recipe_id', '==', recipe_id).limit(1).stream()
    
    for doc in query:
        todos_ref.document(doc.id).update({
            'completed': completed,
            'updated_at': datetime.now()
        })
        return {"message": f"Todo item marked as {'completed' if completed else 'not completed'}"}
    
    raise HTTPException(status_code=404, detail="Todo item not found")

@app.get("/todo-list")
def get_todo_list(current_user: dict = Depends(get_current_user)):
    """Get user's todo list with completion status"""
    todos_ref = db.collection('todo_list')
    todos_query = todos_ref.where('user_id', '==', current_user['id']).stream()
    
    todo_items = []
    for doc in todos_query:
        todo_data = doc.to_dict()
        recipe_id = todo_data['recipe_id']
        completed = todo_data.get('completed', False)
        
        # Get recipe data
        recipe_doc = find_recipe_document(recipe_id)
        if recipe_doc and recipe_doc.exists:
            recipe_data = doc_to_dict(recipe_doc)
            
            # Get creator information
            creator_id = recipe_data.get('creator_id')
            creator_username = recipe_data.get('creator_username')
            
            if creator_id and not creator_username:
                creator_doc = db.collection('users').document(str(creator_id)).get()
                if creator_doc.exists:
                    creator_data = doc_to_dict(creator_doc)
                    creator_username = creator_data.get('username', 'Unknown')
            
            # Get counts
            counts = get_recipe_counts(recipe_id)
            
            recipe_response = RecipeResponse(
                id=recipe_id,
                title=recipe_data['title'],
                description=recipe_data.get('description'),
                image_url=recipe_data.get('image_url'),
                recipe_type=recipe_data.get('recipe_type', 'Dish'),
                cuisine_type=recipe_data.get('cuisine_type', 'Other'),
                prep_time=recipe_data.get('prep_time'),
                cook_time=recipe_data.get('cook_time'),
                total_time=recipe_data.get('total_time'),
                servings=recipe_data.get('servings', 1),
                difficulty=recipe_data.get('difficulty', 'Easy'),
                created_at=recipe_data.get('created_at', datetime.now()),
                updated_at=recipe_data.get('updated_at'),
                ingredients=[RecipeIngredientResponse(**ing) for ing in recipe_data.get('ingredients', [])],
                steps=[RecipeStepResponse(**step) for step in recipe_data.get('steps', [])],
                equipment=[RecipeEquipmentResponse(**eq) for eq in recipe_data.get('equipment', [])],
                creator_id=parse_creator_id(creator_id),
                creator_username=creator_username,
                likes_count=counts['likes_count'],
                comments_count=counts['comments_count'],
                favorites_count=counts['favorites_count'],
                calories_per_serving=recipe_data.get('calories_per_serving'),
                diet_types=recipe_data.get('diet_types') if recipe_data.get('diet_types') is not None else []
            )
            
            todo_items.append({
                'recipe': recipe_response,
                'completed': completed,
                'todo_id': doc.id
            })
    
    return todo_items

@app.get("/recipes/{recipe_id}/user-interactions")
def get_user_interactions(recipe_id: int, current_user: dict = Depends(get_current_user)):
    """Get user's interactions with a recipe"""
    user_id = current_user['id']
    
    # Check favorite
    favorites_ref = db.collection('favorites')
    is_favorited = any(favorites_ref.where('user_id', '==', user_id).where('recipe_id', '==', recipe_id).limit(1).stream())
    
    # Check like
    likes_ref = db.collection('likes')
    is_liked = any(likes_ref.where('user_id', '==', user_id).where('recipe_id', '==', recipe_id).limit(1).stream())
    
    # Check todo
    todos_ref = db.collection('todo_list')
    is_in_todo = any(todos_ref.where('user_id', '==', user_id).where('recipe_id', '==', recipe_id).limit(1).stream())
    
    # Check if following creator
    recipe_doc = find_recipe_document(recipe_id)
    is_following_creator = False
    if recipe_doc and recipe_doc.exists:
        recipe_data = doc_to_dict(recipe_doc)
        creator_id_raw = recipe_data.get('creator_id')
        creator_id = parse_creator_id(creator_id_raw)
        if creator_id and creator_id != user_id:
            follows_ref = db.collection('follows')
            is_following_creator = any(follows_ref.where('follower_id', '==', user_id).where('following_id', '==', creator_id).limit(1).stream())
    
    return {
        "is_favorited": is_favorited,
        "is_liked": is_liked,
        "is_in_todo": is_in_todo,
        "is_following_creator": is_following_creator
    }

# Follow/Unfollow API
@app.post("/users/{user_id}/follow")
def follow_user(user_id: int, current_user: dict = Depends(get_current_user)):
    """Follow a user"""
    follower_id = current_user['id']
    
    if follower_id == user_id:
        raise HTTPException(status_code=400, detail="Cannot follow yourself")
    
    # Check if user exists
    user_doc = db.collection('users').document(str(user_id)).get()
    if not user_doc.exists:
        raise HTTPException(status_code=404, detail="User not found")
    
    # Check if already following
    follows_ref = db.collection('follows')
    existing = follows_ref.where('follower_id', '==', follower_id).where('following_id', '==', user_id).limit(1).stream()
    if any(existing):
        raise HTTPException(status_code=400, detail="Already following this user")
    
    # Create follow relationship
    now = datetime.now()
    follow_data = {
        'follower_id': follower_id,
        'following_id': user_id,
        'created_at': now
    }
    follows_ref.add(follow_data)
    
    return {"message": "User followed successfully"}

@app.delete("/users/{user_id}/follow")
def unfollow_user(user_id: int, current_user: dict = Depends(get_current_user)):
    """Unfollow a user"""
    follower_id = current_user['id']
    
    if follower_id == user_id:
        raise HTTPException(status_code=400, detail="Cannot unfollow yourself")
    
    follows_ref = db.collection('follows')
    query = follows_ref.where('follower_id', '==', follower_id).where('following_id', '==', user_id).limit(1).stream()
    
    deleted = False
    for doc in query:
        follows_ref.document(doc.id).delete()
        deleted = True
        print(f"✅ User {follower_id} unfollowed user {user_id}")
        break
    
    if not deleted:
        raise HTTPException(status_code=404, detail="Not following this user")
    
    return {"message": "User unfollowed successfully"}

@app.get("/users/{user_id}/follow-status")
def get_follow_status(user_id: int, current_user: dict = Depends(get_current_user)):
    """Get follow status between current user and target user"""
    follower_id = current_user['id']
    
    follows_ref = db.collection('follows')
    is_following = any(follows_ref.where('follower_id', '==', follower_id).where('following_id', '==', user_id).limit(1).stream())
    
    return {"is_following": is_following}

@app.get("/users/me/stats")
def get_user_stats(current_user: dict = Depends(get_current_user)):
    """Get current user's statistics"""
    user_id = current_user['id']
    
    # Get followers count (how many users follow this user)
    follows_ref = db.collection('follows')
    followers_count = len(list(follows_ref.where('following_id', '==', user_id).stream()))
    
    # Get following count (how many users this user follows)
    following_count = len(list(follows_ref.where('follower_id', '==', user_id).stream()))
    
    # Get recipes created by this user (as creator)
    recipes_ref = db.collection('recipes')
    user_recipes_query = recipes_ref.where('creator_id', '==', user_id).stream()
    
    # Count recipes created by this user
    recipes_count = 0
    recipe_ids = []
    total_likes = 0
    
    for recipe_doc in user_recipes_query:
        recipes_count += 1
        recipe_data = doc_to_dict(recipe_doc)
        # Use document ID as recipe_id for counting likes
        doc_id = recipe_doc.id
        if doc_id.isdigit():
            recipe_id = int(doc_id)
        else:
            recipe_id = abs(hash(doc_id)) % (10**9)
        recipe_ids.append(recipe_id)
    
    # Count likes for all recipes created by this user
    if recipe_ids:
        likes_ref = db.collection('likes')
        for recipe_id in recipe_ids:
            recipe_likes = likes_ref.where('recipe_id', '==', recipe_id).stream()
            total_likes += len(list(recipe_likes))
    
    print(f"📊 User {user_id} stats: {recipes_count} recipes created, {total_likes} total likes received")
    
    return {
        "followers_count": followers_count,
        "following_count": following_count,
        "total_likes_received": total_likes,
        "recipes_count": recipes_count  # This is the count of recipes created by the user
    }

@app.get("/users/me/followers")
def get_my_followers(current_user: dict = Depends(get_current_user)):
    """Get list of users who follow the current user"""
    user_id = current_user['id']
    follows_ref = db.collection('follows')
    followers_query = follows_ref.where('following_id', '==', user_id).stream()
    
    follower_ids = []
    for doc in followers_query:
        follow_data = doc.to_dict()
        follower_ids.append(follow_data['follower_id'])
    
    if not follower_ids:
        return []
    
    # Get user information for each follower
    users_ref = db.collection('users')
    followers = []
    for follower_id in follower_ids:
        user_doc = users_ref.document(str(follower_id)).get()
        if user_doc.exists:
            user_data = doc_to_dict(user_doc)
            if user_data:
                user_response_data = {k: v for k, v in user_data.items() if k not in ['password_hash', 'password']}
                followers.append(UserResponse(**user_response_data))
    
    return followers

@app.get("/users/me/following")
def get_my_following(current_user: dict = Depends(get_current_user)):
    """Get list of users the current user is following"""
    user_id = current_user['id']
    follows_ref = db.collection('follows')
    following_query = follows_ref.where('follower_id', '==', user_id).stream()
    
    following_ids = []
    for doc in following_query:
        follow_data = doc.to_dict()
        following_ids.append(follow_data['following_id'])
    
    if not following_ids:
        return []
    
    # Get user information for each user being followed
    users_ref = db.collection('users')
    following = []
    for following_id in following_ids:
        user_doc = users_ref.document(str(following_id)).get()
        if user_doc.exists:
            user_data = doc_to_dict(user_doc)
            if user_data:
                user_response_data = {k: v for k, v in user_data.items() if k not in ['password_hash', 'password']}
                following.append(UserResponse(**user_response_data))
    
    return following

@app.get("/users/me/liked-recipes")
def get_my_liked_recipes(current_user: dict = Depends(get_current_user)):
    """Get list of recipes the current user has liked"""
    user_id = current_user['id']
    likes_ref = db.collection('likes')
    likes_query = likes_ref.where('user_id', '==', user_id).stream()
    
    recipe_ids = []
    for doc in likes_query:
        like_data = doc.to_dict()
        recipe_ids.append(like_data['recipe_id'])
    
    if not recipe_ids:
        return []
    
    # Get recipe information for each liked recipe
    recipes_ref = db.collection('recipes')
    recipes = []
    seen_ids = set()
    
    for recipe_id in recipe_ids:
        if recipe_id in seen_ids:
            continue
        seen_ids.add(recipe_id)
        
        recipe_doc = find_recipe_document(recipe_id)
        if recipe_doc and recipe_doc.exists:
            recipe_data = doc_to_dict(recipe_doc)
            
            # Get counts for this recipe
            counts = get_recipe_counts(recipe_id)
            
            # Get creator information
            creator_id = parse_creator_id(recipe_data.get('creator_id'))
            creator_username = recipe_data.get('creator_username')
            
            if creator_id and not creator_username:
                creator_doc = db.collection('users').document(str(creator_id)).get()
                if creator_doc.exists:
                    creator_data = doc_to_dict(creator_doc)
                    creator_username = creator_data.get('username', 'Unknown')
            
            recipes.append(
                RecipeResponse(
                    id=recipe_id,
                    title=recipe_data['title'],
                    description=recipe_data.get('description'),
                    image_url=recipe_data.get('image_url'),
                    recipe_type=recipe_data.get('recipe_type', 'Dish'),
                    cuisine_type=recipe_data.get('cuisine_type', 'Other'),
                    prep_time=recipe_data.get('prep_time'),
                    cook_time=recipe_data.get('cook_time'),
                    total_time=recipe_data.get('total_time'),
                    servings=recipe_data.get('servings', 1),
                    difficulty=recipe_data.get('difficulty', 'Easy'),
                    created_at=recipe_data.get('created_at', datetime.now()),
                    updated_at=recipe_data.get('updated_at'),
                    ingredients=[RecipeIngredientResponse(**ing) for ing in recipe_data.get('ingredients', [])],
                    steps=[RecipeStepResponse(**step) for step in recipe_data.get('steps', [])],
                    equipment=[RecipeEquipmentResponse(**eq) for eq in recipe_data.get('equipment', [])],
                    creator_id=creator_id,
                    creator_username=creator_username,
                    likes_count=counts['likes_count'],
                    comments_count=counts['comments_count'],
                    favorites_count=counts['favorites_count'],
                    calories_per_serving=recipe_data.get('calories_per_serving'),
                    diet_types=recipe_data.get('diet_types') if recipe_data.get('diet_types') is not None else []
                )
            )
    
    return recipes

@app.get("/users/me/recipes")
def get_my_recipes(current_user: dict = Depends(get_current_user)):
    """Get recipes created by current user"""
    user_id = current_user['id']
    
    recipes_ref = db.collection('recipes')
    user_recipes_query = recipes_ref.where('creator_id', '==', user_id).stream()
    
    recipes = []
    for doc in user_recipes_query:
        recipe_data = doc_to_dict(doc)
        if recipe_data:
            # Use document ID as recipe_id
            doc_id = doc.id
            if doc_id.isdigit():
                recipe_id = int(doc_id)
            else:
                recipe_id = abs(hash(doc_id)) % (10**9)
            
            # Get counts for this recipe
            counts = get_recipe_counts(recipe_id)
            
            recipes.append(RecipeResponse(
                id=recipe_id,
                title=recipe_data['title'],
                description=recipe_data.get('description'),
                image_url=recipe_data.get('image_url'),
                recipe_type=recipe_data.get('recipe_type', 'Dish'),
                cuisine_type=recipe_data.get('cuisine_type', 'Other'),
                prep_time=recipe_data.get('prep_time'),
                cook_time=recipe_data.get('cook_time'),
                total_time=recipe_data.get('total_time'),
                servings=recipe_data.get('servings', 1),
                difficulty=recipe_data.get('difficulty', 'Easy'),
                created_at=recipe_data.get('created_at', datetime.now()),
                updated_at=recipe_data.get('updated_at'),
                ingredients=[RecipeIngredientResponse(**ing) for ing in recipe_data.get('ingredients', [])],
                steps=[RecipeStepResponse(**step) for step in recipe_data.get('steps', [])],
                equipment=[RecipeEquipmentResponse(**eq) for eq in recipe_data.get('equipment', [])],
                creator_id=parse_creator_id(recipe_data.get('creator_id')),
                creator_username=recipe_data.get('creator_username'),
                likes_count=counts['likes_count'],
                comments_count=counts['comments_count'],
                favorites_count=counts['favorites_count'],
                calories_per_serving=recipe_data.get('calories_per_serving'),
                diet_types=recipe_data.get('diet_types') if recipe_data.get('diet_types') is not None else []
            ))
    
    return recipes


# AI Recipe Matcher API
@app.post("/recipes/match", response_model=List[MatchedRecipeResponse])
def match_recipes(
    match_request: RecipeMatchRequest
):
    """
    AI助手：根据用户的饮食需求、材料和工具，匹配最适合的菜谱
    
    Args:
        match_request: 匹配请求，包含饮食需求、可用材料、可用工具
    
    Returns:
        匹配的菜谱列表，按匹配分数排序
    """
    try:
        print(f"🔍 菜谱匹配请求:")
        print(f"  - 饮食需求: {match_request.diet_requirements}")
        print(f"  - 可用材料: {match_request.available_ingredients}")
        print(f"  - 可用工具: {match_request.available_equipment}")
        print(f"  - 返回数量: {match_request.limit}")
        
        # 调用匹配算法
        matched_recipes = find_matching_recipes(
            diet_requirements=match_request.diet_requirements,
            available_ingredients=match_request.available_ingredients,
            available_equipment=match_request.available_equipment,
            limit=match_request.limit,
            openai_client=openai_client
        )
        
        if not matched_recipes:
            return []
        
        # 转换为响应格式
        result = []
        for recipe_data, match_score in matched_recipes:
            # 获取菜谱ID
            recipe_id = recipe_data.get('id')
            if not recipe_id:
                continue
            
            # 获取菜谱计数
            counts = get_recipe_counts(recipe_id)
            
            # 获取创建者信息
            creator_id = parse_creator_id(recipe_data.get('creator_id'))
            creator_username = recipe_data.get('creator_username')
            if creator_id and not creator_username:
                creator_doc = db.collection('users').document(str(creator_id)).get()
                if creator_doc.exists:
                    creator_data = doc_to_dict(creator_doc)
                    creator_username = creator_data.get('username', 'Unknown')
            
            # 生成匹配理由
            match_reason = generate_match_reason(
                recipe_data,
                match_request.diet_requirements,
                match_request.available_ingredients,
                match_request.available_equipment,
                match_score
            )
            
            # 构建响应
            recipe_response = RecipeResponse(
                id=recipe_id,
                title=recipe_data['title'],
                description=recipe_data.get('description'),
                image_url=recipe_data.get('image_url'),
                recipe_type=recipe_data.get('recipe_type', 'Dish'),
                cuisine_type=recipe_data.get('cuisine_type', 'Other'),
                prep_time=recipe_data.get('prep_time'),
                cook_time=recipe_data.get('cook_time'),
                total_time=recipe_data.get('total_time'),
                servings=recipe_data.get('servings', 1),
                difficulty=recipe_data.get('difficulty', 'Easy'),
                created_at=recipe_data.get('created_at', datetime.now()),
                updated_at=recipe_data.get('updated_at'),
                ingredients=[RecipeIngredientResponse(**ing) for ing in recipe_data.get('ingredients', [])],
                steps=[RecipeStepResponse(**step) for step in recipe_data.get('steps', [])],
                equipment=[RecipeEquipmentResponse(**eq) for eq in recipe_data.get('equipment', [])],
                creator_id=creator_id,
                creator_username=creator_username,
                likes_count=counts['likes_count'],
                comments_count=counts['comments_count'],
                favorites_count=counts['favorites_count'],
                calories_per_serving=recipe_data.get('calories_per_serving'),
                diet_types=recipe_data.get('diet_types') if recipe_data.get('diet_types') is not None else []
            )
            
            result.append(MatchedRecipeResponse(
                recipe=recipe_response,
                match_score=round(match_score, 2),
                match_reason=match_reason
            ))
        
        print(f"✅ 找到 {len(result)} 个匹配的菜谱")
        return result
        
    except Exception as e:
        print(f"❌ 菜谱匹配错误: {str(e)}")
        import traceback
        print(f"❌ Traceback: {traceback.format_exc()}")
        raise HTTPException(status_code=500, detail=f"匹配菜谱时出错: {str(e)}")


def generate_match_reason(
    recipe: Dict,
    diet_requirements: List[str],
    available_ingredients: List[str],
    available_equipment: List[str],
    match_score: float
) -> str:
    """
    生成匹配理由说明
    """
    reasons = []
    
    # 饮食需求匹配
    recipe_diet_types = recipe.get('diet_types', [])
    if diet_requirements:
        matched_diets = set(diet_requirements) & set(recipe_diet_types)
        if matched_diets:
            reasons.append(f"符合饮食需求: {', '.join(matched_diets)}")
    
    # 材料匹配
    recipe_ingredients = [ing.get('ingredient_name', '') for ing in recipe.get('ingredients', [])]
    if available_ingredients:
        matched_ingredients = []
        for recipe_ing in recipe_ingredients:
            for avail_ing in available_ingredients:
                if avail_ing.lower() in recipe_ing.lower() or recipe_ing.lower() in avail_ing.lower():
                    matched_ingredients.append(recipe_ing)
                    break
        if matched_ingredients:
            reasons.append(f"使用您提供的材料: {', '.join(matched_ingredients[:3])}")
    
    # 工具匹配
    recipe_equipment = [eq.get('equipment_name', '') for eq in recipe.get('equipment', [])]
    if available_equipment and recipe_equipment:
        matched_equipment = []
        for recipe_eq in recipe_equipment:
            for avail_eq in available_equipment:
                if avail_eq.lower() in recipe_eq.lower() or recipe_eq.lower() in avail_eq.lower():
                    matched_equipment.append(recipe_eq)
                    break
        if matched_equipment:
            reasons.append(f"可使用您的工具: {', '.join(matched_equipment)}")
    
    # 如果没有具体理由，使用通用说明
    if not reasons:
        if match_score >= 0.8:
            reasons.append("高度匹配您的需求")
        elif match_score >= 0.6:
            reasons.append("较好地匹配您的需求")
        else:
            reasons.append("部分匹配您的需求")
    
    return "；".join(reasons) if reasons else "推荐菜谱"
