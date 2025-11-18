//
//  APIClient.swift
//  ChefmanApp
//
//  Created by 杨雨桐 on 9/14/25.
//

import Foundation
import UIKit

// MARK: - FastAPI Client
class APIClient: ObservableObject {
    static let shared = APIClient()
    
    // API Configuration
    private let baseURL = APIConfig.baseURL
    private let session = URLSession.shared
    
    // Authentication token
    @Published var authToken: String?
    @Published var currentUser: User?
    
    private init() {}
    
    // MARK: - Authentication Endpoints
    
    func checkUsernameAvailability(username: String) async throws -> Bool {
        let url = URL(string: "\(baseURL)/check-username/\(username)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            if httpResponse.statusCode == 200 {
                let result = try JSONDecoder().decode(UsernameCheckResponse.self, from: data)
                return result.available
            } else if httpResponse.statusCode == 404 {
                // Username not found, so it's available
                return true
            } else {
                throw APIError.serverError("Failed to check username availability")
            }
        } catch {
            print("❌ Username check failed: \(error.localizedDescription)")
            throw error
        }
    }
    
    func login(username: String, password: String) async throws -> AuthResponse {
        let url = URL(string: "\(baseURL)/login")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let loginRequest = LoginRequest(username: username, password: password)
        request.httpBody = try JSONEncoder().encode(loginRequest)
        
        print("🔍 API Request URL: \(url)")
        print("🔍 Base URL: \(baseURL)")
        print("🔍 Request body: \(String(data: request.httpBody!, encoding: .utf8) ?? "nil")")
        
        do {
            let (data, response) = try await session.data(for: request)
            
            print("🔍 Response data: \(String(data: data, encoding: .utf8) ?? "nil")")
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid response type")
                throw APIError.invalidResponse
            }
            
            print("🔍 HTTP Status: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode == 200 {
                do {
                    let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
                    self.authToken = authResponse.accessToken
                    self.currentUser = authResponse.user
                    print("✅ Successfully decoded AuthResponse")
                    return authResponse
                } catch {
                    print("❌ Decoding error: \(error)")
                    print("❌ Raw data: \(String(data: data, encoding: .utf8) ?? "nil")")
                    throw error
                }
            } else {
                do {
                    let errorResponse = try JSONDecoder().decode(ErrorResponse.self, from: data)
                    print("❌ Server error: \(errorResponse.detail)")
                    throw APIError.serverError(errorResponse.detail)
                } catch {
                    print("❌ Failed to decode error response: \(error)")
                    throw APIError.serverError("Unknown server error")
                }
            }
        } catch {
            print("❌ Network error: \(error)")
            print("❌ Error type: \(type(of: error))")
            print("❌ Error description: \(error.localizedDescription)")
            throw error
        }
    }
    
    func register(username: String, email: String, password: String, phone_number: String? = nil, first_name: String? = nil, last_name: String? = nil, gender: String? = "Not specified", birth_date: String? = nil, bio: String? = nil, profile_image_url: String? = nil, address: String? = nil, city: String? = nil, country: String? = nil, postal_code: String? = nil) async throws -> User {
        let url = URL(string: "\(baseURL)/register")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let registerRequest = RegisterRequest(
            username: username, 
            email: email, 
            password: password,
            phone_number: phone_number,
            first_name: first_name,
            last_name: last_name,
            gender: gender,
            birth_date: birth_date,
            bio: bio,
            profile_image_url: profile_image_url,
            address: address,
            city: city,
            country: country,
            postal_code: postal_code
        )
        request.httpBody = try JSONEncoder().encode(registerRequest)
        
        print("🔍 Register request URL: \(url)")
        print("🔍 Register request body: \(String(data: request.httpBody!, encoding: .utf8) ?? "nil")")
        
        do {
            let (data, response) = try await session.data(for: request)
            
            print("🔍 Register response data: \(String(data: data, encoding: .utf8) ?? "nil")")
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            print("🔍 Register HTTP Status: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode == 200 {
                do {
                    var user = try JSONDecoder().decode(User.self, from: data)
                    // 保存密码用于显示（仅客户端本地，不会发送到服务器）
                    // 注意：API 不会返回密码，所以这里需要从注册请求中获取
                    return user
                } catch {
                    print("❌ Failed to decode user response: \(error)")
                    print("❌ Raw data: \(String(data: data, encoding: .utf8) ?? "nil")")
                    throw APIError.serverError("Failed to decode server response")
                }
            } else {
                do {
                    let errorResponse = try JSONDecoder().decode(ErrorResponse.self, from: data)
                    print("❌ Server error: \(errorResponse.detail)")
                    throw APIError.serverError(errorResponse.detail)
                } catch {
                    print("❌ Failed to decode error response: \(error)")
                    let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown server error"
                    throw APIError.serverError(errorMessage)
                }
            }
        } catch let error as APIError {
            throw error
        } catch {
            print("❌ Network error: \(error)")
            throw APIError.networkError(error)
        }
    }
    
    func logout() {
        authToken = nil
        currentUser = nil
    }
    
    // MARK: - User Management Endpoints
    
    func getUsers() async throws -> [User] {
        let url = URL(string: "\(baseURL)/users")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode == 200 {
            let users = try JSONDecoder().decode([User].self, from: data)
            return users
        } else {
            let errorResponse = try JSONDecoder().decode(ErrorResponse.self, from: data)
            throw APIError.serverError(errorResponse.detail)
        }
    }
    
    func updateUserProfile(username: String?, email: String?, gender: String?, birthDate: Date?, bio: String?, profileImageUrl: String?) async throws -> User {
        let url = URL(string: "\(baseURL)/users/me")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let updateRequest = UserUpdateRequest(
            username: username,
            email: email,
            gender: gender,
            birthDate: birthDate,
            bio: bio,
            profileImageUrl: profileImageUrl
        )
        
        request.httpBody = try JSONEncoder().encode(updateRequest)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode == 200 {
            let user = try JSONDecoder().decode(User.self, from: data)
            self.currentUser = user
            return user
        } else {
            let errorResponse = try JSONDecoder().decode(ErrorResponse.self, from: data)
            throw APIError.serverError(errorResponse.detail)
        }
    }
    
    // MARK: - Recipe Endpoints
    
    func getRecipes() async throws -> [Recipe] {
        let url = URL(string: "\(baseURL)/recipes")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        print("🔍 API Request: GET \(url)")
        print("🔍 Auth Token: \(authToken != nil ? "Present" : "Missing")")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        print("🔍 API Response: \(httpResponse.statusCode)")
        print("🔍 Response data: \(String(data: data, encoding: .utf8) ?? "nil")")
        
        if httpResponse.statusCode == 200 {
            let recipes = try JSONDecoder().decode([Recipe].self, from: data)
            print("✅ Decoded \(recipes.count) recipes from API")
            return recipes
        } else {
            throw APIError.serverError("Failed to fetch recipes")
        }
    }

    func matchRecipes(
        dietRequirements: [String],
        availableIngredients: [String],
        availableEquipment: [String],
        limit: Int = 5
    ) async throws -> [MatchedRecipe] {
        let url = URL(string: "\(baseURL)/recipes/match")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let matchRequest = RecipeMatchRequest(
            dietRequirements: dietRequirements,
            availableIngredients: availableIngredients,
            availableEquipment: availableEquipment,
            limit: limit
        )
        
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(matchRequest)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode == 200 {
            let matches = try JSONDecoder().decode([MatchedRecipe].self, from: data)
            return matches
        } else {
            do {
                let errorResponse = try JSONDecoder().decode(ErrorResponse.self, from: data)
                throw APIError.serverError(errorResponse.detail)
            } catch let decodingError as DecodingError {
                print("❌ Failed to decode match error: \(decodingError)")
                let message = String(data: data, encoding: .utf8) ?? "Unknown server error"
                throw APIError.serverError(message)
            } catch {
                throw APIError.serverError("Failed to match recipes")
            }
        }
    }
    
    func getRecipe(recipeId: Int) async throws -> Recipe {
        let url = URL(string: "\(baseURL)/recipes/\(recipeId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode == 200 {
            let recipe = try JSONDecoder().decode(Recipe.self, from: data)
            return recipe
        } else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.serverError(errorMessage)
        }
    }
    
    func createRecipe(recipeData: RecipeCreateData) async throws -> Recipe {
        let url = URL(string: "\(baseURL)/recipes")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            print("🔍 Using auth token: \(token.prefix(20))...")
        } else {
            print("❌ No auth token available for recipe creation")
            throw APIError.serverError("Authentication required. Please login first.")
        }
        
        // Encode request body
        // Note: RecipeCreateData already uses snake_case field names, so no conversion needed
        let encoder = JSONEncoder()
        let requestBody = try encoder.encode(recipeData)
        request.httpBody = requestBody
        
        // Debug: Print request details
        if let bodyString = String(data: requestBody, encoding: .utf8) {
            print("🔍 Creating recipe - Request body: \(bodyString)")
        }
        print("🔍 Creating recipe - Title: \(recipeData.title)")
        print("🔍 Creating recipe - Ingredients count: \(recipeData.ingredients.count)")
        print("🔍 Creating recipe - Steps count: \(recipeData.steps.count)")
        print("🔍 Creating recipe - Equipment count: \(recipeData.equipment.count)")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        let responseString = String(data: data, encoding: .utf8) ?? "nil"
        print("🔍 HTTP Status: \(httpResponse.statusCode)")
        print("🔍 Response data: \(responseString)")
        
        if httpResponse.statusCode == 200 {
            do {
                let recipe = try JSONDecoder().decode(Recipe.self, from: data)
                print("✅ Recipe created successfully: \(recipe.title)")
                return recipe
            } catch {
                print("❌ Failed to decode recipe response: \(error)")
                print("❌ Response data: \(responseString)")
                throw APIError.serverError("Failed to decode server response: \(error.localizedDescription)")
            }
        } else {
            do {
                let errorResponse = try JSONDecoder().decode(ErrorResponse.self, from: data)
                print("❌ Server error: \(errorResponse.detail)")
                throw APIError.serverError(errorResponse.detail)
            } catch {
                print("❌ Failed to decode error response: \(error)")
                print("❌ Raw response: \(responseString)")
                throw APIError.serverError("Server error (Status \(httpResponse.statusCode)): \(responseString)")
            }
        }
    }
    
    // MARK: - Favorites Endpoints
    
    func getFavorites() async throws -> [Recipe] {
        let url = URL(string: "\(baseURL)/favorites")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode == 200 {
            let recipes = try JSONDecoder().decode([Recipe].self, from: data)
            return recipes
        } else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.serverError(errorMessage)
        }
    }
    
    func addFavorite(recipeId: Int) async throws -> Favorite {
        // Add recipe_id as query parameter (same as todo list)
        var urlComponents = URLComponents(string: "\(baseURL)/favorites")!
        urlComponents.queryItems = [URLQueryItem(name: "recipe_id", value: "\(recipeId)")]
        
        guard let url = urlComponents.url else {
            throw APIError.invalidResponse
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode == 200 {
            let favorite = try JSONDecoder().decode(Favorite.self, from: data)
            return favorite
        } else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.serverError(errorMessage)
        }
    }
    
    func removeFavorite(recipeId: Int) async throws {
        let url = URL(string: "\(baseURL)/favorites/\(recipeId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            throw APIError.serverError("Failed to remove favorite")
        }
    }
    
    // MARK: - Comment API Methods
    func getComments(for recipeId: Int) async throws -> [Comment] {
        let url = URL(string: "\(baseURL)/recipes/\(recipeId)/comments")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode == 200 {
            let comments = try JSONDecoder().decode([Comment].self, from: data)
            return comments
        } else {
            throw APIError.serverError("Failed to fetch comments")
        }
    }
    
    func createComment(for recipeId: Int, content: String) async throws -> Comment {
        let url = URL(string: "\(baseURL)/recipes/\(recipeId)/comments")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let commentData = ["content": content]
        request.httpBody = try JSONSerialization.data(withJSONObject: commentData)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode == 200 {
            let comment = try JSONDecoder().decode(Comment.self, from: data)
            return comment
        } else {
            let errorResponse = try JSONDecoder().decode(ErrorResponse.self, from: data)
            throw APIError.serverError(errorResponse.detail)
        }
    }
    
    func deleteComment(commentId: Int) async throws {
        let url = URL(string: "\(baseURL)/comments/\(commentId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            throw APIError.serverError("Failed to delete comment")
        }
    }
    
    // MARK: - Image Upload Methods
    func uploadImage(image: UIImage, category: String = "recipes") async throws -> ImageUploadResponse {
        let url = URL(string: "\(baseURL)/upload/image")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Create multipart form data
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add category field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"category\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(category)\r\n".data(using: .utf8)!)
        
        // Add image field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        
        if let imageData = image.jpegData(compressionQuality: 0.8) {
            body.append(imageData)
        }
        
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode == 200 {
            let uploadResponse = try JSONDecoder().decode(ImageUploadResponse.self, from: data)
            return uploadResponse
        } else {
            let errorResponse = try JSONDecoder().decode(ErrorResponse.self, from: data)
            throw APIError.serverError(errorResponse.detail)
        }
    }
    
    func deleteImage(category: String, filename: String) async throws {
        let url = URL(string: "\(baseURL)/images/\(category)/\(filename)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            throw APIError.serverError("Failed to delete image")
        }
    }
    
    // MARK: - Interaction Methods
    
    // Like/Unlike Recipe
    func likeRecipe(recipeId: Int) async throws {
        let url = URL(string: "\(baseURL)/recipes/\(recipeId)/like")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            let errorData = try? await session.data(for: request)
            let errorMessage = String(data: errorData?.0 ?? Data(), encoding: .utf8) ?? "Unknown error"
            throw APIError.serverError(errorMessage)
        }
    }
    
    func unlikeRecipe(recipeId: Int) async throws {
        let url = URL(string: "\(baseURL)/recipes/\(recipeId)/like")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            let errorData = try? await session.data(for: request)
            let errorMessage = String(data: errorData?.0 ?? Data(), encoding: .utf8) ?? "Unknown error"
            throw APIError.serverError(errorMessage)
        }
    }
    
    func getRecipeLikes(recipeId: Int) async throws -> Int {
        let url = URL(string: "\(baseURL)/recipes/\(recipeId)/likes")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode == 200 {
            let result = try JSONDecoder().decode(LikesCountResponse.self, from: data)
            return result.likesCount
        } else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.serverError(errorMessage)
        }
    }
    
    // Todo List Methods
    func addToTodoList(recipeId: Int) async throws {
        // Add recipe_id as query parameter
        var urlComponents = URLComponents(string: "\(baseURL)/todo-list")!
        urlComponents.queryItems = [URLQueryItem(name: "recipe_id", value: "\(recipeId)")]
        
        guard let url = urlComponents.url else {
            throw APIError.invalidResponse
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.serverError(errorMessage)
        }
    }
    
    func removeFromTodoList(recipeId: Int) async throws {
        let url = URL(string: "\(baseURL)/todo-list/\(recipeId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            let errorData = try? await session.data(for: request)
            let errorMessage = String(data: errorData?.0 ?? Data(), encoding: .utf8) ?? "Unknown error"
            throw APIError.serverError(errorMessage)
        }
    }
    
    // Todo list item with completion status
    struct TodoListItem: Codable {
        let recipe: Recipe
        let completed: Bool
        let todoId: String?
        
        enum CodingKeys: String, CodingKey {
            case recipe
            case completed
            case todoId = "todo_id"
        }
    }
    
    func getTodoList() async throws -> [TodoListItem] {
        let url = URL(string: "\(baseURL)/todo-list")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode == 200 {
            let items = try JSONDecoder().decode([TodoListItem].self, from: data)
            return items
        } else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.serverError(errorMessage)
        }
    }
    
    func toggleTodoCompletion(recipeId: Int, completed: Bool) async throws {
        var urlComponents = URLComponents(string: "\(baseURL)/todo-list/\(recipeId)/complete")!
        urlComponents.queryItems = [URLQueryItem(name: "completed", value: completed ? "true" : "false")]
        
        guard let url = urlComponents.url else {
            throw APIError.invalidResponse
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.serverError(errorMessage)
        }
    }
    
    // Get user interactions with a recipe
    func getUserInteractions(recipeId: Int) async throws -> UserInteractions {
        let url = URL(string: "\(baseURL)/recipes/\(recipeId)/user-interactions")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode == 200 {
            let interactions = try JSONDecoder().decode(UserInteractions.self, from: data)
            return interactions
        } else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.serverError(errorMessage)
        }
    }
    
    // MARK: - Follow Methods
    func followUser(userId: Int) async throws {
        let url = URL(string: "\(baseURL)/users/\(userId)/follow")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.serverError(errorMessage)
        }
    }
    
    func unfollowUser(userId: Int) async throws {
        let url = URL(string: "\(baseURL)/users/\(userId)/follow")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.serverError(errorMessage)
        }
    }
    
    func getFollowStatus(userId: Int) async throws -> Bool {
        let url = URL(string: "\(baseURL)/users/\(userId)/follow-status")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode == 200 {
            let result = try JSONDecoder().decode(FollowStatusResponse.self, from: data)
            return result.isFollowing
        } else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.serverError(errorMessage)
        }
    }
    
    // MARK: - User Statistics
    func getUserStats() async throws -> UserStats {
        let url = URL(string: "\(baseURL)/users/me/stats")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode == 200 {
            let stats = try JSONDecoder().decode(UserStats.self, from: data)
            return stats
        } else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.serverError(errorMessage)
        }
    }
    
    // MARK: - My Recipes
    func getMyRecipes() async throws -> [Recipe] {
        let url = URL(string: "\(baseURL)/users/me/recipes")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode == 200 {
            let recipes = try JSONDecoder().decode([Recipe].self, from: data)
            return recipes
        } else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.serverError(errorMessage)
        }
    }
    
    // MARK: - User Profile
    func getUserProfile(userId: Int) async throws -> UserProfile {
        let url = URL(string: "\(baseURL)/users/\(userId)/profile")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode == 200 {
            do {
                // Print raw JSON for debugging
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("🔍 UserProfile JSON response: \(jsonString)")
                }
                let profile = try JSONDecoder().decode(UserProfile.self, from: data)
                return profile
            } catch let decodingError as DecodingError {
                print("❌ Failed to decode UserProfile: \(decodingError)")
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("❌ Raw JSON: \(jsonString)")
                }
                throw decodingError
            }
        } else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.serverError(errorMessage)
        }
    }
    
    func getUserRecipes(userId: Int) async throws -> [Recipe] {
        let url = URL(string: "\(baseURL)/users/\(userId)/recipes")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode == 200 {
            let recipes = try JSONDecoder().decode([Recipe].self, from: data)
            return recipes
        } else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.serverError(errorMessage)
        }
    }
    
    // MARK: - Followers and Following Methods
    func getMyFollowers() async throws -> [User] {
        let url = URL(string: "\(baseURL)/users/me/followers")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode == 200 {
            let users = try JSONDecoder().decode([User].self, from: data)
            return users
        } else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.serverError(errorMessage)
        }
    }
    
    func getMyFollowing() async throws -> [User] {
        let url = URL(string: "\(baseURL)/users/me/following")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode == 200 {
            let users = try JSONDecoder().decode([User].self, from: data)
            return users
        } else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.serverError(errorMessage)
        }
    }
    
    func getMyLikedRecipes() async throws -> [Recipe] {
        let url = URL(string: "\(baseURL)/users/me/liked-recipes")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode == 200 {
            let recipes = try JSONDecoder().decode([Recipe].self, from: data)
            return recipes
        } else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.serverError(errorMessage)
        }
    }
}

// MARK: - Response Models
struct LikesCountResponse: Codable {
    let likesCount: Int
    
    enum CodingKeys: String, CodingKey {
        case likesCount = "likes_count"
    }
}

struct UserInteractions: Codable {
    let isFavorited: Bool
    let isLiked: Bool
    let isInTodo: Bool
    let isFollowingCreator: Bool?
    
    enum CodingKeys: String, CodingKey {
        case isFavorited = "is_favorited"
        case isLiked = "is_liked"
        case isInTodo = "is_in_todo"
        case isFollowingCreator = "is_following_creator"
    }
}

struct FollowStatusResponse: Codable {
    let isFollowing: Bool
    
    enum CodingKeys: String, CodingKey {
        case isFollowing = "is_following"
    }
}

struct UserStats: Codable {
    let followersCount: Int
    let followingCount: Int
    let totalLikesReceived: Int
    let recipesCount: Int
    
    enum CodingKeys: String, CodingKey {
        case followersCount = "followers_count"
        case followingCount = "following_count"
        case totalLikesReceived = "total_likes_received"
        case recipesCount = "recipes_count"
    }
}

struct UserProfile: Codable {
    let id: Int
    let username: String
    let email: String?
    let bio: String?
    let gender: String?
    let profileImageUrl: String?
    let recipesCount: Int
    let followersCount: Int
    let followingCount: Int
    let totalLikesReceived: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case email
        case bio
        case gender
        case profileImageUrl = "profile_image_url"
        case recipesCount = "recipes_count"
        case followersCount = "followers_count"
        case followingCount = "following_count"
        case totalLikesReceived = "total_likes_received"
    }
}

// MARK: - API Errors
enum APIError: Error, LocalizedError {
    case invalidResponse
    case serverError(String)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .serverError(let message):
            return message
        case .networkError(let error):
            return error.localizedDescription
        }
    }
}

