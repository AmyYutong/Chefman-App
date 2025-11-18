//
//  MainAppViews.swift
//  ChefmanApp
//
//  Created by 杨雨桐 on 9/14/25.
//

import SwiftUI
import PhotosUI

// MARK: - Environment Key for Tab Selection
struct SelectedTabKey: EnvironmentKey {
    static let defaultValue: Binding<Int> = .constant(0)
}

extension EnvironmentValues {
    var selectedTab: Binding<Int> {
        get { self[SelectedTabKey.self] }
        set { self[SelectedTabKey.self] = newValue }
    }
}

// MARK: - Recipe Model (Local version for UI)
struct LocalRecipe: Identifiable, Hashable {
    let id = UUID()
    var title: String
    var imageSystemName: String  // SF Symbols placeholder for examples
    var isFavorite: Bool = false
}

// MARK: - Library Manager (Updated for FastAPI)
final class Library: ObservableObject {
    @Published var recipes: [Recipe] = []
    @Published var favorites: [Recipe] = []
    @Published var todoList: [APIClient.TodoListItem] = []
    @Published var myRecipes: [Recipe] = []
    @Published var isLoading = false
    
    init() {
        loadRecipes()
        loadFavorites()
        loadTodoList()
        loadMyRecipes()
    }
    
    // Load recipes from FastAPI
    func loadRecipes() {
        print("🔄 Library.loadRecipes() called")
        isLoading = true
        Task {
            do {
                print("🔍 Fetching recipes from API...")
                let apiRecipes = try await APIClient.shared.getRecipes()
                print("✅ Successfully fetched \(apiRecipes.count) recipes")
                await MainActor.run {
                    self.recipes = apiRecipes
                    self.isLoading = false
                    print("🔄 UI updated with \(self.recipes.count) recipes")
                }
            } catch {
                print("❌ Failed to load recipes: \(error.localizedDescription)")
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
    
    // Load favorites from FastAPI
    func loadFavorites() {
        Task {
            do {
                let apiFavorites = try await APIClient.shared.getFavorites()
                await MainActor.run {
                    self.favorites = apiFavorites
                }
            } catch {
                print("❌ Failed to load favorites: \(error.localizedDescription)")
            }
        }
    }
    
    // Toggle favorite
    func toggleFavorite(_ recipe: Recipe) {
        Task {
            do {
                if favorites.contains(where: { $0.id == recipe.id }) {
                    try await APIClient.shared.removeFavorite(recipeId: recipe.id!)
                    await MainActor.run {
                        favorites.removeAll { $0.id == recipe.id }
                    }
                } else {
                    let _ = try await APIClient.shared.addFavorite(recipeId: recipe.id!)
                    await MainActor.run {
                        favorites.append(recipe)
                    }
                }
            } catch {
                print("❌ Failed to toggle favorite: \(error.localizedDescription)")
            }
        }
    }
    
    // Check if recipe is favorite
    func isFavorite(_ recipe: Recipe) -> Bool {
        return favorites.contains(where: { $0.id == recipe.id })
    }
    
    // Load todo list
    func loadTodoList() {
        print("🔄 Loading todo list...")
        Task {
            do {
                let apiTodoList = try await APIClient.shared.getTodoList()
                await MainActor.run {
                    self.todoList = apiTodoList
                    print("✅ Loaded \(apiTodoList.count) todo items")
                }
            } catch {
                print("❌ Failed to load todo list: \(error.localizedDescription)")
            }
        }
    }
    
    // Toggle todo completion
    func toggleTodoCompletion(_ item: APIClient.TodoListItem) {
        guard let recipeId = item.recipe.id else { return }
        let newCompleted = !item.completed
        
        // Optimistically update UI
        if let index = todoList.firstIndex(where: { $0.recipe.id == item.recipe.id }) {
            let updatedItem = todoList[index]
            let newItem = APIClient.TodoListItem(
                recipe: updatedItem.recipe,
                completed: newCompleted,
                todoId: updatedItem.todoId
            )
            todoList[index] = newItem
        }
        
        Task {
            do {
                try await APIClient.shared.toggleTodoCompletion(recipeId: recipeId, completed: newCompleted)
                print("✅ Todo completion toggled: \(newCompleted)")
            } catch {
                print("❌ Failed to toggle todo completion: \(error.localizedDescription)")
                // Revert on error
                await MainActor.run {
                    if let index = todoList.firstIndex(where: { $0.recipe.id == item.recipe.id }) {
                        let revertedItem = APIClient.TodoListItem(
                            recipe: item.recipe,
                            completed: item.completed,
                            todoId: item.todoId
                        )
                        todoList[index] = revertedItem
                    }
                }
            }
        }
    }
    
    // Load my recipes
    func loadMyRecipes() {
        print("🔄 Loading my recipes...")
        Task {
            do {
                // Use the new API endpoint to get recipes created by current user
                let myRecipes = try await APIClient.shared.getMyRecipes()
                await MainActor.run {
                    self.myRecipes = myRecipes
                    print("✅ Loaded \(self.myRecipes.count) 'My Recipes' for current user")
                }
            } catch {
                print("❌ Failed to load my recipes: \(error.localizedDescription)")
                await MainActor.run {
                    self.myRecipes = []
                }
            }
        }
    }
    
    // Add to todo list
    func addToTodoList(_ recipe: Recipe) {
        Task {
            do {
                try await APIClient.shared.addToTodoList(recipeId: recipe.id!)
                // Reload todo list to get updated data
                loadTodoList()
                print("✅ Added \(recipe.title) to todo list")
            } catch {
                print("❌ Failed to add to todo list: \(error.localizedDescription)")
            }
        }
    }
    
    // Remove from todo list
    func removeFromTodoList(_ recipe: Recipe) {
        Task {
            do {
                try await APIClient.shared.removeFromTodoList(recipeId: recipe.id!)
                // Reload todo list to get updated data
                loadTodoList()
                print("❌ Removed \(recipe.title) from todo list")
            } catch {
                print("❌ Failed to remove from todo list: \(error.localizedDescription)")
            }
        }
    }
    
    // Check if recipe is in todo list
    func isInTodoList(_ recipe: Recipe) -> Bool {
        return todoList.contains(where: { $0.recipe.id == recipe.id })
    }
    
    // Clear all data (for testing)
    func clearAll() {
        recipes.removeAll()
        favorites.removeAll()
        todoList.removeAll()
        myRecipes.removeAll()
    }
}

// MARK: - Root View
struct RootView: View {
    @StateObject private var library = Library()
    @State private var showUploadRecipe = false
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                HomeView()
                    .environmentObject(library)
                    .environment(\.selectedTab, Binding(
                        get: { selectedTab },
                        set: { selectedTab = $0 }
                    ))
                    .tabItem { 
                        Label("Home", systemImage: "house.fill") 
                    }
                    .tag(0)
                
                MeView()
                    .environmentObject(library)
                    .environment(\.selectedTab, Binding(
                        get: { selectedTab },
                        set: { selectedTab = $0 }
                    ))
                    .tabItem { 
                        Label("Me", systemImage: "person.circle") 
                    }
                    .tag(1)
            }
            
            // Create Recipe Button (Between Home and Me in tab bar)
            HStack {
                Spacer()
                
                Button(action: {
                    showUploadRecipe = true
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.green)
                        )
                        .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 3)
                }
                
                Spacer()
            }
            .padding(.bottom, -5) // Move even closer to tab bar
        }
        .onAppear {
            // 登录成功后自动刷新数据
            print("🔄 RootView appeared")
        }
        .sheet(isPresented: $showUploadRecipe) {
            UploadRecipeView()
        }
    }
}

// MARK: - Home View (Main Home Page)
struct HomeView: View {
    @EnvironmentObject var library: Library
    @Environment(\.selectedTab) private var selectedTab
    @State private var searchText = ""
    @State private var isSearching = false
    @State private var randomRecipes: [Recipe] = []
    @State private var selectedRecipe: Recipe?
    @State private var isViewVisible = false
    @State private var lastRecipesCount = 0
    
    private let columns = [GridItem(.flexible(), spacing: 10),
                           GridItem(.flexible(), spacing: 10)]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Search Bar
                    searchBar
                    
                    // Header with refresh button
                    headerView
                    
                    // Content based on search
                    if isSearching {
                        searchResultsView
                    } else {
                        randomRecipesView
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
            .navigationTitle("Discover Recipes")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                isViewVisible = true
                lastRecipesCount = library.recipes.count
                loadRandomRecipes()
            }
            .onDisappear {
                isViewVisible = false
            }
            .onChange(of: library.recipes) { oldValue, newValue in
                // Only reload if view is visible, tab is selected (Home tab = 0), and recipes actually changed
                let isHomeTabSelected = selectedTab.wrappedValue == 0
                guard isViewVisible && isHomeTabSelected else { 
                    print("⏸️ HomeView not visible or not selected tab, skipping random recipes reload (visible: \(isViewVisible), tab: \(selectedTab.wrappedValue))")
                    return 
                }
                
                // Check if recipes actually changed (count or IDs)
                let oldIds = Set(oldValue.compactMap { $0.id })
                let newIds = Set(newValue.compactMap { $0.id })
                let recipesChanged = newValue.count != lastRecipesCount || oldIds != newIds
                
                guard recipesChanged else { 
                    print("⏸️ Recipes unchanged, skipping random recipes reload")
                    return 
                }
                
                print("🔄 library.recipes changed, reloading random recipes (count: \(oldValue.count) -> \(newValue.count))")
                lastRecipesCount = newValue.count
                loadRandomRecipes()
            }
            .sheet(item: $selectedRecipe) { recipe in
                RecipeDetailView(recipe: recipe)
                    .environmentObject(library)
            }
        }
    }
    
    // MARK: - Search Bar
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search recipes...", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
                .onChange(of: searchText) { oldValue, newValue in
                    isSearching = !newValue.isEmpty
                }
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                    isSearching = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            Text("Discover Recipes")
                .font(.headline)
                .foregroundColor(.primary)
            
            Spacer()
            
            Button(action: {
                loadRandomRecipes()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.clockwise")
                    Text("Refresh")
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
        }
    }
    
    // MARK: - Search Results View
    private var searchResultsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Search Results")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            let filteredRecipes = library.recipes.filter { recipe in
                recipe.title.localizedCaseInsensitiveContains(searchText) ||
                recipe.description?.localizedCaseInsensitiveContains(searchText) == true ||
                recipe.recipeType.localizedCaseInsensitiveContains(searchText) ||
                recipe.cuisineType.localizedCaseInsensitiveContains(searchText)
            }
            
            if filteredRecipes.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    
                    Text("No recipes found")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Try searching with different keywords")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 40)
            } else {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(filteredRecipes) { recipe in
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
    
    // MARK: - Random Recipes View
    private var randomRecipesView: some View {
        VStack(alignment: .leading, spacing: 16) {
            if randomRecipes.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "fork.knife")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    
                    Text("No recipes available")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Create your first recipe to get started")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 40)
            } else {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(randomRecipes) { recipe in
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
    
    // MARK: - Helper Methods
    private func loadRandomRecipes() {
        print("🔄 loadRandomRecipes() called with \(library.recipes.count) recipes")
        // Get a random subset of recipes (up to 6 recipes)
        let allRecipes = library.recipes
        if allRecipes.count <= 6 {
            randomRecipes = allRecipes.shuffled()
        } else {
            randomRecipes = Array(allRecipes.shuffled().prefix(6))
        }
        print("🔄 Random recipes updated: \(randomRecipes.count) recipes")
    }
}

// MARK: - Me View (Personal Page with Sub-tabs)
struct MeView: View {
    @EnvironmentObject var library: Library
    @State private var showUploadRecipe = false
    @State private var showProfileMenu = false
    @State private var selectedTab = 0
    @State private var selectedRecipe: Recipe?
    @State private var showAIAssistant = false
    
    // Avatar editing
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedAvatarImage: UIImage?
    @State private var showImagePicker = false
    @State private var showCamera = false
    @State private var showPhotoActionSheet = false
    @State private var isUploadingAvatar = false
    
    private let columns = [GridItem(.flexible(), spacing: 10),
                           GridItem(.flexible(), spacing: 10)]
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                VStack(spacing: 0) {
                    // Header with Profile Menu
                    headerView
                    
                    // Tab Selector
                    tabSelector
                    
                    // Content based on selected tab
                    ScrollView {
                        VStack(spacing: 16) {
                            switch selectedTab {
                            case 0:
                                myRecipesView
                            case 1:
                                myFavoritesView
                            case 2:
                                myTodoListView
                            default:
                                myRecipesView
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 24)
                    }
                }
                
                aiAssistantFloatingButton
                    .padding(.trailing, 20)
                    .padding(.bottom, 32)
            }
            .navigationTitle("Me")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showProfileMenu = true
                    }) {
                        if let currentUser = APIClient.shared.currentUser {
                            if let profileImageUrl = currentUser.profileImageUrl, !profileImageUrl.isEmpty {
                                AsyncImage(url: URL(string: profileImageUrl)) { phase in
                                    switch phase {
                                    case .empty:
                                        ProgressView()
                                            .frame(width: 32, height: 32)
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 32, height: 32)
                                            .clipShape(Circle())
                                    case .failure:
                                        defaultToolbarAvatarView(username: currentUser.username)
                                    @unknown default:
                                        defaultToolbarAvatarView(username: currentUser.username)
                                    }
                                }
                            } else {
                                defaultToolbarAvatarView(username: currentUser.username)
                            }
                        } else {
                            Image(systemName: "person.circle.fill")
                                .font(.title2)
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create Recipe") {
                        showUploadRecipe = true
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                }
            }
            .sheet(isPresented: $showUploadRecipe) {
                UploadRecipeView()
            }
            .sheet(isPresented: $showAIAssistant) {
                AIAssistantSheetView()
                    .environmentObject(library)
            }
            .sheet(isPresented: $showProfileMenu) {
                ProfileMenuView()
            }
            .sheet(item: $selectedRecipe) { recipe in
                RecipeDetailView(recipe: recipe)
                    .environmentObject(library)
            }
            .onAppear {
                library.loadMyRecipes()
                library.loadFavorites()
                library.loadTodoList()
                loadUserStats()
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(selectedImage: $selectedAvatarImage, sourceType: .photoLibrary)
            }
            .sheet(isPresented: $showCamera) {
                ImagePicker(selectedImage: $selectedAvatarImage, sourceType: .camera)
            }
            .confirmationDialog("Change Profile Photo", isPresented: $showPhotoActionSheet, titleVisibility: .visible) {
                Button("Camera") {
                    showCamera = true
                }
                Button("Photo Library") {
                    showImagePicker = true
                }
                Button("Cancel", role: .cancel) { }
            }
            .onChange(of: selectedAvatarImage) { oldValue, newImage in
                if let image = newImage {
                    uploadAvatar(image: image)
                }
            }
            .onChange(of: selectedPhoto) { oldValue, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self) {
                        if let uiImage = UIImage(data: data) {
                            selectedAvatarImage = uiImage
                        }
                    }
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
            .frame(width: 60, height: 60)
            .overlay(
                Text(String(username.prefix(1).uppercased()))
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            )
    }
    
    private func defaultToolbarAvatarView(username: String) -> some View {
        Circle()
            .fill(LinearGradient(
                gradient: Gradient(colors: [Color.blue, Color.purple]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ))
            .frame(width: 32, height: 32)
            .overlay(
                Text(String(username.prefix(1).uppercased()))
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            )
    }
    
    // MARK: - Date Formatting Helpers
    private func formatDate(_ date: Date, style: DateFormatter.Style) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        return formatter.string(from: date)
    }
    
    private func formatDate(_ date: Date, format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: date)
    }
    
    // MARK: - Upload Avatar
    private func uploadAvatar(image: UIImage) {
        isUploadingAvatar = true
        
        Task {
            do {
                // Upload image to server
                let response = try await APIClient.shared.uploadImage(image: image, category: "profiles")
                let imageUrl = response.image.originalUrl
                
                print("✅ Avatar uploaded: \(imageUrl)")
                
                // Update user profile with new avatar URL
                let updatedUser = try await APIClient.shared.updateUserProfile(
                    username: nil,
                    email: nil,
                    gender: nil,
                    birthDate: nil,
                    bio: nil,
                    profileImageUrl: imageUrl
                )
                
                await MainActor.run {
                    APIClient.shared.currentUser = updatedUser
                    isUploadingAvatar = false
                    print("✅ Profile avatar updated successfully")
                }
            } catch {
                print("❌ Failed to upload avatar: \(error.localizedDescription)")
                await MainActor.run {
                    isUploadingAvatar = false
                }
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 16) {
            // User Profile Section
            if let currentUser = APIClient.shared.currentUser {
                HStack(spacing: 16) {
                    // Avatar (Clickable to change)
                    Button(action: {
                        showPhotoActionSheet = true
                    }) {
                        ZStack {
                            if let profileImageUrl = currentUser.profileImageUrl, !profileImageUrl.isEmpty {
                                // Show custom avatar if available
                                AsyncImage(url: URL(string: profileImageUrl)) { phase in
                                    switch phase {
                                    case .empty:
                                        ProgressView()
                                            .frame(width: 60, height: 60)
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 60, height: 60)
                                            .clipShape(Circle())
                                    case .failure:
                                        defaultAvatarView(username: currentUser.username)
                                    @unknown default:
                                        defaultAvatarView(username: currentUser.username)
                                    }
                                }
                            } else {
                                // Default avatar with initial
                                defaultAvatarView(username: currentUser.username)
                            }
                            
                            // Edit icon overlay
                            VStack {
                                Spacer()
                                HStack {
                                    Spacer()
                                    Image(systemName: "camera.fill")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                        .padding(6)
                                        .background(Color.blue)
                                        .clipShape(Circle())
                                        .offset(x: 2, y: 2)
                                }
                            }
                            .frame(width: 60, height: 60)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(currentUser.username)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        if let bio = currentUser.bio, !bio.isEmpty {
                            Text(bio)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                        
                        // User Info
                        HStack(spacing: 12) {
                            if let gender = currentUser.gender, !gender.isEmpty {
                                Label(gender, systemImage: "person")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.gray.opacity(0.05))
                .cornerRadius(12)
                
                // Statistics Section
                HStack(spacing: 20) {
                    NavigationLink(destination: FollowersListView()
                        .environmentObject(library)) {
                        StatCard(
                            title: "Followers",
                            value: "\(userStats.followersCount)",
                            icon: "person.2"
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    NavigationLink(destination: FollowingListView()
                        .environmentObject(library)) {
                        StatCard(
                            title: "Following",
                            value: "\(userStats.followingCount)",
                            icon: "person.2.fill"
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    NavigationLink(destination: LikedRecipesListView()) {
                        StatCard(
                            title: "Likes",
                            value: "\(userStats.totalLikesReceived)",
                            icon: "heart.fill"
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    NavigationLink(destination: MyRecipesListView()) {
                        StatCard(
                            title: "Recipes",
                            value: "\(userStats.recipesCount)",
                            icon: "book.fill"
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 16)
            } else {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Welcome back!")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("Ready to create something delicious?")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(.top, 8)
        .onAppear {
            loadUserStats()
        }
    }
    
    @State private var userStats = UserStats(followersCount: 0, followingCount: 0, totalLikesReceived: 0, recipesCount: 0)
    @State private var isLoadingStats = false
    
    private func loadUserStats() {
        guard APIClient.shared.currentUser != nil else { return }
        isLoadingStats = true
        
        Task {
            do {
                let stats = try await APIClient.shared.getUserStats()
                await MainActor.run {
                    self.userStats = stats
                    self.isLoadingStats = false
                    print("📊 User stats loaded: \(stats.recipesCount) recipes created")
                }
            } catch {
                print("❌ Failed to load user stats: \(error.localizedDescription)")
                await MainActor.run {
                    self.isLoadingStats = false
                }
            }
        }
    }
    
    // MARK: - Tab Selector
    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(0..<3) { index in
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
    
    private var tabTitles = ["My Recipes", "Favorites", "Todo List"]
    
    private var aiAssistantFloatingButton: some View {
        Button(action: {
            showAIAssistant = true
        }) {
            HStack(spacing: 8) {
                Image(systemName: "bubble.left.and.text.bubble.right.fill")
                    .font(.system(size: 18, weight: .semibold))
                Text("AI Assistant")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue, Color.purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("Open AI assistant")
    }
    
    // MARK: - My Recipes View
    private var myRecipesView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("My Recipes")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(library.myRecipes.count) recipes")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if library.myRecipes.isEmpty {
                EmptyStateView(
                    title: "No recipes yet",
                    subtitle: "Create your first recipe to get started.",
                    actionTitle: "Create Recipe",
                    action: { showUploadRecipe = true }
                )
                .padding(.top, 40)
            } else {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(library.myRecipes) { recipe in
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
    
    // MARK: - My Favorites View
    private var myFavoritesView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("My Favorites")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(library.favorites.count) favorites")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if library.favorites.isEmpty {
                EmptyStateView(
                    title: "No favorites yet",
                    subtitle: "Tap the heart on any recipe to save it here."
                )
                .padding(.top, 40)
            } else {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(library.favorites) { recipe in
                        NavigationLink(destination: RecipeDetailView(recipe: recipe)
                            .environmentObject(library)) {
                            RecipeCard(recipe: recipe, onToggleFavorite: {
                                library.toggleFavorite(recipe)
                            })
                            .environmentObject(library)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
    }
    
    // MARK: - My Todo List View
    private var myTodoListView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Todo List")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                let completedCount = library.todoList.filter { $0.completed }.count
                Text("\(completedCount)/\(library.todoList.count) completed")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if library.todoList.isEmpty {
                EmptyStateView(
                    title: "No recipes to try",
                    subtitle: "Add recipes to your todo list to try them later.",
                    actionTitle: nil,
                    action: nil
                )
                .frame(maxWidth: .infinity)
                .padding(.top, 40)
            } else {
                VStack(spacing: 0) {
                    ForEach(library.todoList, id: \.recipe.id) { item in
                        NavigationLink(destination: RecipeDetailView(recipe: item.recipe)
                            .environmentObject(library)) {
                            TodoListItemRow(item: item, onToggleCompletion: {
                                library.toggleTodoCompletion(item)
                            })
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(Color(.systemBackground))
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        if item.recipe.id != library.todoList.last?.recipe.id {
                            Divider()
                                .padding(.leading, 16)
                        }
                    }
                }
                .background(Color(.systemBackground))
                .cornerRadius(12)
            }
        }
    }
}

// MARK: - Profile Menu View (User Settings)
struct ProfileMenuView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var apiClient = APIClient.shared
    @State private var showEditProfile = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    profileHeader
                    
                    // Profile Information
                    profileInfoSection
                    
                    // Menu Options
                    menuOptionsSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
            }
            .sheet(isPresented: $showEditProfile) {
                EditProfileView()
            }
        }
    }
    
    // MARK: - Profile Header
    private var profileHeader: some View {
        VStack(spacing: 16) {
            // Avatar
            if let currentUser = APIClient.shared.currentUser {
                Circle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [Color.blue, Color.purple]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 100, height: 100)
                    .overlay(
                        Text(String(currentUser.username.prefix(1).uppercased()))
                            .font(.system(size: 40))
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    )
                
                // Name and basic info
                VStack(spacing: 4) {
                    Text(currentUser.username)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    if let bio = currentUser.bio, !bio.isEmpty {
                        Text(bio)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    } else {
                        Text("Culinary Enthusiast")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                }
                
                Text("Guest User")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
        }
    }
    
    // MARK: - Profile Info Section
    private var profileInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Personal Information")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                if let currentUser = APIClient.shared.currentUser {
                    infoRow(title: "Username", value: currentUser.username)
                    
                    if !currentUser.email.isEmpty {
                        infoRow(title: "Email", value: currentUser.email)
                    }
                    
                    if let gender = currentUser.gender, !gender.isEmpty {
                        infoRow(title: "Gender", value: gender)
                    } else {
                        infoRow(title: "Gender", value: "Not specified")
                    }
                    
                    if let birthDate = currentUser.birthDate {
                        infoRow(title: "Birth Date", value: formatDate(birthDate, style: .medium))
                    } else {
                        infoRow(title: "Birth Date", value: "Not specified")
                    }
                    
                    if let createdAt = currentUser.createdAt {
                        infoRow(title: "Member Since", value: formatDate(createdAt, format: "MMMM yyyy"))
                    }
                } else {
                    infoRow(title: "Status", value: "Not logged in")
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
    
    // MARK: - Date Formatting Helpers
    private func formatDate(_ date: Date, style: DateFormatter.Style) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        return formatter.string(from: date)
    }
    
    private func formatDate(_ date: Date, format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: date)
    }
    
    // MARK: - Menu Options Section
    private var menuOptionsSection: some View {
        VStack(spacing: 12) {
            menuButton(title: "Edit Profile", icon: "pencil", action: { 
                showEditProfile = true 
            })
            menuButton(title: "Account Settings", icon: "gear", action: { 
                // TODO: Navigate to account settings
            })
            menuButton(title: "Privacy", icon: "lock.shield", action: { 
                // TODO: Navigate to privacy settings
            })
            menuButton(title: "Notifications", icon: "bell", action: { 
                // TODO: Navigate to notification settings
            })
            menuButton(title: "Help & Support", icon: "questionmark.circle", action: { 
                // TODO: Show help & support
            })
            menuButton(title: "About", icon: "info.circle", action: { 
                // TODO: Show about page
            })
            
            Divider()
                .padding(.vertical, 8)
            
            menuButton(title: "Logout", icon: "arrow.right.square", action: { 
                handleLogout()
            }, isDestructive: true)
        }
    }
    
    private func handleLogout() {
        // Clear current user
        APIClient.shared.currentUser = nil
        APIClient.shared.authToken = nil
        
        // Dismiss the settings view
        dismiss()
        
        // TODO: Navigate to login screen
        // This might require a state change in the parent view
    }
    
    // MARK: - Helper Views
    private func infoRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(.primary)
        }
    }
    
    private func menuButton(title: String, icon: String, action: @escaping () -> Void, isDestructive: Bool = false) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(isDestructive ? .red : .blue)
                    .frame(width: 20)
                
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(isDestructive ? .red : .primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(8)
        }
    }
}

// MARK: - Edit Profile View
struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var apiClient = APIClient.shared
    
    @State private var username = "yutong"
    @State private var email = "yutong@example.com"
    @State private var gender = "Not specified"
    @State private var birthDate = Date()
    @State private var isEditing = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Information") {
                    TextField("Username", text: $username)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                }
                
                Section("Personal Details") {
                    Picker("Gender", selection: $gender) {
                        Text("Not specified").tag("Not specified")
                        Text("Male").tag("Male")
                        Text("Female").tag("Female")
                        Text("Other").tag("Other")
                    }
                    
                    DatePicker("Birth Date", selection: $birthDate, displayedComponents: .date)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveProfile()
                    }
                    .disabled(!isEditing)
                }
            }
            .onAppear {
                isEditing = true
            }
        }
    }
    
    private func saveProfile() {
        Task {
            do {
                let updatedUser = try await apiClient.updateUserProfile(
                    username: username,
                    email: email,
                    gender: gender,
                    birthDate: birthDate,
                    bio: nil,
                    profileImageUrl: nil
                )
                
                await MainActor.run {
                    print("✅ Profile updated successfully: \(updatedUser.username)")
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    print("❌ Failed to update profile: \(error.localizedDescription)")
                    // TODO: Show error alert
                }
            }
        }
    }
}

// MARK: - Profile View (Legacy - keeping for reference)
struct ProfileView: View {
    @EnvironmentObject var library: Library
    @State private var showEdit = false
    @State private var showUploadRecipe = false
    
    private let columns = [GridItem(.flexible(), spacing: 10),
                           GridItem(.flexible(), spacing: 10)]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    header
                    actions
                    // Content area: show grid with data; show empty state without data
                    if library.recipes.isEmpty {
                        EmptyStateView(
                            title: "No recipes yet",
                            subtitle: "Share your first recipe to get started.",
                            actionTitle: "Create",
                            action: { showUploadRecipe = true }
                        )
                        .padding(.top, 24)
                    } else {
                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(library.recipes) { recipe in
                                RecipeCard(recipe: recipe, onToggleFavorite: {
                                    library.toggleFavorite(recipe)
                                })
                                .environmentObject(library)
                            }
                        }
                        .padding(.top, 6)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Clear All (for test)") { library.clearAll() }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showUploadRecipe) {
                UploadRecipeView()
            }
        }
    }
    
    // Avatar + Name (can be replaced with your data)
    private var header: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().fill(Color.gray.opacity(0.12)).frame(width: 84, height: 84)
                Image(systemName: "person.circle.fill")
                    .resizable().scaledToFit().frame(width: 64, height: 64)
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("Yutong").font(.title3).bold()
                Text("Culinary • Data • App Builder").font(.footnote).foregroundStyle(.secondary)
            }
            Spacer()
        }
    }
    
    private var actions: some View {
        HStack(spacing: 10) {
            Button {
                showEdit = true
            } label: {
                Label("Edit Profile", systemImage: "pencil")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .background(.black.opacity(0.06), in: Capsule())
            }
            .buttonStyle(.plain)
            
            Button {
                showUploadRecipe = true
            } label: {
                Label("Create Recipe", systemImage: "plus.circle")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .background(.blue.opacity(0.1), in: Capsule())
                    .foregroundColor(.blue)
            }
            .buttonStyle(.plain)
            
            Spacer()
        }
    }
}

// MARK: - Favorites View
struct FavoritesView: View {
    @EnvironmentObject var library: Library
    private let columns = [GridItem(.flexible(), spacing: 10),
                           GridItem(.flexible(), spacing: 10)]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if library.favorites.isEmpty {
                    EmptyStateView(
                        title: "No favorites",
                        subtitle: "Tap the heart on any recipe to save it here."
                    )
                    .padding(.top, 40)
                } else {
                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(library.favorites) { recipe in
                            RecipeCard(recipe: recipe, onToggleFavorite: {
                                library.toggleFavorite(recipe)
                            })
                            .environmentObject(library)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Favorites")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Recipe Card Component
struct RecipeCard: View {
    let recipe: Recipe
    let onToggleFavorite: () -> Void
    let onTap: (() -> Void)?
    @EnvironmentObject var library: Library
    @State private var isLiked = false
    @State private var likesCount: Int = 0
    @State private var isLiking = false
    
    init(recipe: Recipe, onToggleFavorite: @escaping () -> Void, onTap: (() -> Void)? = nil) {
        self.recipe = recipe
        self.onToggleFavorite = onToggleFavorite
        self.onTap = onTap
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Recipe Image and Title
            Button(action: {
                onTap?()
            }) {
                VStack(alignment: .leading, spacing: 8) {
                    // Recipe Image
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.1))
                            .frame(height: 120)
                        
                        if let imageUrl = recipe.imageUrl, !imageUrl.isEmpty {
                            AsyncImage(url: URL(string: imageUrl)) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                        .frame(height: 120)
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(height: 120)
                                        .clipped()
                                case .failure:
                                    Image(systemName: "fork.knife")
                                        .font(.system(size: 40))
                                        .foregroundColor(.gray)
                                @unknown default:
                                    Image(systemName: "fork.knife")
                                        .font(.system(size: 40))
                                        .foregroundColor(.gray)
                                }
                            }
                        } else {
                            Image(systemName: "fork.knife")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                        }
                    }
                    .cornerRadius(12)
                    .clipped()
                    
                    Text(recipe.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(2)
                        .foregroundColor(.primary)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // Only show like button on homepage
            HStack {
                Spacer()
                Button(action: {
                    toggleLike()
                }) {
                    HStack(spacing: 4) {
                        if isLiking {
                            ProgressView()
                                .scaleEffect(0.7)
                        } else {
                            Image(systemName: isLiked ? "heart.fill" : "heart")
                                .foregroundColor(isLiked ? .red : .gray)
                        }
                        Text("\(likesCount)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(isLiking)
            }
        }
        .padding(8)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .onAppear {
            likesCount = recipe.likesCount ?? 0
            checkLikeStatus()
        }
    }
    
    private func checkLikeStatus() {
        guard let recipeId = recipe.id else { return }
        Task {
            do {
                let interactions = try await APIClient.shared.getUserInteractions(recipeId: recipeId)
                await MainActor.run {
                    isLiked = interactions.isLiked
                }
            } catch {
                print("❌ Failed to check like status: \(error)")
            }
        }
    }
    
    private func toggleLike() {
        guard let recipeId = recipe.id else { return }
        isLiking = true
        
        Task {
            do {
                if isLiked {
                    try await APIClient.shared.unlikeRecipe(recipeId: recipeId)
                    let newCount = try await APIClient.shared.getRecipeLikes(recipeId: recipeId)
                    await MainActor.run {
                        isLiked = false
                        likesCount = newCount
                        isLiking = false
                    }
                } else {
                    try await APIClient.shared.likeRecipe(recipeId: recipeId)
                    let newCount = try await APIClient.shared.getRecipeLikes(recipeId: recipeId)
                    await MainActor.run {
                        isLiked = true
                        likesCount = newCount
                        isLiking = false
                    }
                }
            } catch {
                print("❌ Failed to toggle like: \(error)")
                await MainActor.run {
                    isLiking = false
                }
            }
        }
    }
}

// MARK: - Todo List Item Row
struct TodoListItemRow: View {
    let item: APIClient.TodoListItem
    let onToggleCompletion: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Recipe Image
            if let imageUrl = item.recipe.imageUrl, !imageUrl.isEmpty {
                AsyncImage(url: URL(string: imageUrl)) { phase in
                    switch phase {
                    case .empty:
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 60, height: 60)
                            .overlay(ProgressView())
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    case .failure:
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 60, height: 60)
                            .overlay(Image(systemName: "photo"))
                    @unknown default:
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 60, height: 60)
                    }
                }
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .overlay(Image(systemName: "fork.knife"))
            }
            
            // Recipe Info
            VStack(alignment: .leading, spacing: 4) {
                Text(item.recipe.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .strikethrough(item.completed)
                
                if let description = item.recipe.description, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .strikethrough(item.completed)
                }
            }
            
            Spacer()
            
            // Completion Toggle
            Button(action: {
                onToggleCompletion()
            }) {
                Image(systemName: item.completed ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(item.completed ? .green : .gray)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 8)
        .opacity(item.completed ? 0.6 : 1.0)
    }
}

// MARK: - Stat Card Component
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(10)
    }
}

// MARK: - Followers List View
struct FollowersListView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var library: Library
    @StateObject private var apiClient = APIClient.shared
    @State private var followers: [User] = []
    @State private var isLoading = true
    
    var body: some View {
        NavigationStack {
            List {
                if isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .padding()
                } else if followers.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "person.2")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No followers yet")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 100)
                } else {
                    ForEach(followers) { user in
                        NavigationLink(destination: UserProfileView(userId: user.id ?? 0, username: user.username)
                            .environmentObject(library)) {
                            FollowerUserRowView(user: user)
                        }
                    }
                }
            }
            .navigationTitle("Followers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.primary)
                    }
                }
            }
            .onAppear {
                loadFollowers()
            }
        }
    }
    
    private func loadFollowers() {
        Task {
            do {
                let users = try await apiClient.getMyFollowers()
                await MainActor.run {
                    self.followers = users
                    self.isLoading = false
                }
            } catch {
                print("❌ Failed to load followers: \(error.localizedDescription)")
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
}

// MARK: - Following List View
struct FollowingListView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var library: Library
    @StateObject private var apiClient = APIClient.shared
    @State private var following: [User] = []
    @State private var isLoading = true
    
    var body: some View {
        NavigationStack {
            List {
                if isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .padding()
                } else if following.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("Not following anyone yet")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 100)
                } else {
                    ForEach(following) { user in
                        NavigationLink(destination: UserProfileView(userId: user.id ?? 0, username: user.username)
                            .environmentObject(library)) {
                            FollowerUserRowView(user: user)
                        }
                    }
                }
            }
            .navigationTitle("Following")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.primary)
                    }
                }
            }
            .onAppear {
                loadFollowing()
            }
        }
    }
    
    private func loadFollowing() {
        Task {
            do {
                let users = try await apiClient.getMyFollowing()
                await MainActor.run {
                    self.following = users
                    self.isLoading = false
                }
            } catch {
                print("❌ Failed to load following: \(error.localizedDescription)")
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
}

// MARK: - Liked Recipes List View
struct LikedRecipesListView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var library: Library
    @StateObject private var apiClient = APIClient.shared
    @State private var likedRecipes: [Recipe] = []
    @State private var isLoading = true
    @State private var selectedRecipe: Recipe?
    
    private let columns = [GridItem(.flexible(), spacing: 10),
                           GridItem(.flexible(), spacing: 10)]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if isLoading {
                    ProgressView()
                        .padding(.top, 100)
                } else if likedRecipes.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "heart")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No liked recipes yet")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 100)
                } else {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(likedRecipes) { recipe in
                            RecipeCard(recipe: recipe, onToggleFavorite: {
                                // Toggle favorite for liked recipes
                                Task {
                                    do {
                                        if library.isFavorite(recipe) {
                                            try await apiClient.removeFavorite(recipeId: recipe.id ?? 0)
                                            await MainActor.run {
                                                library.favorites.removeAll { $0.id == recipe.id }
                                            }
                                        } else {
                                            let _ = try await apiClient.addFavorite(recipeId: recipe.id ?? 0)
                                            await MainActor.run {
                                                if !library.favorites.contains(where: { $0.id == recipe.id }) {
                                                    library.favorites.append(recipe)
                                                }
                                            }
                                        }
                                    } catch {
                                        print("❌ Failed to toggle favorite: \(error.localizedDescription)")
                                    }
                                }
                            }, onTap: {
                                selectedRecipe = recipe
                            })
                            .environmentObject(library)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Liked Recipes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadLikedRecipes()
            }
            .sheet(item: $selectedRecipe) { recipe in
                RecipeDetailView(recipe: recipe)
                    .environmentObject(library)
            }
        }
    }
    
    private func loadLikedRecipes() {
        Task {
            do {
                let recipes = try await apiClient.getMyLikedRecipes()
                await MainActor.run {
                    self.likedRecipes = recipes
                    self.isLoading = false
                }
            } catch {
                print("❌ Failed to load liked recipes: \(error.localizedDescription)")
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
}

// MARK: - My Recipes List View
struct MyRecipesListView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var library: Library
    @StateObject private var apiClient = APIClient.shared
    @State private var myRecipes: [Recipe] = []
    @State private var isLoading = true
    @State private var selectedRecipe: Recipe?
    
    private let columns = [GridItem(.flexible(), spacing: 10),
                           GridItem(.flexible(), spacing: 10)]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if isLoading {
                    ProgressView()
                        .padding(.top, 100)
                } else if myRecipes.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "book.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No recipes created yet")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 100)
                } else {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(myRecipes) { recipe in
                            RecipeCard(recipe: recipe, onToggleFavorite: {
                                // Toggle favorite for my recipes
                                Task {
                                    do {
                                        if library.isFavorite(recipe) {
                                            try await apiClient.removeFavorite(recipeId: recipe.id ?? 0)
                                            await MainActor.run {
                                                library.favorites.removeAll { $0.id == recipe.id }
                                            }
                                        } else {
                                            let _ = try await apiClient.addFavorite(recipeId: recipe.id ?? 0)
                                            await MainActor.run {
                                                if !library.favorites.contains(where: { $0.id == recipe.id }) {
                                                    library.favorites.append(recipe)
                                                }
                                            }
                                        }
                                    } catch {
                                        print("❌ Failed to toggle favorite: \(error.localizedDescription)")
                                    }
                                }
                            }, onTap: {
                                selectedRecipe = recipe
                            })
                            .environmentObject(library)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("My Recipes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadMyRecipes()
            }
            .sheet(item: $selectedRecipe) { recipe in
                RecipeDetailView(recipe: recipe)
                    .environmentObject(library)
            }
        }
    }
    
    private func loadMyRecipes() {
        Task {
            do {
                let recipes = try await apiClient.getMyRecipes()
                await MainActor.run {
                    self.myRecipes = recipes
                    self.isLoading = false
                }
            } catch {
                print("❌ Failed to load my recipes: \(error.localizedDescription)")
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
}

// MARK: - Follower User Row View
struct FollowerUserRowView: View {
    let user: User
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            if let profileImageUrl = user.profileImageUrl, !profileImageUrl.isEmpty {
                AsyncImage(url: URL(string: profileImageUrl)) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: 50, height: 50)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                    case .failure:
                        defaultAvatarView(username: user.username)
                    @unknown default:
                        defaultAvatarView(username: user.username)
                    }
                }
            } else {
                defaultAvatarView(username: user.username)
            }
            
            // User Info
            VStack(alignment: .leading, spacing: 4) {
                Text(user.username)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if let bio = user.bio, !bio.isEmpty {
                    Text(bio)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
    
    private func defaultAvatarView(username: String) -> some View {
        Circle()
            .fill(LinearGradient(
                gradient: Gradient(colors: [Color.blue, Color.purple]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ))
            .frame(width: 50, height: 50)
            .overlay(
                Text(String(username.prefix(1).uppercased()))
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            )
    }
}

// MARK: - Empty State Component
struct EmptyStateView: View {
    let title: String
    let subtitle: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(title: String, subtitle: String, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundColor(.gray.opacity(0.6))
            
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            if let actionTitle = actionTitle, let action = action {
                Button(actionTitle, action: action)
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding(.horizontal, 32)
    }
}

// MARK: - AI Assistant Sheet
struct AIAssistantSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var library: Library
    
    @State private var dietInput = ""
    @State private var ingredientsInput = ""
    @State private var equipmentInput = ""
    @State private var resultLimit: Int = 5
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var matches: [MatchedRecipe] = []
    @State private var selectedRecipe: Recipe?
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Diet Requirements")) {
                    TextField("e.g., Vegan, Gluten-Free", text: $dietInput, axis: .vertical)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                    Text("Separate multiple diet requirements with commas or newlines").font(.caption).foregroundColor(.secondary)
                }
                
                Section(header: Text("Available Ingredients")) {
                    TextField("Enter ingredients you have, e.g., chicken, tomato", text: $ingredientsInput, axis: .vertical)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                    Text("Use English ingredient names for better matching").font(.caption).foregroundColor(.secondary)
                }
                
                Section(header: Text("Available Tools")) {
                    TextField("e.g., air fryer, blender", text: $equipmentInput, axis: .vertical)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                }
                
                Section(header: Text("Options")) {
                    Stepper(value: $resultLimit, in: 1...15) {
                        Text("Show \(resultLimit) recommendations")
                    }
                    Button {
                        requestMatches()
                    } label: {
                        HStack {
                            if isLoading {
                                ProgressView()
                            }
                            Text("Start Matching")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(isLoading)
                }
                
                Section(header: Text("Results")) {
                    if isLoading {
                        HStack {
                            Spacer()
                            ProgressView("Matching recipes...")
                            Spacer()
                        }
                    } else if let errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    } else if matches.isEmpty {
                        Text("Enter your criteria and tap 'Start Matching' to get recipe recommendations.")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(matches) { match in
                            Button {
                                selectedRecipe = match.recipe
                            } label: {
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text(match.recipe.title)
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        Spacer()
                                        Text("\(Int(match.matchScore * 100))%")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.blue)
                                    }
                                    
                                    if let calories = match.recipe.caloriesPerServing {
                                        Text("\(calories) kcal/serving")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    if let reason = match.matchReason, !reason.isEmpty {
                                        Text(reason)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    if let diets = match.recipe.dietTypes, !diets.isEmpty {
                                        Text(diets.joined(separator: " • "))
                                            .font(.caption2)
                                            .foregroundColor(.green)
                                    }
                                }
                                .padding(.vertical, 6)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
            .navigationTitle("AI Recipe Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $selectedRecipe) { recipe in
                RecipeDetailView(recipe: recipe)
                    .environmentObject(library)
            }
        }
    }
    
    private func requestMatches() {
        let diets = parseList(from: dietInput)
        let ingredients = parseList(from: ingredientsInput)
        let equipment = parseList(from: equipmentInput)
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let results = try await APIClient.shared.matchRecipes(
                    dietRequirements: diets,
                    availableIngredients: ingredients,
                    availableEquipment: equipment,
                    limit: resultLimit
                )
                await MainActor.run {
                    matches = results
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                    matches = []
                }
            }
        }
    }
    
    private func parseList(from input: String) -> [String] {
        input
            .components(separatedBy: CharacterSet(charactersIn: ",\n"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}
