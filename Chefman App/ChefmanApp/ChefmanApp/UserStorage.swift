//
//  UserStorage.swift
//  ChefmanApp
//
//  Created by 杨雨桐 on 9/14/25.
//

import Foundation
import SQLite3

// MARK: - User Model
struct User: Codable, Identifiable, Hashable {
    let id: Int?
    let username: String
    let email: String
    let password: String?
    let passwordHash: String?
    let createdAt: Date?
    let lastLoginAt: Date?
    let gender: String?
    let birthDate: Date?
    let bio: String?
    let profileImageUrl: String?
    let updatedAt: Date?
    
    init(id: Int? = nil, username: String, email: String, password: String? = nil, passwordHash: String? = nil, createdAt: Date? = nil, lastLoginAt: Date? = nil, gender: String? = nil, birthDate: Date? = nil, bio: String? = nil, profileImageUrl: String? = nil, updatedAt: Date? = nil) {
        self.id = id
        self.username = username
        self.email = email
        self.password = password
        self.passwordHash = passwordHash
        self.createdAt = createdAt
        self.lastLoginAt = lastLoginAt
        self.gender = gender
        self.birthDate = birthDate
        self.bio = bio
        self.profileImageUrl = profileImageUrl
        self.updatedAt = updatedAt
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case email
        case password
        case passwordHash = "password_hash"
        case createdAt = "created_at"
        case lastLoginAt = "last_login_at"
        case gender
        case birthDate = "birth_date"
        case bio
        case profileImageUrl = "profile_image_url"
        case updatedAt = "updated_at"
    }
    
    // Custom decoder to handle date strings
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decodeIfPresent(Int.self, forKey: .id)
        username = try container.decode(String.self, forKey: .username)
        email = try container.decode(String.self, forKey: .email)
        password = try container.decodeIfPresent(String.self, forKey: .password)
        passwordHash = try container.decodeIfPresent(String.self, forKey: .passwordHash)
        gender = try container.decodeIfPresent(String.self, forKey: .gender)
        bio = try container.decodeIfPresent(String.self, forKey: .bio)
        profileImageUrl = try container.decodeIfPresent(String.self, forKey: .profileImageUrl)
        
        // Handle date decoding
        if let createdAtString = try container.decodeIfPresent(String.self, forKey: .createdAt) {
            let formatter = ISO8601DateFormatter()
            createdAt = formatter.date(from: createdAtString)
        } else {
            createdAt = nil
        }
        
        if let lastLoginAtString = try container.decodeIfPresent(String.self, forKey: .lastLoginAt) {
            let formatter = ISO8601DateFormatter()
            lastLoginAt = formatter.date(from: lastLoginAtString)
        } else {
            lastLoginAt = nil
        }
        
        if let birthDateString = try container.decodeIfPresent(String.self, forKey: .birthDate) {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            birthDate = formatter.date(from: birthDateString)
        } else {
            birthDate = nil
        }
        
        if let updatedAtString = try container.decodeIfPresent(String.self, forKey: .updatedAt) {
            let formatter = ISO8601DateFormatter()
            updatedAt = formatter.date(from: updatedAtString)
        } else {
            updatedAt = nil
        }
    }
}

// MARK: - User Database Manager
class UserDatabaseManager: ObservableObject {
    static let shared = UserDatabaseManager()
    
    private var db: OpaquePointer?
    private let dbPath: String
    
    @Published var users: [User] = []
    
    private init() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        dbPath = documentsPath.appendingPathComponent("users.db").path
        
        if sqlite3_open(dbPath, &db) == SQLITE_OK {
            createTable()
            loadUsers()
        } else {
            print("Unable to open database. Error: \(String(cString: sqlite3_errmsg(db)))")
        }
    }
    
    deinit {
        sqlite3_close(db)
    }
    
    private func createTable() {
        let createTableSQL = """
            CREATE TABLE IF NOT EXISTS users (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                username TEXT UNIQUE NOT NULL,
                email TEXT UNIQUE NOT NULL,
                password_hash TEXT,
                gender TEXT,
                birth_date TEXT,
                bio TEXT,
                profile_image_url TEXT,
                created_at TEXT,
                last_login_at TEXT,
                updated_at TEXT
            );
        """
        
        if sqlite3_exec(db, createTableSQL, nil, nil, nil) == SQLITE_OK {
            print("Users table created successfully")
        } else {
            print("Unable to create table. Error: \(String(cString: sqlite3_errmsg(db)))")
        }
    }
    
    func saveUser(_ user: User) {
        let insertSQL = """
            INSERT INTO users (username, email, password_hash, gender, birth_date, bio, profile_image_url, created_at, last_login_at, updated_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
        """
        
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, insertSQL, -1, &statement, nil) == SQLITE_OK {
            let username = user.username as NSString
            let email = user.email as NSString
            let passwordHash = (user.passwordHash ?? "") as NSString
            let gender = (user.gender ?? "") as NSString
            let birthDate = (user.birthDate?.description ?? "") as NSString
            let bio = (user.bio ?? "") as NSString
            let profileImageUrl = (user.profileImageUrl ?? "") as NSString
            let createdAt = (user.createdAt?.description ?? "") as NSString
            let lastLoginAt = (user.lastLoginAt?.description ?? "") as NSString
            let updatedAt = (user.updatedAt?.description ?? "") as NSString
            
            sqlite3_bind_text(statement, 1, username.utf8String, -1, nil)
            sqlite3_bind_text(statement, 2, email.utf8String, -1, nil)
            sqlite3_bind_text(statement, 3, passwordHash.utf8String, -1, nil)
            sqlite3_bind_text(statement, 4, gender.utf8String, -1, nil)
            sqlite3_bind_text(statement, 5, birthDate.utf8String, -1, nil)
            sqlite3_bind_text(statement, 6, bio.utf8String, -1, nil)
            sqlite3_bind_text(statement, 7, profileImageUrl.utf8String, -1, nil)
            sqlite3_bind_text(statement, 8, createdAt.utf8String, -1, nil)
            sqlite3_bind_text(statement, 9, lastLoginAt.utf8String, -1, nil)
            sqlite3_bind_text(statement, 10, updatedAt.utf8String, -1, nil)
            
            if sqlite3_step(statement) == SQLITE_DONE {
                print("User saved successfully")
                loadUsers()
            } else {
                print("Unable to save user. Error: \(String(cString: sqlite3_errmsg(db)))")
            }
        }
        
        sqlite3_finalize(statement)
    }
    
    func updateUser(_ user: User) {
        guard let id = user.id else { return }
        
        let updateSQL = """
            UPDATE users SET username = ?, email = ?, password_hash = ?, gender = ?, birth_date = ?, bio = ?, profile_image_url = ?, updated_at = ?
            WHERE id = ?;
        """
        
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, updateSQL, -1, &statement, nil) == SQLITE_OK {
            let username = user.username as NSString
            let email = user.email as NSString
            let passwordHash = (user.passwordHash ?? "") as NSString
            let gender = (user.gender ?? "") as NSString
            let birthDate = (user.birthDate?.description ?? "") as NSString
            let bio = (user.bio ?? "") as NSString
            let profileImageUrl = (user.profileImageUrl ?? "") as NSString
            let updatedAt = (user.updatedAt?.description ?? "") as NSString
            
            sqlite3_bind_text(statement, 1, username.utf8String, -1, nil)
            sqlite3_bind_text(statement, 2, email.utf8String, -1, nil)
            sqlite3_bind_text(statement, 3, passwordHash.utf8String, -1, nil)
            sqlite3_bind_text(statement, 4, gender.utf8String, -1, nil)
            sqlite3_bind_text(statement, 5, birthDate.utf8String, -1, nil)
            sqlite3_bind_text(statement, 6, bio.utf8String, -1, nil)
            sqlite3_bind_text(statement, 7, profileImageUrl.utf8String, -1, nil)
            sqlite3_bind_text(statement, 8, updatedAt.utf8String, -1, nil)
            sqlite3_bind_int(statement, 9, Int32(id))
            
            if sqlite3_step(statement) == SQLITE_DONE {
                print("User updated successfully")
                loadUsers()
            } else {
                print("Unable to update user. Error: \(String(cString: sqlite3_errmsg(db)))")
            }
        }
        
        sqlite3_finalize(statement)
    }
    
    func deleteUser(_ user: User) {
        guard let id = user.id else { return }
        
        let deleteSQL = "DELETE FROM users WHERE id = ?;"
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, deleteSQL, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_int(statement, 1, Int32(id))
            
            if sqlite3_step(statement) == SQLITE_DONE {
                print("User deleted successfully")
                loadUsers()
            } else {
                print("Unable to delete user. Error: \(String(cString: sqlite3_errmsg(db)))")
            }
        }
        
        sqlite3_finalize(statement)
    }
    
    func loadUsers() {
        users.removeAll()
        
        let querySQL = "SELECT * FROM users;"
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, querySQL, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                let id = Int(sqlite3_column_int(statement, 0))
                let username = String(cString: sqlite3_column_text(statement, 1))
                let email = String(cString: sqlite3_column_text(statement, 2))
                let passwordHash = String(cString: sqlite3_column_text(statement, 3))
                let gender = String(cString: sqlite3_column_text(statement, 4))
                let birthDate = String(cString: sqlite3_column_text(statement, 5))
                let bio = String(cString: sqlite3_column_text(statement, 6))
                let profileImageUrl = String(cString: sqlite3_column_text(statement, 7))
                let createdAt = String(cString: sqlite3_column_text(statement, 8))
                let lastLoginAt = String(cString: sqlite3_column_text(statement, 9))
                let updatedAt = String(cString: sqlite3_column_text(statement, 10))
                
                let user = User(
                    id: id,
                    username: username,
                    email: email,
                    passwordHash: passwordHash.isEmpty ? nil : passwordHash,
                    createdAt: Date(),
                    lastLoginAt: nil,
                    gender: gender.isEmpty ? nil : gender,
                    birthDate: nil,
                    bio: bio.isEmpty ? nil : bio,
                    profileImageUrl: profileImageUrl.isEmpty ? nil : profileImageUrl,
                    updatedAt: nil
                )
                
                users.append(user)
            }
        }
        
        sqlite3_finalize(statement)
    }
    
    func clearAllUsers() {
        let deleteSQL = "DELETE FROM users;"
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, deleteSQL, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_DONE {
                print("All users cleared successfully")
                loadUsers()
            } else {
                print("Unable to clear users. Error: \(String(cString: sqlite3_errmsg(db)))")
            }
        }
        
        sqlite3_finalize(statement)
    }
    
    func createTestUsers() {
        let testUsers = [
            User(username: "testuser", email: "test@example.com", passwordHash: "hashed_password_123"),
            User(username: "demo", email: "demo@example.com", passwordHash: "hashed_password_456")
        ]
        
        for user in testUsers {
            saveUser(user)
        }
    }
}