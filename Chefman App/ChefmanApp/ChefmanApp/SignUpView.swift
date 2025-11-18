//
//  SignUpView.swift
//  ChefmanApp
//
//  Created by 杨雨桐 on 9/14/25.
//

import SwiftUI

// MARK: - Sign Up Page
struct SignUpView: View {
    @State private var newUsername = ""
    @State private var newEmail = ""
    @State private var newPhonenumber = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var goToUserInfo = false // go to user profile information
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    
    // Validation states
    @State private var usernameError = ""
    @State private var emailError = ""
    @State private var phoneError = ""
    @State private var passwordError = ""
    @State private var confirmPasswordError = ""
    @State private var isCheckingUsername = false
    
    // MARK: - Validation Functions
    private func validateUsername() {
        if newUsername.isEmpty {
            usernameError = ""
            return
        }
        
        if newUsername.count < 3 {
            usernameError = "Username must be at least 3 characters"
            return
        }
        
        if !newUsername.allSatisfy({ $0.isLetter || $0.isNumber || $0 == "_" || $0 == "-" }) {
            usernameError = "Username can only contain letters, numbers, underscores, and hyphens"
            return
        }
        
        // Check for username availability
        isCheckingUsername = true
        Task {
            do {
                let isAvailable = try await APIClient.shared.checkUsernameAvailability(username: newUsername)
                
                await MainActor.run {
                    if isAvailable {
                        usernameError = ""
                    } else {
                        usernameError = "Username is already taken"
                    }
                    isCheckingUsername = false
                }
            } catch {
                await MainActor.run {
                    usernameError = "Error checking username availability"
                    isCheckingUsername = false
                }
            }
        }
    }
    
    private func validateEmail() {
        if newEmail.isEmpty {
            emailError = ""
            return
        }
        
        let emailRegex = "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        
        if !emailPredicate.evaluate(with: newEmail) {
            emailError = "Please enter a valid email address"
        } else {
            emailError = ""
        }
    }
    
    private func validatePhone() {
        if newPhonenumber.isEmpty {
            phoneError = ""
            return
        }
        
        let phoneRegex = "^[+]?[0-9\\s\\-\\(\\)]{10,15}$"
        let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        
        if !phonePredicate.evaluate(with: newPhonenumber) {
            phoneError = "Please enter a valid phone number"
        } else {
            phoneError = ""
        }
    }
    
    private func validatePassword() {
        if newPassword.isEmpty {
            passwordError = ""
            return
        }
        
        if newPassword.count < 6 {
            passwordError = "Password must be at least 6 characters"
        } else if newPassword.count > 50 {
            passwordError = "Password must be less than 50 characters"
        } else {
            passwordError = ""
        }
    }
    
    private func validateConfirmPassword() {
        if confirmPassword.isEmpty {
            confirmPasswordError = ""
            return
        }
        
        if newPassword != confirmPassword {
            confirmPasswordError = "Passwords do not match"
        } else {
            confirmPasswordError = ""
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            // Logo and branding
            VStack(spacing: 16) {
                ChefmanLogo(size: 80)
                
                VStack(spacing: 8) {
                    Text("Welcome to Chefman Studio!")
                        .font(.largeTitle)
                        .bold()
                        .multilineTextAlignment(.center)
                    
                    Text("Create Account")
                        .font(.title2)
                        .foregroundColor(.primary)
                        .bold()
                }
            }
            .padding(.top, 20)

            VStack(alignment: .leading, spacing: 4) {
                TextField("Create Your Username", text: $newUsername)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding()
                    .frame(width: 300, height: 50)
                    .background(usernameError.isEmpty ? Color.black.opacity(0.05) : Color.red.opacity(0.1))
                    .cornerRadius(8)
                    .onChange(of: newUsername) { _ in
                        validateUsername()
                    }
                    .onTapGesture {
                        usernameError = ""
                    }
                
                if !usernameError.isEmpty {
                    Text(usernameError)
                        .font(.caption)
                        .foregroundColor(.red)
                }
                
                if isCheckingUsername {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Checking username availability...")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                TextField("Enter Your Email", text: $newEmail)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .padding()
                    .frame(width: 300, height: 50)
                    .background(emailError.isEmpty ? Color.black.opacity(0.05) : Color.red.opacity(0.1))
                    .cornerRadius(8)
                    .onChange(of: newEmail) { _ in
                        validateEmail()
                    }
                    .onTapGesture {
                        emailError = ""
                    }
                
                if !emailError.isEmpty {
                    Text(emailError)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                TextField("Enter Your Phone Number", text: $newPhonenumber)
                    .padding()
                    .frame(width: 300, height: 50)
                    .background(phoneError.isEmpty ? Color.black.opacity(0.05) : Color.red.opacity(0.1))
                    .cornerRadius(8)
                    .onChange(of: newPhonenumber) { _ in
                        validatePhone()
                    }
                    .onTapGesture {
                        phoneError = ""
                    }
                
                if !phoneError.isEmpty {
                    Text(phoneError)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }

            // Password field with show/hide toggle
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    if showPassword {
                        TextField("New Password", text: $newPassword)
                            .padding()
                            .frame(width: 250, height: 50)
                            .background(passwordError.isEmpty ? Color.black.opacity(0.05) : Color.red.opacity(0.1))
                            .cornerRadius(8)
                    } else {
                        SecureField("New Password", text: $newPassword)
                            .padding()
                            .frame(width: 250, height: 50)
                            .background(passwordError.isEmpty ? Color.black.opacity(0.05) : Color.red.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    Button(action: {
                        showPassword.toggle()
                    }) {
                        Image(systemName: showPassword ? "eye.slash" : "eye")
                            .foregroundColor(.gray)
                            .frame(width: 50, height: 50)
                    }
                }
                .frame(width: 300, height: 50)
                .onChange(of: newPassword) { _ in
                    validatePassword()
                    validateConfirmPassword() // Also validate confirm password when main password changes
                }
                .onTapGesture {
                    passwordError = ""
                }
                
                if !passwordError.isEmpty {
                    Text(passwordError)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            // Confirm password field with show/hide toggle
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    if showConfirmPassword {
                        TextField("Confirm Password", text: $confirmPassword)
                            .padding()
                            .frame(width: 250, height: 50)
                            .background(confirmPasswordError.isEmpty ? Color.black.opacity(0.05) : Color.red.opacity(0.1))
                            .cornerRadius(8)
                    } else {
                        SecureField("Confirm Password", text: $confirmPassword)
                            .padding()
                            .frame(width: 250, height: 50)
                            .background(confirmPasswordError.isEmpty ? Color.black.opacity(0.05) : Color.red.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    Button(action: {
                        showConfirmPassword.toggle()
                    }) {
                        Image(systemName: showConfirmPassword ? "eye.slash" : "eye")
                            .foregroundColor(.gray)
                            .frame(width: 50, height: 50)
                    }
                }
                .frame(width: 300, height: 50)
                .onChange(of: confirmPassword) { _ in
                    validateConfirmPassword()
                }
                .onTapGesture {
                    confirmPasswordError = ""
                }
                
                if !confirmPasswordError.isEmpty {
                    Text(confirmPasswordError)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            if showError {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.top, 4)
                    .multilineTextAlignment(.center)
            }

            Button("Next Step") {
                // Validate all required fields are filled
                if newUsername.isEmpty || newEmail.isEmpty || newPhonenumber.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty {
                    showError = true
                    errorMessage = "Please fill in all required fields"
                    return
                }
                
                // Check if there are any validation errors
                if !usernameError.isEmpty || !emailError.isEmpty || !phoneError.isEmpty || !passwordError.isEmpty || !confirmPasswordError.isEmpty {
                    showError = true
                    errorMessage = "Please fix the validation errors above"
                    return
                }
                
                // All validations passed, navigate to detailed sign up
                showError = false
                goToUserInfo = true
            }
            .foregroundColor(.white)
            .frame(width: 300, height: 50)
            .background(Color.green)
            .cornerRadius(25.0)
            .padding(.top, 10)
            }
            .navigationDestination(isPresented: $goToUserInfo) {
                DetailedSignUpView(
                    username: newUsername,
                    email: newEmail,
                    phoneNumber: newPhonenumber,
                    password: newPassword
                )
            }
    }
    
}

// MARK: - Preview for Testing
#Preview {
    SignUpView()
}
