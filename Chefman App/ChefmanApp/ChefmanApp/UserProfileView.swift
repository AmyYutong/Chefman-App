//
//  UserProfileView.swift
//  ChefmanApp
//
//  Created for viewing other users' profiles
//

import SwiftUI

// MARK: - User Profile View (for viewing other users)
struct UserProfileView: View {
    let userId: Int
    let username: String?
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var library: Library
    @StateObject private var apiClient = APIClient.shared
    
    @State private var userProfile: UserProfile?
    @State private var userRecipes: [Recipe] = []
    @State private var isLoading = true
    @State private var isFollowing = false
    @State private var isFollowingLoading = false
    @State private var selectedTab = 0
    @State private var selectedRecipe: Recipe?
    
    private let columns = [GridItem(.flexible(), spacing: 10),
                           GridItem(.flexible(), spacing: 10)]
    
    // Explicit public initializer
    init(userId: Int, username: String?) {
        self.userId = userId
        self.username = username
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    if isLoading {
                        ProgressView()
                            .padding(.top, 100)
                    } else if let profile = userProfile {
                        // Profile Header
                        profileHeader(profile: profile)
                        
                        // Statistics
                        statisticsSection(profile: profile)
                        
                        // Tab Selector
                        tabSelector
                        
                        // Content
                        VStack(spacing: 16) {
                            switch selectedTab {
                            case 0:
                                recipesGridView
                            case 1:
                                favoritesView
                            default:
                                recipesGridView
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 24)
                    } else {
                        Text("User not found")
                            .foregroundColor(.secondary)
                            .padding(.top, 100)
                    }
                }
            }
            .navigationTitle(userProfile?.username ?? username ?? "Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadUserProfile()
            }
            .sheet(item: $selectedRecipe) { recipe in
                RecipeDetailView(recipe: recipe)
                    .environmentObject(library)
            }
        }
    }
    
    // MARK: - Profile Header
    private func profileHeader(profile: UserProfile) -> some View {
        VStack(spacing: 16) {
            // Avatar (with custom image if available)
            if let profileImageUrl = profile.profileImageUrl, !profileImageUrl.isEmpty {
                AsyncImage(url: URL(string: profileImageUrl)) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: 80, height: 80)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                    case .failure:
                        defaultAvatarView(username: profile.username)
                    @unknown default:
                        defaultAvatarView(username: profile.username)
                    }
                }
            } else {
                defaultAvatarView(username: profile.username)
            }
            
            // Username and Bio
            VStack(spacing: 4) {
                Text(profile.username)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                if let bio = profile.bio, !bio.isEmpty {
                    Text(bio)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
            }
            
            // Follow Button (if not current user)
            if userId != apiClient.currentUser?.id {
                Button(action: {
                    toggleFollow()
                }) {
                    HStack(spacing: 6) {
                        if isFollowingLoading {
                            ProgressView()
                                .scaleEffect(0.7)
                                .foregroundColor(.white)
                        } else {
                            Image(systemName: isFollowing ? "checkmark.circle.fill" : "person.badge.plus")
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                        
                        Text(isFollowing ? "Following" : "Follow")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(isFollowing ? Color.gray : Color.blue)
                    .cornerRadius(20)
                }
                .disabled(isFollowingLoading)
            }
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.05))
    }
    
    // MARK: - Statistics Section
    private func statisticsSection(profile: UserProfile) -> some View {
        HStack(spacing: 20) {
            StatCard(
                title: "Recipes",
                value: "\(profile.recipesCount)",
                icon: "book.fill"
            )
            
            StatCard(
                title: "Followers",
                value: "\(profile.followersCount)",
                icon: "person.2"
            )
            
            StatCard(
                title: "Following",
                value: "\(profile.followingCount)",
                icon: "person.2.fill"
            )
            
            StatCard(
                title: "Likes",
                value: "\(profile.totalLikesReceived)",
                icon: "heart.fill"
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
    }
    
    // MARK: - Tab Selector
    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(0..<2) { index in
                Button(action: {
                    selectedTab = index
                }) {
                    VStack(spacing: 4) {
                        Text(tabTitles[index])
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(selectedTab == index ? .blue : .secondary)
                        
                        Rectangle()
                            .fill(selectedTab == index ? Color.blue : Color.clear)
                            .frame(height: 2)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }
    
    private var tabTitles = ["Recipes", "Favorites"]
    
    // MARK: - Recipes Grid View
    private var recipesGridView: some View {
        VStack(alignment: .leading, spacing: 16) {
            if userRecipes.isEmpty {
                EmptyStateView(
                    title: "No recipes yet",
                    subtitle: "This user hasn't created any recipes yet."
                )
                .padding(.top, 40)
            } else {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(userRecipes) { recipe in
                        RecipeCard(recipe: recipe, onToggleFavorite: {
                            library.toggleFavorite(recipe)
                        }, onTap: {
                            selectedRecipe = recipe
                        })
                        .environmentObject(library)
                    }
                }
            }
        }
    }
    
    // MARK: - Favorites View
    private var favoritesView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Favorites are private")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.top, 40)
        }
    }
    
    // MARK: - Load User Profile
    private func loadUserProfile() {
        isLoading = true
        
        Task {
            do {
                // Load user profile info
                let profile = try await apiClient.getUserProfile(userId: userId)
                
                // Load user's recipes
                let recipes = try await apiClient.getUserRecipes(userId: userId)
                
                // Check follow status
                let followStatus = try await apiClient.getFollowStatus(userId: userId)
                
                await MainActor.run {
                    self.userProfile = profile
                    self.userRecipes = recipes
                    self.isFollowing = followStatus
                    self.isLoading = false
                }
            } catch {
                print("❌ Failed to load user profile: \(error.localizedDescription)")
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
    
    // MARK: - Toggle Follow
    private func toggleFollow() {
        guard userId != apiClient.currentUser?.id else { return }
        
        isFollowingLoading = true
        
        Task {
            do {
                if isFollowing {
                    try await apiClient.unfollowUser(userId: userId)
                    print("✅ Unfollowed user \(userId)")
                } else {
                    try await apiClient.followUser(userId: userId)
                    print("✅ Followed user \(userId)")
                }
                
                // Reload follow status
                let followStatus = try await apiClient.getFollowStatus(userId: userId)
                await MainActor.run {
                    self.isFollowing = followStatus
                    self.isFollowingLoading = false
                    
                    // Reload profile to update stats
                    if let profile = self.userProfile {
                        loadUserProfile()
                    }
                }
            } catch {
                print("❌ Failed to toggle follow: \(error.localizedDescription)")
                await MainActor.run {
                    self.isFollowingLoading = false
                }
            }
        }
    }
    
    // MARK: - Default Avatar View
    private func defaultAvatarView(username: String) -> some View {
        Circle()
            .fill(LinearGradient(
                gradient: Gradient(colors: [Color.blue, Color.purple]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ))
            .frame(width: 80, height: 80)
            .overlay(
                Text(String(username.prefix(1).uppercased()))
                    .font(.title)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            )
    }
}

// Note: UserProfile struct is defined in APIClient.swift

