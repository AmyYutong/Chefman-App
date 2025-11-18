//
//  UserInfoView.swift
//  ChefmanApp
//
//  Created by 杨雨桐 on 9/14/25.
//

import SwiftUI

// MARK: - User Info Page
struct UserInfoView: View {
    let username: String
    @State private var age = ""
    @State private var gender = ""
    @State private var goToMain = false   // 👉 Control navigation to main page

    var body: some View {
        VStack {
            Text("Welcome, \(username)!")
                .font(.title2)
                .bold()
                .padding()

            TextField("Age", text: $age)
                .padding()
                .frame(width: 300, height: 50)
                .background(Color.black.opacity(0.05))
                .keyboardType(.numberPad)

            TextField("Gender", text: $gender)
                .padding()
                .frame(width: 300, height: 50)
                .background(Color.black.opacity(0.05))

            Button("Save and Continue") {
                print("Saved age: \(age), gender: \(gender)")
                goToMain = true
            }
            .foregroundColor(.white)
            .frame(width: 300, height: 50)
            .background(Color.green)
            .cornerRadius(25.0)
            .padding(.top, 10)

            // 👉 Skip button
            Button("Skip") {
                goToMain = true
            }
            .font(.footnote)
            .foregroundColor(.blue)
            .padding(.top, 8)
        }
        .navigationDestination(isPresented: $goToMain) {
            RootView()   // Navigate to main page
        }
    }
}

// MARK: - Preview for Testing
#Preview {
    UserInfoView(username: "testuser")
}
