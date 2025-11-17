//
//  RecipeModel.swift
//  ChefmanApp
//
//  Created by 杨雨桐 on 9/14/25.
//

import Foundation

// MARK: - Recipe Model (Matches Backend API Response)
struct Recipe: Codable, Identifiable, Hashable {
    let id: Int?
    let title: String
    let description: String?
    let imageUrl: String?
    let recipeType: String
    let cuisineType: String
    let prepTime: String?
    let cookTime: String?
    let totalTime: String?
    let servings: Int
    let difficulty: String
    let createdAt: Date?
    let updatedAt: Date?
    let likesCount: Int?
    let commentsCount: Int?
    let favoritesCount: Int?
    let todoCount: Int?
    let creatorId: Int?
    let creatorUsername: String?
    let caloriesPerServing: Int?
    let dietTypes: [String]?
    let steps: [RecipeStepDisplay]?
    let ingredients: [RecipeIngredientDisplay]?
    let equipment: [RecipeEquipmentDisplay]?
    
    // For local use
    var isFavorite: Bool = false
    
    init(id: Int? = nil, title: String, description: String? = nil, imageUrl: String? = nil, recipeType: String = "Dish", cuisineType: String = "Other", prepTime: String? = nil, cookTime: String? = nil, totalTime: String? = nil, servings: Int = 1, difficulty: String = "Easy", createdAt: Date? = nil, updatedAt: Date? = nil, likesCount: Int? = nil, commentsCount: Int? = nil, favoritesCount: Int? = nil, todoCount: Int? = nil, creatorId: Int? = nil, creatorUsername: String? = nil, caloriesPerServing: Int? = nil, dietTypes: [String]? = nil, isFavorite: Bool = false) {
        self.id = id
        self.title = title
        self.description = description
        self.imageUrl = imageUrl
        self.recipeType = recipeType
        self.cuisineType = cuisineType
        self.prepTime = prepTime
        self.cookTime = cookTime
        self.totalTime = totalTime
        self.servings = servings
        self.difficulty = difficulty
        self.createdAt = createdAt ?? Date()
        self.updatedAt = updatedAt
        self.likesCount = likesCount
        self.commentsCount = commentsCount
        self.favoritesCount = favoritesCount
        self.todoCount = todoCount
        self.creatorId = creatorId
        self.creatorUsername = creatorUsername
        self.caloriesPerServing = caloriesPerServing
        self.dietTypes = dietTypes
        self.steps = nil
        self.ingredients = nil
        self.equipment = nil
        self.isFavorite = isFavorite
    }
    
    // Coding keys to match API
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case imageUrl = "image_url"
        case recipeType = "recipe_type"
        case cuisineType = "cuisine_type"
        case prepTime = "prep_time"
        case cookTime = "cook_time"
        case totalTime = "total_time"
        case servings
        case difficulty
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case likesCount = "likes_count"
        case commentsCount = "comments_count"
        case favoritesCount = "favorites_count"
        case todoCount = "todo_count"
        case creatorId = "creator_id"
        case creatorUsername = "creator_username"
        case caloriesPerServing = "calories_per_serving"
        case dietTypes = "diet_types"
        case steps
        case ingredients
        case equipment
    }
    
    // Custom decoder to handle date strings
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decodeIfPresent(Int.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        recipeType = try container.decodeIfPresent(String.self, forKey: .recipeType) ?? "Dish"
        cuisineType = try container.decodeIfPresent(String.self, forKey: .cuisineType) ?? "Other"
        prepTime = try container.decodeIfPresent(String.self, forKey: .prepTime)
        cookTime = try container.decodeIfPresent(String.self, forKey: .cookTime)
        totalTime = try container.decodeIfPresent(String.self, forKey: .totalTime)
        servings = try container.decodeIfPresent(Int.self, forKey: .servings) ?? 1
        difficulty = try container.decodeIfPresent(String.self, forKey: .difficulty) ?? "Easy"
        
        // Handle date decoding
        if let createdAtString = try container.decodeIfPresent(String.self, forKey: .createdAt) {
            let formatter = ISO8601DateFormatter()
            createdAt = formatter.date(from: createdAtString)
        } else {
            createdAt = nil
        }
        
        if let updatedAtString = try container.decodeIfPresent(String.self, forKey: .updatedAt) {
            let formatter = ISO8601DateFormatter()
            updatedAt = formatter.date(from: updatedAtString)
        } else {
            updatedAt = nil
        }
        
        likesCount = try container.decodeIfPresent(Int.self, forKey: .likesCount)
        commentsCount = try container.decodeIfPresent(Int.self, forKey: .commentsCount)
        favoritesCount = try container.decodeIfPresent(Int.self, forKey: .favoritesCount)
        todoCount = try container.decodeIfPresent(Int.self, forKey: .todoCount)
        creatorId = try container.decodeIfPresent(Int.self, forKey: .creatorId)
        creatorUsername = try container.decodeIfPresent(String.self, forKey: .creatorUsername)
        caloriesPerServing = try container.decodeIfPresent(Int.self, forKey: .caloriesPerServing)
        dietTypes = try container.decodeIfPresent([String].self, forKey: .dietTypes)
        
        // Decode steps, ingredients, and equipment
        if let stepsArray = try container.decodeIfPresent([RecipeStepData].self, forKey: .steps) {
            steps = stepsArray.map { stepData in
                RecipeStepDisplay(
                    stepNumber: stepData.step_number,
                    description: stepData.description,
                    duration: stepData.duration,
                    temperature: stepData.temperature,
                    notes: stepData.notes,
                    imageUrl: stepData.image_url,
                    videoUrl: stepData.video_url
                )
            }
        } else {
            steps = nil
        }
        
        if let ingredientsArray = try container.decodeIfPresent([RecipeIngredientData].self, forKey: .ingredients) {
            ingredients = ingredientsArray.map { ingData in
                RecipeIngredientDisplay(
                    ingredientName: ingData.ingredient_name,
                    amount: ingData.amount,
                    unit: ingData.unit,
                    notes: ingData.notes
                )
            }
        } else {
            ingredients = nil
        }
        
        if let equipmentArray = try container.decodeIfPresent([RecipeEquipmentData].self, forKey: .equipment) {
            equipment = equipmentArray.map { eqData in
                RecipeEquipmentDisplay(
                    equipmentName: eqData.equipment_name,
                    brand: eqData.brand,
                    isChefman: eqData.is_chefman
                )
            }
        } else {
            equipment = nil
        }
        
        isFavorite = false
    }
    
    // Custom encoder to handle date strings and optional fields
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(imageUrl, forKey: .imageUrl)
        try container.encode(recipeType, forKey: .recipeType)
        try container.encode(cuisineType, forKey: .cuisineType)
        try container.encodeIfPresent(prepTime, forKey: .prepTime)
        try container.encodeIfPresent(cookTime, forKey: .cookTime)
        try container.encodeIfPresent(totalTime, forKey: .totalTime)
        try container.encode(servings, forKey: .servings)
        try container.encode(difficulty, forKey: .difficulty)
        
        // Handle date encoding
        if let createdAt = createdAt {
            let formatter = ISO8601DateFormatter()
            try container.encode(formatter.string(from: createdAt), forKey: .createdAt)
        }
        
        if let updatedAt = updatedAt {
            let formatter = ISO8601DateFormatter()
            try container.encode(formatter.string(from: updatedAt), forKey: .updatedAt)
        }
        
        try container.encodeIfPresent(likesCount, forKey: .likesCount)
        try container.encodeIfPresent(commentsCount, forKey: .commentsCount)
        try container.encodeIfPresent(favoritesCount, forKey: .favoritesCount)
        try container.encodeIfPresent(todoCount, forKey: .todoCount)
        try container.encodeIfPresent(creatorId, forKey: .creatorId)
        try container.encodeIfPresent(creatorUsername, forKey: .creatorUsername)
        try container.encodeIfPresent(caloriesPerServing, forKey: .caloriesPerServing)
        try container.encodeIfPresent(dietTypes, forKey: .dietTypes)
        
        // Encode steps, ingredients, and equipment
        // Note: We encode them as arrays, but since they contain UUIDs which are Codable,
        // this should work. However, if the backend doesn't expect UUIDs, we might need
        // to convert them back to RecipeStepData format.
        try container.encodeIfPresent(steps, forKey: .steps)
        try container.encodeIfPresent(ingredients, forKey: .ingredients)
        try container.encodeIfPresent(equipment, forKey: .equipment)
    }
}

// MARK: - Recipe Step Display (for UI)
struct RecipeStepDisplay: Identifiable, Hashable, Codable {
    let id: UUID
    let stepNumber: Int
    let description: String
    let duration: String?
    let temperature: String?
    let notes: String?
    let imageUrl: String?
    let videoUrl: String?
    
    init(stepNumber: Int, description: String, duration: String? = nil, temperature: String? = nil, notes: String? = nil, imageUrl: String? = nil, videoUrl: String? = nil) {
        self.id = UUID()
        self.stepNumber = stepNumber
        self.description = description
        self.duration = duration
        self.temperature = temperature
        self.notes = notes
        self.imageUrl = imageUrl
        self.videoUrl = videoUrl
    }
}

// MARK: - Recipe Ingredient Display (for UI)
struct RecipeIngredientDisplay: Identifiable, Hashable, Codable {
    let id: UUID
    let ingredientName: String
    let amount: String?
    let unit: String?
    let notes: String?
    
    init(ingredientName: String, amount: String? = nil, unit: String? = nil, notes: String? = nil) {
        self.id = UUID()
        self.ingredientName = ingredientName
        self.amount = amount
        self.unit = unit
        self.notes = notes
    }
}

// MARK: - Recipe Equipment Display (for UI)
struct RecipeEquipmentDisplay: Identifiable, Hashable, Codable {
    let id: UUID
    let equipmentName: String
    let brand: String?
    let isChefman: Bool
    
    init(equipmentName: String, brand: String? = nil, isChefman: Bool = false) {
        self.id = UUID()
        self.equipmentName = equipmentName
        self.brand = brand
        self.isChefman = isChefman
    }
}

// MARK: - Favorite Model
struct Favorite: Codable, Identifiable {
    let id: Int?
    let userId: Int
    let recipeId: Int
    let createdAt: Date?
    
    init(id: Int? = nil, userId: Int, recipeId: Int, createdAt: Date? = nil) {
        self.id = id
        self.userId = userId
        self.recipeId = recipeId
        self.createdAt = createdAt ?? Date()
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case recipeId = "recipe_id"
        case createdAt = "created_at"
    }
}

// MARK: - API Request Models
struct LoginRequest: Codable {
    let username: String
    let password: String
}

struct UsernameCheckResponse: Codable {
    let available: Bool
    let username: String
}

struct RegisterRequest: Codable {
    let username: String
    let email: String
    let password: String
    let phone_number: String?
    let first_name: String?
    let last_name: String?
    let gender: String?
    let birth_date: String?
    let bio: String?
    let profile_image_url: String?
    let address: String?
    let city: String?
    let country: String?
    let postal_code: String?
    
    init(username: String, email: String, password: String, phone_number: String? = nil, first_name: String? = nil, last_name: String? = nil, gender: String? = "Not specified", birth_date: String? = nil, bio: String? = nil, profile_image_url: String? = nil, address: String? = nil, city: String? = nil, country: String? = nil, postal_code: String? = nil) {
        self.username = username
        self.email = email
        self.password = password
        self.phone_number = phone_number
        self.first_name = first_name
        self.last_name = last_name
        self.gender = gender
        self.birth_date = birth_date
        self.bio = bio
        self.profile_image_url = profile_image_url
        self.address = address
        self.city = city
        self.country = country
        self.postal_code = postal_code
    }
}

struct CreateRecipeRequest: Codable {
    let title: String
    let description: String?
    let imageUrl: String?
}

// MARK: - Recipe Creation Models (Matches Backend RecipeCreate)
struct RecipeIngredientData: Codable {
    let ingredient_name: String
    let amount: String?
    let unit: String?
    let notes: String?
}

struct RecipeStepData: Codable {
    let step_number: Int
    let description: String
    let duration: String?
    let temperature: String?
    let notes: String?
    let image_url: String?  // 步骤图片（可选）
    let video_url: String?  // 步骤视频（可选）
}

struct RecipeEquipmentData: Codable {
    let equipment_name: String
    let brand: String?
    let is_chefman: Bool
}

// MARK: - AI Recipe Matching Models
struct RecipeMatchRequest: Codable {
    let dietRequirements: [String]
    let availableIngredients: [String]
    let availableEquipment: [String]
    let limit: Int
    
    enum CodingKeys: String, CodingKey {
        case dietRequirements = "diet_requirements"
        case availableIngredients = "available_ingredients"
        case availableEquipment = "available_equipment"
        case limit
    }
}

struct MatchedRecipe: Codable, Identifiable, Hashable {
    let recipe: Recipe
    let matchScore: Double
    let matchReason: String?
    
    var id: Int {
        recipe.id ?? recipe.title.hashValue
    }
    
    enum CodingKeys: String, CodingKey {
        case recipe
        case matchScore = "match_score"
        case matchReason = "match_reason"
    }
}

struct RecipeCreateData: Codable {
    let title: String
    let description: String?
    let image_url: String?
    let recipe_type: String
    let cuisine_type: String
    let prep_time: String?
    let cook_time: String?
    let total_time: String?
    let servings: Int
    let difficulty: String
    let ingredients: [RecipeIngredientData]
    let steps: [RecipeStepData]
    let equipment: [RecipeEquipmentData]
}

struct AddFavoriteRequest: Codable {
    let recipeId: Int
}

// MARK: - API Response Models
struct AuthResponse: Codable {
    let accessToken: String
    let tokenType: String
    let user: User
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case user
    }
}

struct ApiResponse<T: Codable>: Codable {
    let success: Bool
    let message: String?
    let data: T?
}

struct ErrorResponse: Codable {
    let detail: String
}

struct UserUpdateRequest: Codable {
    let username: String?
    let email: String?
    let gender: String?
    let birthDate: Date?
    let bio: String?
    let profileImageUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case username
        case email
        case gender
        case birthDate = "birth_date"
        case bio
        case profileImageUrl = "profile_image_url"
    }
}

// MARK: - Image Upload Models
struct ImageUploadResponse: Codable {
    let success: Bool
    let image: ImageInfo
    let message: String
}

struct ImageInfo: Codable {
    let id: String
    let filename: String
    let originalUrl: String
    let thumbnailUrl: String
    let size: Int
    let category: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case filename
        case originalUrl = "original_url"
        case thumbnailUrl = "thumbnail_url"
        case size
        case category
    }
}
