//
//  DetailedSignUpView.swift
//  ChefmanApp
//
//  Created by 杨雨桐 on 9/14/25.
//

import SwiftUI

// MARK: - Detailed Sign Up Page
struct DetailedSignUpView: View {
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var gender = "Not specified"
    @State private var birthDate = Date()
    @State private var bio = ""
    @State private var address = ""
    @State private var city = ""
    @State private var country = ""
    @State private var postalCode = ""
    @State private var showDatePicker = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isCreatingAccount = false
    @State private var showSuccessView = false
    
    // Validation states
    @State private var firstNameError = ""
    @State private var lastNameError = ""
    @State private var bioError = ""
    @State private var addressError = ""
    @State private var cityError = ""
    @State private var countryError = ""
    @State private var postalCodeError = ""
    
    // Field-level error states for API errors
    @State private var usernameError = ""
    @State private var emailError = ""
    @State private var phoneNumberError = ""
    @State private var passwordError = ""
    
    // Basic account info passed from previous screen
    let username: String
    let email: String
    let phoneNumber: String
    let password: String
    
    let genderOptions = ["Not specified", "Male", "Female", "Other"]
    
    // Date formatter for display
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    // MARK: - Validation Functions
    private func validateFirstName() {
        if !firstName.isEmpty && firstName.count < 2 {
            firstNameError = "First name must be at least 2 characters"
        } else if !firstName.isEmpty && !firstName.allSatisfy({ $0.isLetter || $0.isWhitespace }) {
            firstNameError = "First name can only contain letters and spaces"
        } else {
            firstNameError = ""
        }
    }
    
    private func validateLastName() {
        if !lastName.isEmpty && lastName.count < 2 {
            lastNameError = "Last name must be at least 2 characters"
        } else if !lastName.isEmpty && !lastName.allSatisfy({ $0.isLetter || $0.isWhitespace }) {
            lastNameError = "Last name can only contain letters and spaces"
        } else {
            lastNameError = ""
        }
    }
    
    private func validateBio() {
        if !bio.isEmpty && bio.count > 500 {
            bioError = "Bio must be less than 500 characters"
        } else {
            bioError = ""
        }
    }
    
    private func validateAddress() {
        if !address.isEmpty && address.count < 5 {
            addressError = "Address must be at least 5 characters"
        } else {
            addressError = ""
        }
    }
    
    private func validateCity() {
        if !city.isEmpty && city.count < 2 {
            cityError = "City must be at least 2 characters"
        } else if !city.isEmpty && !city.allSatisfy({ $0.isLetter || $0.isWhitespace || $0 == "-" || $0 == "'" }) {
            cityError = "City can only contain letters, spaces, hyphens, and apostrophes"
        } else {
            cityError = ""
        }
    }
    
    private func validateCountry() {
        if !country.isEmpty && country.count < 2 {
            countryError = "Country must be at least 2 characters"
        } else if !country.isEmpty && !country.allSatisfy({ $0.isLetter || $0.isWhitespace || $0 == "-" || $0 == "'" }) {
            countryError = "Country can only contain letters, spaces, hyphens, and apostrophes"
        } else {
            countryError = ""
        }
    }
    
    private func validatePostalCode() {
        if !postalCode.isEmpty {
            let postalCodePattern = "^[A-Za-z0-9\\s-]{3,10}$"
            let regex = try? NSRegularExpression(pattern: postalCodePattern)
            let range = NSRange(location: 0, length: postalCode.utf16.count)
            if regex?.firstMatch(in: postalCode, options: [], range: range) == nil {
                postalCodeError = "Postal code format is invalid"
            } else {
                postalCodeError = ""
            }
        } else {
            postalCodeError = ""
        }
    }
    
    var body: some View {
        NavigationView {
            if showSuccessView {
                SuccessView()
            } else {
                ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 16) {
                        ChefmanLogo(size: 60)
                        
                        VStack(spacing: 8) {
                            Text("Complete Your Profile")
                                .font(.title)
                                .bold()
                                .multilineTextAlignment(.center)
                            
                            Text("Tell us more about yourself (optional)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.top, 20)
                    
                    // Display field-level errors from API
                    VStack(alignment: .leading, spacing: 8) {
                        if !usernameError.isEmpty {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                Text(usernameError)
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                            .padding(.horizontal)
                        }
                        
                        if !emailError.isEmpty {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                Text(emailError)
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                            .padding(.horizontal)
                        }
                        
                        if !phoneNumberError.isEmpty {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                Text(phoneNumberError)
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                            .padding(.horizontal)
                        }
                        
                        if !passwordError.isEmpty {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                Text(passwordError)
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Personal Information Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Personal Information")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                TextField("First Name", text: $firstName)
                                    .textInputAutocapitalization(.words)
                                    .padding()
                                    .background(firstNameError.isEmpty ? Color.black.opacity(0.05) : Color.red.opacity(0.1))
                                    .cornerRadius(8)
                                    .onChange(of: firstName) { _ in
                                        validateFirstName()
                                    }
                                    .onTapGesture {
                                        firstNameError = ""
                                    }
                                
                                if !firstNameError.isEmpty {
                                    Text(firstNameError)
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                TextField("Last Name", text: $lastName)
                                    .textInputAutocapitalization(.words)
                                    .padding()
                                    .background(lastNameError.isEmpty ? Color.black.opacity(0.05) : Color.red.opacity(0.1))
                                    .cornerRadius(8)
                                    .onChange(of: lastName) { _ in
                                        validateLastName()
                                    }
                                    .onTapGesture {
                                        lastNameError = ""
                                    }
                                
                                if !lastNameError.isEmpty {
                                    Text(lastNameError)
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                            }
                        }
                        
                        // Gender Picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Gender")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Picker("Gender", selection: $gender) {
                                ForEach(genderOptions, id: \.self) { option in
                                    Text(option).tag(option)
                                }
                            }
                            .pickerStyle(WheelPickerStyle())
                            .frame(height: 120)
                            .clipped()
                        }
                        
                        // Birth Date
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Birth Date")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Button(action: {
                                showDatePicker.toggle()
                            }) {
                                HStack {
                                    Text(showDatePicker ? "Hide Date Picker" : (birthDate == Date() ? "Select Birth Date" : "Selected: \(birthDate, formatter: dateFormatter)"))
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: showDatePicker ? "chevron.up" : "chevron.down")
                                        .foregroundColor(.gray)
                                }
                                .padding()
                                .background(Color.black.opacity(0.05))
                                .cornerRadius(8)
                            }
                            
                            if showDatePicker {
                                VStack(spacing: 12) {
                                    DatePicker("", selection: $birthDate, displayedComponents: .date)
                                        .datePickerStyle(WheelDatePickerStyle())
                                        .frame(height: 120)
                                        .clipped()
                                    
                                    HStack(spacing: 12) {
                                        Button("Cancel") {
                                            showDatePicker = false
                                        }
                                        .foregroundColor(.gray)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.gray.opacity(0.1))
                                        .cornerRadius(8)
                                        
                                        Button("Select") {
                                            showDatePicker = false
                                        }
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.green)
                                        .cornerRadius(8)
                                    }
                                }
                                .padding()
                                .background(Color.black.opacity(0.05))
                                .cornerRadius(8)
                            }
                        }
                        
                        // Bio
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Bio")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                TextField("Tell us about yourself...", text: $bio, axis: .vertical)
                                    .lineLimit(3...6)
                                    .padding()
                                    .background(bioError.isEmpty ? Color.black.opacity(0.05) : Color.red.opacity(0.1))
                                    .cornerRadius(8)
                                    .onChange(of: bio) { _ in
                                        validateBio()
                                    }
                                    .onTapGesture {
                                        bioError = ""
                                    }
                                
                                if !bioError.isEmpty {
                                    Text(bioError)
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Address Information Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Address Information")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            TextField("Address", text: $address)
                                .textInputAutocapitalization(.words)
                                .padding()
                                .background(addressError.isEmpty ? Color.black.opacity(0.05) : Color.red.opacity(0.1))
                                .cornerRadius(8)
                                .onChange(of: address) { _ in
                                    validateAddress()
                                }
                                .onTapGesture {
                                    addressError = ""
                                }
                            
                            if !addressError.isEmpty {
                                Text(addressError)
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                TextField("City", text: $city)
                                    .textInputAutocapitalization(.words)
                                    .padding()
                                    .background(cityError.isEmpty ? Color.black.opacity(0.05) : Color.red.opacity(0.1))
                                    .cornerRadius(8)
                                    .onChange(of: city) { _ in
                                        validateCity()
                                    }
                                    .onTapGesture {
                                        cityError = ""
                                    }
                                
                                if !cityError.isEmpty {
                                    Text(cityError)
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                TextField("Country", text: $country)
                                    .textInputAutocapitalization(.words)
                                    .padding()
                                    .background(countryError.isEmpty ? Color.black.opacity(0.05) : Color.red.opacity(0.1))
                                    .cornerRadius(8)
                                    .onChange(of: country) { _ in
                                        validateCountry()
                                    }
                                    .onTapGesture {
                                        countryError = ""
                                    }
                                
                                if !countryError.isEmpty {
                                    Text(countryError)
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            TextField("Postal Code", text: $postalCode)
                                .textInputAutocapitalization(.never)
                                .padding()
                                .background(postalCodeError.isEmpty ? Color.black.opacity(0.05) : Color.red.opacity(0.1))
                                .cornerRadius(8)
                                .onChange(of: postalCode) { _ in
                                    validatePostalCode()
                                }
                                .onTapGesture {
                                    postalCodeError = ""
                                }
                            
                            if !postalCodeError.isEmpty {
                                Text(postalCodeError)
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Error Message
                    if showError {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.top, 4)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        Button(action: createAccount) {
                            HStack {
                                if isCreatingAccount {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                }
                                Text(isCreatingAccount ? "Creating Account..." : "Create Account")
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(10)
                        }
                        .disabled(isCreatingAccount)
                        
                        Button(action: skipAndCreateAccount) {
                            Text("Skip & Create Account")
                                .foregroundColor(.blue)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(10)
                        }
                        .disabled(isCreatingAccount)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
                }
                .navigationTitle("Complete Profile")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
    
    private func createAccount() {
        // Validate required fields first
        if username.isEmpty || email.isEmpty || password.isEmpty {
            showError = true
            errorMessage = "Please fill in all required fields (Username, Email, Password)"
            return
        }
        
        // Check for validation errors
        if !firstNameError.isEmpty || !lastNameError.isEmpty || !bioError.isEmpty || !addressError.isEmpty || !cityError.isEmpty || !countryError.isEmpty || !postalCodeError.isEmpty {
            showError = true
            errorMessage = "Please fix the validation errors above"
            return
        }
        
        isCreatingAccount = true
        showError = false
        
        Task {
            do {
                var user = try await APIClient.shared.register(
                    username: username,
                    email: email,
                    password: password,
                    phone_number: phoneNumber.isEmpty ? nil : phoneNumber,
                    first_name: firstName.isEmpty ? nil : firstName,
                    last_name: lastName.isEmpty ? nil : lastName,
                    gender: gender,
                    birth_date: {
                        let formatter = DateFormatter()
                        formatter.dateFormat = "yyyy-MM-dd"
                        return formatter.string(from: birthDate)
                    }(),
                    bio: bio.isEmpty ? nil : bio,
                    address: address.isEmpty ? nil : address,
                    city: city.isEmpty ? nil : city,
                    country: country.isEmpty ? nil : country,
                    postal_code: postalCode.isEmpty ? nil : postalCode
                )
                
                // 保存密码用于显示（仅客户端本地）
                user = User(
                    id: user.id,
                    username: user.username,
                    email: user.email,
                    password: password,  // 保存密码用于显示
                    passwordHash: user.passwordHash,
                    createdAt: user.createdAt,
                    lastLoginAt: user.lastLoginAt,
                    gender: user.gender,
                    birthDate: user.birthDate,
                    bio: user.bio,
                    profileImageUrl: user.profileImageUrl,
                    updatedAt: user.updatedAt
                )
                
                // 更新 APIClient 中的当前用户
                APIClient.shared.currentUser = user
                
                print("✅ Account created successfully: \(user.username)")
                
                await MainActor.run {
                    isCreatingAccount = false
                    showSuccessView = true
                }
            } catch {
                print("❌ Account creation failed: \(error.localizedDescription)")
                await MainActor.run {
                    isCreatingAccount = false
                    
                    // Parse error message and set field-specific errors
                    let errorMessage = error.localizedDescription
                    showError = true
                    self.errorMessage = errorMessage
                    
                    // Clear all field errors first
                    usernameError = ""
                    emailError = ""
                    phoneNumberError = ""
                    passwordError = ""
                    
                    // Set field-specific errors based on error message
                    if errorMessage.lowercased().contains("username") {
                        usernameError = errorMessage
                    } else if errorMessage.lowercased().contains("email") {
                        emailError = errorMessage
                    } else if errorMessage.lowercased().contains("phone") {
                        phoneNumberError = errorMessage
                    } else if errorMessage.lowercased().contains("password") {
                        passwordError = errorMessage
                    }
                }
            }
        }
    }
    
    private func skipAndCreateAccount() {
        // Validate required fields first
        if username.isEmpty || email.isEmpty || password.isEmpty {
            showError = true
            errorMessage = "Please fill in all required fields (Username, Email, Password)"
            return
        }
        
        isCreatingAccount = true
        showError = false
        
        Task {
            do {
                var user = try await APIClient.shared.register(
                    username: username,
                    email: email,
                    password: password,
                    phone_number: phoneNumber.isEmpty ? nil : phoneNumber
                )
                
                // 保存密码用于显示（仅客户端本地）
                user = User(
                    id: user.id,
                    username: user.username,
                    email: user.email,
                    password: password,  // 保存密码用于显示
                    passwordHash: user.passwordHash,
                    createdAt: user.createdAt,
                    lastLoginAt: user.lastLoginAt,
                    gender: user.gender,
                    birthDate: user.birthDate,
                    bio: user.bio,
                    profileImageUrl: user.profileImageUrl,
                    updatedAt: user.updatedAt
                )
                
                // 更新 APIClient 中的当前用户
                APIClient.shared.currentUser = user
                
                print("✅ Account created successfully: \(user.username)")
                
                await MainActor.run {
                    isCreatingAccount = false
                    showSuccessView = true
                }
            } catch {
                print("❌ Account creation failed: \(error.localizedDescription)")
                await MainActor.run {
                    isCreatingAccount = false
                    
                    // Parse error message and set field-specific errors
                    let errorMessage = error.localizedDescription
                    showError = true
                    self.errorMessage = errorMessage
                    
                    // Clear all field errors first
                    usernameError = ""
                    emailError = ""
                    phoneNumberError = ""
                    passwordError = ""
                    
                    // Set field-specific errors based on error message
                    if errorMessage.lowercased().contains("username") {
                        usernameError = errorMessage
                    } else if errorMessage.lowercased().contains("email") {
                        emailError = errorMessage
                    } else if errorMessage.lowercased().contains("phone") {
                        phoneNumberError = errorMessage
                    } else if errorMessage.lowercased().contains("password") {
                        passwordError = errorMessage
                    }
                }
            }
        }
    }
}

// MARK: - Date Formatter Extension
extension DateFormatter {
    static let iso8601: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

// MARK: - Success View
struct SuccessView: View {
    @State private var showLoginView = false
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Success Icon
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            VStack(spacing: 16) {
                Text("Congratulations!")
                    .font(.largeTitle)
                    .bold()
                    .foregroundColor(.primary)
                
                Text("Your account has been created successfully!")
                    .font(.title2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Text("Welcome to Chefman Studio!")
                    .font(.title)
                    .bold()
                    .foregroundColor(.green)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            // Continue Button
            Button(action: {
                showLoginView = true
            }) {
                Text("Continue to Login")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 250, height: 50)
                    .background(Color.green)
                    .cornerRadius(25)
            }
            .padding(.bottom, 50)
        }
        .padding()
        .navigationDestination(isPresented: $showLoginView) {
            LoginView()
        }
    }
}

#Preview {
    DetailedSignUpView(
        username: "testuser",
        email: "test@example.com",
        phoneNumber: "+1234567890",
        password: "password123"
    )
}
