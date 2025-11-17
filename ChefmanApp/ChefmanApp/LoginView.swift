//
//  LoginView.swift
//  ChefmanApp
//
//  Created by 杨雨桐 on 9/14/25.
//

import SwiftUI

// MARK: - Login Page
struct LoginView: View {
    @State private var username = ""
    @State private var password = ""
    @State private var wrgusername = 0
    @State private var wrgpassword = 0
    @State private var showinglogin = false
    @State private var showingsignup = false
    @State private var showPassword = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Professional background
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header section
                    VStack(spacing: 16) {
                        Spacer()
                            .frame(height: 60)
                        
                        // Logo and branding
                        VStack(spacing: 16) {
                            // Chefman Logo
                            ChefmanLogo(size: 100)
                            
                            VStack(spacing: 8) {
                                Text("Chefman Studio")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.primary)
                                
                                Text("Professional Culinary Management")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                            .frame(height: 40)
                    }
                    
                    // Login form section
                    VStack(spacing: 24) {
                        VStack(spacing: 20) {
                            // Username field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Username")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)
                                
                                TextField("Enter your username", text: $username)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .padding(.horizontal, 16)
                                    .frame(height: 50)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(wrgusername > 0 ? Color.red : Color.clear, lineWidth: 1)
                                    )
                            }

                            // Password field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Password")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)
                                
                                HStack {
                                    if showPassword {
                                        TextField("Enter your password", text: $password)
                                            .textInputAutocapitalization(.never)
                                            .autocorrectionDisabled()
                                    } else {
                                        SecureField("Enter your password", text: $password)
                                            .textInputAutocapitalization(.never)
                                            .autocorrectionDisabled()
                                    }

                                    Button(action: {
                                        showPassword.toggle()
                                    }) {
                                        Image(systemName: showPassword ? "eye.slash" : "eye")
                                            .foregroundColor(.secondary)
                                            .font(.system(size: 16))
                                    }
                                    .padding(.trailing, 8)
                                }
                                .padding(.horizontal, 16)
                                .frame(height: 50)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(wrgpassword > 0 ? Color.red : Color.clear, lineWidth: 1)
                                )
                            }
                        }
                        
                        // Error messages
                        if (username == "") || (password == "") {
                            Text("Please enter your username and password")
                                .font(.system(size: 14))
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        else if (wrgusername == 2) || (wrgpassword == 2) {
                            Text("Invalid username or password")
                                .font(.system(size: 14))
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        // Login button
                        Button(action: {
                            authenticateUser(username: username, password: password)
                        }) {
                            HStack {
                                Text("Sign In")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 24)
                            .frame(height: 50)
                            .background(Color.green)
                            .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Forgot password
                        Button("Forgot Password?") {
                            // Handle forgot password
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.green)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        
                        Spacer()
                            .frame(height: 20)
                        
                        // Sign up section
                        HStack {
                            Text("Don't have an account?")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)

                            Button("Create Account") {
                                showingsignup = true
                            }
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.green)
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 40)
                }
            }
            .navigationDestination(isPresented: $showinglogin) {
                RootView()
            }
            .navigationDestination(isPresented: $showingsignup) {
                SignUpView()
            }

        }
    }

    private func authenticateUser(username: String, password: String) {
        // Reset error states
        wrgusername = 0
        wrgpassword = 0
        
        // Check if username and password are empty
        if username.isEmpty || password.isEmpty {
            return
        }
        
        // Use FastAPI for authentication
        Task {
            do {
                print("🔍 Attempting login for user: \(username)")
                let authResponse = try await APIClient.shared.login(username: username, password: password)
                print("✅ User login successful!")
                print("✅ Username: \(authResponse.user.username)")
                print("✅ Email: \(authResponse.user.email)")
                print("✅ User ID: \(authResponse.user.id ?? -1)")
                
                await MainActor.run {
                    // 登录成功后自动跳转到主应用
                    showinglogin = true
                    print("🔄 Navigating to main app after successful login")
                }
            } catch {
                print("❌ Login failed: \(error)")
                print("❌ Error type: \(type(of: error))")
                print("❌ Error description: \(error.localizedDescription)")
                
                // More specific error handling
                if let decodingError = error as? DecodingError {
                    print("❌ Decoding error details: \(decodingError)")
                }
                
                await MainActor.run {
                    // For now, show generic error
                    wrgpassword = 2
                }
            }
        }
    }
}

// MARK: - Preview for Testing
#Preview {
    LoginView()
}
