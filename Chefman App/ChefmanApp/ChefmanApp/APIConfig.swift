//
//  APIConfig.swift
//  ChefmanApp
//
//  Created by 杨雨桐 on 9/14/25.
//

import Foundation

// MARK: - API Configuration
struct APIConfig {
    // MARK: - Environment Configuration
    // 根据构建配置自动选择 API URL
    // Debug: 本地开发服务器
    // Release: 生产环境服务器（用于 TestFlight 和 App Store）
    
    #if DEBUG
    // 开发环境 - 本地服务器
    static let baseURL = "http://127.0.0.1:8000"
    #else
    // 生产环境 - 请替换为你的生产服务器地址
    // 例如: "https://api.yourdomain.com" 或 "https://your-server.herokuapp.com"
    static let baseURL = "https://your-production-api-url.com"
    #endif
    
    static let apiVersion = "v1"
    
    // Endpoints (Updated to match your FastAPI backend)
    struct Endpoints {
        static let login = "/login"
        static let register = "/register"
        static let logout = "/logout"
        static let recipes = "/recipes"
        static let favorites = "/favorites"
        static let users = "/users"
        
        // Test endpoints (for development)
        static let testRecipes = "/test/recipes"
        static let testFavorites = "/test/favorites"
    }
    
    // Headers
    struct Headers {
        static let contentType = "application/json"
        static let authorization = "Authorization"
    }
    
    // MARK: - Setup Instructions
    static func printSetupInstructions() {
        print("""
        🚀 FastAPI Integration Setup Instructions:
        
        1. Make sure your FastAPI server is running on: \(baseURL)
        
        2. Update the baseURL in APIConfig.swift if your server runs on a different port:
           static let baseURL = "http://your-server:port"
        
        3. Ensure your FastAPI endpoints match:
           - POST /auth/login
           - POST /auth/register
           - GET /recipes
           - GET /favorites
           - POST /favorites
           - DELETE /favorites/{recipe_id}
        
        4. Test your FastAPI server:
           curl -X GET \(baseURL)/docs
        
        5. Database should be running with the schema you provided:
           - Database: chefman_app
           - Tables: users, recipes, favorites
        
        📊 Current Configuration:
        🌐 Base URL: \(baseURL)
        📱 API Version: \(apiVersion)
        """)
    }
    
    // MARK: - Connection Test
    static func testConnection() async -> Bool {
        guard let url = URL(string: "\(baseURL)/docs") else { return false }
        
        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            if let httpResponse = response as? HTTPURLResponse {
                return httpResponse.statusCode == 200
            }
        } catch {
            print("❌ Failed to connect to FastAPI server: \(error.localizedDescription)")
        }
        
        return false
    }
}
