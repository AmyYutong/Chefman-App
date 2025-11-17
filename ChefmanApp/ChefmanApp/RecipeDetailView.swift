import SwiftUI
import PhotosUI

// MARK: - Recipe Detail View (Similar to Xiaohongshu detail page)
struct RecipeDetailView: View {
    let recipe: Recipe
    @EnvironmentObject var library: Library
    @Environment(\.dismiss) private var dismiss
    @StateObject private var apiClient = APIClient.shared
    
    @State private var comments: [Comment] = []
    @State private var newComment = ""
    @State private var isAddingComment = false
    @State private var isLoadingComments = false
    
    // Interaction states
    @State private var isLiked = false
    @State private var isFavorited = false
    @State private var isInTodo = false
    @State private var isFollowingCreator = false
    @State private var likesCount: Int = 0
    @State private var favoritesCount: Int = 0
    @State private var commentsCount: Int = 0
    @State private var todoCount: Int = 0
    
    // Loading states
    @State private var isLiking = false
    @State private var isFavoriting = false
    @State private var isTodding = false
    @State private var isFollowing = false
    @State private var showUserProfile = false
    @State private var showAllSteps = false
    @State private var selectedStep: RecipeStepDisplay? = nil
    @State private var showStepDetail = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Recipe Image
                recipeImageView
                
                // Content Area
                VStack(alignment: .leading, spacing: 16) {
                    // Title and Basic Info
                    headerSection
                    
                    // Creator Information
                    creatorSection
                    
                    // Recipe Details
                    recipeDetailsSection
                    
                    // Ingredients List
                    ingredientsSection
                    
                    // Equipment List
                    equipmentSection
                    
                    // Cooking Steps
                    stepsSection
                    
                    // Comments Section
                    commentsSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 20)
            }
        }
        .ignoresSafeArea(edges: .top)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Close") {
                    dismiss()
                }
            }
        }
        .onAppear {
            loadComments()
            loadInteractionStatus()
            updateCounts()
        }
        .sheet(isPresented: $showUserProfile) {
            if let creatorId = recipe.creatorId {
                UserProfileView(userId: creatorId, username: recipe.creatorUsername)
                    .environmentObject(library)
            }
        }
        .sheet(isPresented: $showStepDetail) {
            if let step = selectedStep {
                StepDetailView(step: step, recipeTitle: recipe.title)
            }
        }
    }
    
    // MARK: - Recipe Image
    private var recipeImageView: some View {
        Group {
            if let imageUrl = recipe.imageUrl, !imageUrl.isEmpty {
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            ProgressView()
                                .scaleEffect(1.2)
                        )
                }
            } else {
                Rectangle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [Color.orange.opacity(0.8), Color.red.opacity(0.6)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .overlay(
                        Image(systemName: "fork.knife")
                            .font(.system(size: 50))
                            .foregroundColor(.white)
                    )
            }
        }
        .frame(height: 250)
        .frame(maxWidth: .infinity)
        .clipped()
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(recipe.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    if let description = recipe.description, !description.isEmpty {
                        Text(description)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .lineLimit(3)
                    }
                }
                
                Spacer()
                
                // Interaction Buttons
                VStack(spacing: 12) {
                    // Like Button
                    Button(action: {
                        toggleLike()
                    }) {
                        VStack(spacing: 4) {
                            if isLiking {
                                ProgressView()
                                    .scaleEffect(0.7)
                            } else {
                                Image(systemName: isLiked ? "heart.fill" : "heart")
                                    .font(.title2)
                                    .foregroundColor(isLiked ? .red : .gray)
                            }
                            Text("\(likesCount)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(isLiking)
                    
                    // Comment Button
                    Button(action: {
                        // Scroll to comments section (could be enhanced)
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: "bubble.left")
                                .font(.title2)
                                .foregroundColor(.gray)
                            Text("\(commentsCount)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Favorite Button (Star)
                    Button(action: {
                        toggleFavorite()
                    }) {
                        VStack(spacing: 4) {
                            if isFavoriting {
                                ProgressView()
                                    .scaleEffect(0.7)
                            } else {
                                Image(systemName: isFavorited ? "star.fill" : "star")
                                    .font(.title2)
                                    .foregroundColor(isFavorited ? .yellow : .gray)
                            }
                            Text("\(favoritesCount)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(isFavoriting)
                    
                    // Try It Later Button (Bookmark)
                    Button(action: {
                        toggleTodo()
                    }) {
                        VStack(spacing: 4) {
                            if isTodding {
                                ProgressView()
                                    .scaleEffect(0.7)
                            } else {
                                Image(systemName: isInTodo ? "bookmark.fill" : "bookmark")
                                    .font(.title2)
                                    .foregroundColor(isInTodo ? .blue : .gray)
                            }
                            Text("\(todoCount)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(isTodding)
                }
            }
            
            // Tags
            VStack(alignment: .leading, spacing: 8) {
                // Basic tags
                HStack(spacing: 8) {
                    Label(recipe.recipeType, systemImage: "tag")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(8)
                    
                    Label(recipe.cuisineType, systemImage: "globe")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.1))
                        .foregroundColor(.green)
                        .cornerRadius(8)
                    
                    Label(recipe.difficulty, systemImage: "star")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.1))
                        .foregroundColor(.orange)
                        .cornerRadius(8)
                }
                
                // Calories
                if let calories = recipe.caloriesPerServing {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                        Text("\(calories) cal/serving")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                }
                
                // Diet types
                if let dietTypes = recipe.dietTypes, !dietTypes.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(dietTypes, id: \.self) { dietType in
                                Label(dietType, systemImage: "leaf.fill")
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(dietTypeColor(dietType).opacity(0.15))
                                    .foregroundColor(dietTypeColor(dietType))
                                    .cornerRadius(6)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Diet Type Color Helper
    private func dietTypeColor(_ dietType: String) -> Color {
        switch dietType.lowercased() {
        case "keto", "low-carb":
            return .purple
        case "vegan":
            return .green
        case "vegetarian":
            return .mint
        case "glp-1":
            return .blue
        case "paleo":
            return .brown
        case "mediterranean":
            return .orange
        case "high-protein":
            return .red
        case "gluten-free":
            return .yellow
        case "dairy-free":
            return .cyan
        case "low-sodium":
            return .teal
        case "heart-healthy":
            return .pink
        default:
            return .gray
        }
    }
    
    // MARK: - Creator Section
    private var creatorSection: some View {
        HStack(spacing: 12) {
            // Creator Avatar (Clickable)
            Button(action: {
                if let creatorId = recipe.creatorId {
                    showUserProfile = true
                }
            }) {
                // Try to load creator's profile image if available
                // For now, show default avatar (we can enhance this later to fetch creator's profile)
                Circle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [Color.blue, Color.purple]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(creatorInitial)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    )
            }
            .buttonStyle(PlainButtonStyle())
            
            // Creator Name (Clickable) - Display username directly
            Button(action: {
                if let creatorId = recipe.creatorId {
                    showUserProfile = true
                }
            }) {
                Text(creatorName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
               // Only show follow button if creator exists and is not current user
               if let creatorId = recipe.creatorId, creatorId != APIClient.shared.currentUser?.id {
                   Button(action: {
                       toggleFollow()
                   }) {
                       HStack(spacing: 4) {
                           if isFollowing {
                               ProgressView()
                                   .scaleEffect(0.7)
                                   .foregroundColor(.white)
                           } else {
                               Image(systemName: isFollowingCreator ? "checkmark.circle.fill" : "person.badge.plus")
                                   .font(.caption2)
                                   .foregroundColor(.white)
                           }
                           
                           Text(isFollowingCreator ? "Following" : "Follow")
                               .font(.caption)
                               .fontWeight(.medium)
                               .foregroundColor(.white)
                       }
                   }
                   .padding(.horizontal, 12)
                   .padding(.vertical, 6)
                   .background(isFollowingCreator ? Color.gray : Color.blue)
                   .foregroundColor(.white)
                   .cornerRadius(15)
                   .disabled(isFollowing)
               }
        }
        .padding(.vertical, 8)
    }
    
    private var creatorName: String {
        recipe.creatorUsername ?? "Unknown User"
    }
    
    private var creatorInitial: String {
        String(creatorName.prefix(1).uppercased())
    }
    
    // MARK: - Recipe Details Section
    private var recipeDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recipe Information")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                DetailCard(
                    icon: "clock",
                    title: "Prep Time",
                    value: recipe.prepTime ?? "Not set",
                    color: .blue
                )
                
                DetailCard(
                    icon: "flame",
                    title: "Cook Time",
                    value: recipe.cookTime ?? "Not set",
                    color: .orange
                )
                
                DetailCard(
                    icon: "person.2",
                    title: "Servings",
                    value: "\(recipe.servings) people",
                    color: .green
                )
            }
        }
    }
    
    // MARK: - Ingredients Section
    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ingredients")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            if let ingredients = recipe.ingredients, !ingredients.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(ingredients) { ingredient in
                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            Circle()
                                .fill(Color.blue.opacity(0.2))
                                .frame(width: 8, height: 8)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(ingredient.ingredientName)
                                    .font(.body)
                                    .foregroundColor(.primary)
                                
                                HStack(spacing: 6) {
                                    if let amount = ingredient.amount, !amount.isEmpty {
                                        Text(amount)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    if let unit = ingredient.unit, !unit.isEmpty {
                                        Text(unit)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    if let notes = ingredient.notes, !notes.isEmpty {
                                        Text("• \(notes)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            
                            Spacer()
                        }
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(8)
                    }
                }
            } else {
                Text("Ingredient details are not available for this recipe.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
    }
    
    // MARK: - Equipment Section
    private var equipmentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Equipment")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            if let equipmentList = recipe.equipment, !equipmentList.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(equipmentList) { equipment in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: equipment.isChefman ? "gearshape.fill" : "wand.and.stars")
                                .font(.subheadline)
                                .foregroundColor(equipment.isChefman ? .orange : .blue)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(equipment.equipmentName)
                                    .font(.body)
                                    .fontWeight(.medium)
                                
                                HStack(spacing: 6) {
                                    if let brand = equipment.brand, !brand.isEmpty {
                                        Text(brand)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    if equipment.isChefman {
                                        Text("Chefman")
                                            .font(.caption2)
                                            .fontWeight(.bold)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.orange.opacity(0.15))
                                            .foregroundColor(.orange)
                                            .cornerRadius(6)
                                    }
                                }
                            }
                            
                            Spacer()
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(10)
                    }
                }
            } else {
                Text("No equipment information provided.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
    }
    
    // MARK: - Steps Section
    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cooking Steps")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            // Preview of actual steps
            if let steps = recipe.steps, !steps.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    // Show first 3 steps, or all steps if expanded
                    let stepsToShow = showAllSteps ? steps : Array(steps.prefix(3))
                    
                    ForEach(Array(stepsToShow.enumerated()), id: \.element.id) { index, step in
                        Button(action: {
                            selectedStep = step
                            showStepDetail = true
                        }) {
                            HStack(alignment: .top, spacing: 12) {
                                // Step Number
                                ZStack {
                                    Circle()
                                        .fill(Color.blue)
                                        .frame(width: 24, height: 24)
                                    
                                    Text("\(step.stepNumber)")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                }
                                
                                // Step Info
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(step.description)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                        .lineLimit(showAllSteps ? nil : 2)
                                    
                                    HStack(spacing: 8) {
                                        if let duration = step.duration, !duration.isEmpty {
                                            Label(duration, systemImage: "clock")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        if step.videoUrl != nil && !step.videoUrl!.isEmpty {
                                            Label("Video", systemImage: "play.circle.fill")
                                                .font(.caption)
                                                .foregroundColor(.blue)
                                        }
                                        if step.imageUrl != nil && !step.imageUrl!.isEmpty {
                                            Label("Image", systemImage: "photo.fill")
                                                .font(.caption)
                                                .foregroundColor(.green)
                                        }
                                    }
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    if steps.count > 3 {
                        Button(action: {
                            withAnimation {
                                showAllSteps.toggle()
                            }
                        }) {
                            HStack {
                                Text(showAllSteps ? "Show less" : "View all \(steps.count) steps")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.blue)
                                Spacer()
                                Image(systemName: showAllSteps ? "chevron.up.circle.fill" : "arrow.right.circle.fill")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                            }
                            .padding(.top, 4)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            } else {
                Text("No steps available")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
    }
    
    // MARK: - Comments Section
    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Comments (\(comments.count))")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            // Add Comment Input
            VStack(spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    // User Avatar
                    Circle()
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [Color.blue, Color.purple]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 32, height: 32)
                        .overlay(
                            Text("U")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        )
                    
                    // Comment Input
                    VStack(spacing: 8) {
                        TextField("Write a comment...", text: $newComment, axis: .vertical)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .lineLimit(3...6)
                        
                        HStack {
                            Spacer()
                            Button("Post") {
                                addComment()
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                            .disabled(newComment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isAddingComment)
                        }
                    }
                }
            }
            .padding(.bottom, 8)
            
            // Comments List
            if isLoadingComments {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else if comments.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "bubble.left")
                        .font(.title2)
                        .foregroundColor(.gray)
                    
                    Text("No comments yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                // Show all comments
                ForEach(comments) { comment in
                    CommentRowView(comment: comment)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    private func loadComments() {
        isLoadingComments = true
        Task {
            do {
                if let recipeId = recipe.id {
                    let apiComments = try await apiClient.getComments(for: recipeId)
                    await MainActor.run {
                        self.comments = apiComments
                        self.commentsCount = apiComments.count
                        self.isLoadingComments = false
                    }
                } else {
                    await MainActor.run {
                        self.comments = []
                        self.commentsCount = 0
                        self.isLoadingComments = false
                    }
                }
            } catch {
                print("❌ Failed to load comments: \(error.localizedDescription)")
                await MainActor.run {
                    self.comments = []
                    self.commentsCount = 0
                    self.isLoadingComments = false
                }
            }
        }
    }
    
    private func loadInteractionStatus() {
        guard let recipeId = recipe.id else { return }
        
        Task {
            do {
                let interactions = try await apiClient.getUserInteractions(recipeId: recipeId)
                await MainActor.run {
                    self.isLiked = interactions.isLiked
                    self.isFavorited = interactions.isFavorited
                    self.isInTodo = interactions.isInTodo
                    self.isFollowingCreator = interactions.isFollowingCreator ?? false
                }
            } catch {
                print("❌ Failed to load interaction status: \(error.localizedDescription)")
            }
        }
    }
    
    private func toggleFollow() {
        guard let creatorId = recipe.creatorId else { return }
        guard creatorId != APIClient.shared.currentUser?.id else { return }
        
        isFollowing = true
        
        Task {
            do {
                if isFollowingCreator {
                    // Unfollow the user
                    try await apiClient.unfollowUser(userId: creatorId)
                    print("✅ Unfollowed user \(creatorId)")
                    
                    // Update local state immediately for better UX
                    await MainActor.run {
                        self.isFollowingCreator = false
                    }
                } else {
                    // Follow the user
                    try await apiClient.followUser(userId: creatorId)
                    print("✅ Followed user \(creatorId)")
                    
                    // Update local state immediately for better UX
                    await MainActor.run {
                        self.isFollowingCreator = true
                    }
                }
                
                // Reload interaction status to ensure consistency
                if let recipeId = recipe.id {
                    let interactions = try await apiClient.getUserInteractions(recipeId: recipeId)
                    await MainActor.run {
                        self.isFollowingCreator = interactions.isFollowingCreator ?? false
                        self.isFollowing = false
                    }
                } else {
                    await MainActor.run {
                        self.isFollowing = false
                    }
                }
            } catch {
                print("❌ Failed to toggle follow: \(error.localizedDescription)")
                await MainActor.run {
                    isFollowing = false
                    // Revert the state change on error
                    // Note: We could also reload the interaction status here to get the correct state
                }
            }
        }
    }
    
    private func updateCounts() {
        // Initialize counts from recipe data
        likesCount = recipe.likesCount ?? 0
        favoritesCount = recipe.favoritesCount ?? 0
        commentsCount = recipe.commentsCount ?? 0
        todoCount = recipe.todoCount ?? 0
        
        // Refresh counts from API
        guard let recipeId = recipe.id else { return }
        
        Task {
            do {
                // Get updated recipe data
                let updatedRecipe = try await apiClient.getRecipe(recipeId: recipeId)
                await MainActor.run {
                    self.likesCount = updatedRecipe.likesCount ?? 0
                    self.favoritesCount = updatedRecipe.favoritesCount ?? 0
                    self.commentsCount = updatedRecipe.commentsCount ?? 0
                    self.todoCount = updatedRecipe.todoCount ?? 0
                }
            } catch {
                print("❌ Failed to update counts: \(error.localizedDescription)")
            }
        }
    }
    
    private func toggleLike() {
        guard let recipeId = recipe.id else { return }
        isLiking = true
        
        Task {
            do {
                if isLiked {
                    try await apiClient.unlikeRecipe(recipeId: recipeId)
                    let newCount = try await apiClient.getRecipeLikes(recipeId: recipeId)
                    await MainActor.run {
                        isLiked = false
                        likesCount = newCount
                        isLiking = false
                    }
                } else {
                    try await apiClient.likeRecipe(recipeId: recipeId)
                    let newCount = try await apiClient.getRecipeLikes(recipeId: recipeId)
                    await MainActor.run {
                        isLiked = true
                        likesCount = newCount
                        isLiking = false
                    }
                }
            } catch {
                print("❌ Failed to toggle like: \(error.localizedDescription)")
                await MainActor.run {
                    isLiking = false
                }
            }
        }
    }
    
    private func toggleFavorite() {
        guard let recipeId = recipe.id else { return }
        isFavoriting = true
        
        // Optimistically update UI
        let wasFavorited = isFavorited
        let oldCount = favoritesCount
        
        // Update UI immediately for better UX
        self.isFavorited = !wasFavorited
        if wasFavorited {
            self.favoritesCount = max(0, oldCount - 1)
        } else {
            self.favoritesCount = oldCount + 1
        }
        
        Task {
            do {
                if wasFavorited {
                    try await apiClient.removeFavorite(recipeId: recipeId)
                    print("✅ Removed from favorites")
                } else {
                    try await apiClient.addFavorite(recipeId: recipeId)
                    print("✅ Added to favorites")
                }
                
                // Get updated recipe to get latest counts
                let updatedRecipe = try await apiClient.getRecipe(recipeId: recipeId)
                
                // Reload interaction status
                let interactions = try await apiClient.getUserInteractions(recipeId: recipeId)
                
                await MainActor.run {
                    self.isFavorited = interactions.isFavorited
                    self.favoritesCount = updatedRecipe.favoritesCount ?? 0
                    self.isFavoriting = false
                    print("✅ Favorites updated: \(self.favoritesCount)")
                }
            } catch {
                print("❌ Failed to toggle favorite: \(error.localizedDescription)")
                await MainActor.run {
                    // Revert optimistic update on error
                    self.isFavorited = wasFavorited
                    self.favoritesCount = oldCount
                    isFavoriting = false
                }
            }
        }
    }
    
    private func toggleTodo() {
        guard let recipeId = recipe.id else { return }
        isTodding = true
        
        Task {
            do {
                if isInTodo {
                    try await apiClient.removeFromTodoList(recipeId: recipeId)
                    print("✅ Removed from todo list")
                } else {
                    try await apiClient.addToTodoList(recipeId: recipeId)
                    print("✅ Added to todo list")
                }
                
                // Get updated recipe to get latest counts
                let updatedRecipe = try await apiClient.getRecipe(recipeId: recipeId)
                
                // Reload interaction status
                let interactions = try await apiClient.getUserInteractions(recipeId: recipeId)
                
                await MainActor.run {
                    self.isInTodo = interactions.isInTodo
                    self.todoCount = updatedRecipe.todoCount ?? 0
                    self.isTodding = false
                    print("✅ Todo updated: \(self.isInTodo), count: \(self.todoCount)")
                }
            } catch {
                print("❌ Failed to toggle todo: \(error.localizedDescription)")
                await MainActor.run {
                    isTodding = false
                }
            }
        }
    }
    
    private func addComment() {
        guard !newComment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard let recipeId = recipe.id else { return }
        
        let commentContent = newComment.trimmingCharacters(in: .whitespacesAndNewlines)
        isAddingComment = true
        
        Task {
            do {
                print("🔍 Creating comment for recipe \(recipeId): \(commentContent)")
                let newCommentObj = try await apiClient.createComment(for: recipeId, content: commentContent)
                print("✅ Comment created successfully")
                
                // Reload comments to get the latest list and count
                let updatedComments = try await apiClient.getComments(for: recipeId)
                
                // Get updated recipe to get latest counts
                let updatedRecipe = try await apiClient.getRecipe(recipeId: recipeId)
                
                await MainActor.run {
                    self.comments = updatedComments
                    self.commentsCount = updatedRecipe.commentsCount ?? updatedComments.count
                    self.newComment = ""
                    self.isAddingComment = false
                    print("✅ Comments updated: \(self.comments.count) comments, count: \(self.commentsCount)")
                }
            } catch {
                print("❌ Failed to create comment: \(error.localizedDescription)")
                print("❌ Error type: \(type(of: error))")
                if let apiError = error as? APIError {
                    print("❌ API Error: \(apiError.localizedDescription)")
                }
                await MainActor.run {
                    isAddingComment = false
                }
            }
        }
    }
}

// MARK: - Detail Card Component
struct DetailCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Comment Model
struct Comment: Identifiable, Codable {
    let id: Int
    let userId: Int
    let recipeId: Int
    let content: String
    let createdAt: Date
    let updatedAt: Date
    let user: CommentUser
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case recipeId = "recipe_id"
        case content
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case user
    }
    
    // Custom decoder to handle date strings
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int.self, forKey: .id)
        userId = try container.decode(Int.self, forKey: .userId)
        recipeId = try container.decode(Int.self, forKey: .recipeId)
        content = try container.decode(String.self, forKey: .content)
        user = try container.decode(CommentUser.self, forKey: .user)
        
        // Handle date decoding
        if let createdAtString = try container.decodeIfPresent(String.self, forKey: .createdAt) {
            let formatter = ISO8601DateFormatter()
            createdAt = formatter.date(from: createdAtString) ?? Date()
        } else {
            createdAt = Date()
        }
        
        if let updatedAtString = try container.decodeIfPresent(String.self, forKey: .updatedAt) {
            let formatter = ISO8601DateFormatter()
            updatedAt = formatter.date(from: updatedAtString) ?? Date()
        } else {
            updatedAt = Date()
        }
    }
}

// MARK: - Comment User Model
struct CommentUser: Codable {
    let id: Int
    let username: String
    let profileImageUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case profileImageUrl = "profile_image_url"
    }
}

// MARK: - Comment Row View
struct CommentRowView: View {
    let comment: Comment
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // User Avatar
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 32, height: 32)
                .overlay(
                    Text(String(comment.user.username.prefix(1)))
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(comment.user.username)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text(comment.createdAt, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(comment.content)
                    .font(.body)
                    .foregroundColor(.primary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Comment Sheet View
struct CommentSheetView: View {
    let recipe: Recipe
    @Binding var comments: [Comment]
    @Environment(\.dismiss) private var dismiss
    @StateObject private var apiClient = APIClient.shared
    
    @State private var newComment = ""
    @State private var isAddingComment = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Comments List
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(comments) { comment in
                            CommentRowView(comment: comment)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                }
                
                // Add Comment Area
                VStack(spacing: 12) {
                    Divider()
                    
                    HStack(spacing: 12) {
                        TextField("Write your comment...", text: $newComment)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Button("Send") {
                            addComment()
                        }
                        .disabled(newComment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isAddingComment)
                        .foregroundColor(newComment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .blue)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
                .background(Color(.systemBackground))
            }
            .navigationTitle("Comments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func addComment() {
        guard !newComment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard let recipeId = recipe.id else { return }
        
        isAddingComment = true
        
        Task {
            do {
                let newCommentObj = try await apiClient.createComment(for: recipeId, content: newComment)
                await MainActor.run {
                    comments.append(newCommentObj)
                    newComment = ""
                    isAddingComment = false
                }
            } catch {
                print("❌ Failed to create comment: \(error.localizedDescription)")
                await MainActor.run {
                    isAddingComment = false
                }
            }
        }
    }
}

#Preview {
    RecipeDetailView(recipe: Recipe(
        title: "Delicious Pasta",
        description: "This is a simple and easy-to-make classic pasta dish, perfect for beginners.",
        recipeType: "Dish",
        cuisineType: "Italian",
        servings: 2,
        difficulty: "Easy"
    ))
    .environmentObject(Library())
}
