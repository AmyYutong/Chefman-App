//
//  StepByStepView.swift
//  ChefmanApp
//
//  Step-by-step cooking guide with videos
//

import SwiftUI
import AVKit

// MARK: - Step By Step View
struct StepByStepView: View {
    let recipe: Recipe
    let initialStepIndex: Int?
    @Environment(\.dismiss) private var dismiss
    @State private var currentStepIndex: Int = 0
    @State private var steps: [RecipeStepDisplay] = []
    @State private var selectedStepIndex: Int? = nil
    @State private var showStepDetail = false
    
    init(recipe: Recipe, initialStepIndex: Int? = nil) {
        self.recipe = recipe
        self.initialStepIndex = initialStepIndex
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if steps.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "list.bullet.rectangle")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    Text("No steps available")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Steps List View (Left side or top on smaller screens)
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                            StepListItemView(
                                step: step,
                                stepNumber: index + 1,
                                isSelected: currentStepIndex == index,
                                hasVideo: step.videoUrl != nil && !step.videoUrl!.isEmpty,
                                hasImage: step.imageUrl != nil && !step.imageUrl!.isEmpty
                            )
                            .onTapGesture {
                                withAnimation {
                                    currentStepIndex = index
                                }
                            }
                        }
                    }
                    .padding()
                }
                .frame(maxWidth: .infinity)
                
                Divider()
                
                // Step Detail View (Right side or bottom)
                TabView(selection: $currentStepIndex) {
                    ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                        RecipeStepCardView(step: step, stepNumber: index + 1, totalSteps: steps.count)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page)
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                .frame(height: UIScreen.main.bounds.height * 0.6)
            }
        }
        .navigationTitle("Step by Step")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Close") {
                    dismiss()
                }
            }
        }
        .onAppear {
            loadStepsFromRecipe()
            // Set initial step index if provided
            if let initialIndex = initialStepIndex {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    currentStepIndex = initialIndex
                }
            }
        }
    }
    
    private func loadStepsFromRecipe() {
        // Use steps from recipe object directly (much faster!)
        if let recipeSteps = recipe.steps, !recipeSteps.isEmpty {
            self.steps = recipeSteps.map { step in
                RecipeStepDisplay(
                    stepNumber: step.stepNumber,
                    description: step.description,
                    duration: step.duration,
                    temperature: step.temperature,
                    notes: step.notes,
                    imageUrl: step.imageUrl,
                    videoUrl: step.videoUrl
                )
            }
        } else {
            // Fallback: try to load from API if steps not in recipe
            loadStepsFromAPI()
        }
    }
    
    private func loadStepsFromAPI() {
        Task {
            do {
                guard let recipeId = recipe.id else { return }
                let fullRecipe = try await APIClient.shared.getRecipe(recipeId: recipeId)
                await MainActor.run {
                    if let recipeSteps = fullRecipe.steps, !recipeSteps.isEmpty {
                        self.steps = recipeSteps.map { step in
                            RecipeStepDisplay(
                                stepNumber: step.stepNumber,
                                description: step.description,
                                duration: step.duration,
                                temperature: step.temperature,
                                notes: step.notes,
                                imageUrl: step.imageUrl,
                                videoUrl: step.videoUrl
                            )
                        }
                    }
                }
            } catch {
                print("❌ Failed to load steps: \(error)")
            }
        }
    }
}

// MARK: - Step Card View
struct RecipeStepCardView: View {
    let step: RecipeStepDisplay
    let stepNumber: Int
    let totalSteps: Int
    @State private var showVideo = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Step Number Badge
                HStack {
                    Text("Step \(stepNumber) of \(totalSteps)")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.green)
                        .cornerRadius(20)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                // Step Image or Video Thumbnail
                if let imageUrl = step.imageUrl, !imageUrl.isEmpty {
                    AsyncImage(url: URL(string: imageUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay(ProgressView())
                    }
                    .frame(height: 300)
                    .cornerRadius(12)
                    .padding(.horizontal)
                } else if let videoUrl = step.videoUrl, !videoUrl.isEmpty {
                    VideoThumbnailView(videoURL: videoUrl)
                        .frame(height: 300)
                        .cornerRadius(12)
                        .padding(.horizontal)
                        .onTapGesture {
                            showVideo = true
                        }
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 200)
                        .cornerRadius(12)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                        )
                        .padding(.horizontal)
                }
                
                // Step Description
                VStack(alignment: .leading, spacing: 12) {
                    Text(step.description)
                        .font(.body)
                        .lineSpacing(4)
                    
                    // Step Details
                    if let duration = step.duration, !duration.isEmpty {
                        HStack {
                            Image(systemName: "clock")
                            Text("Duration: \(duration)")
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    }
                    
                    if let temperature = step.temperature, !temperature.isEmpty {
                        HStack {
                            Image(systemName: "thermometer")
                            Text("Temperature: \(temperature)")
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    }
                    
                    if let notes = step.notes, !notes.isEmpty {
                        Text(notes)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .italic()
                            .padding(.top, 4)
                    }
                }
                .padding(.horizontal)
                
                // Video Play Button
                if let videoUrl = step.videoUrl, !videoUrl.isEmpty {
                    Button(action: {
                        showVideo = true
                    }) {
                        HStack {
                            Image(systemName: "play.circle.fill")
                                .font(.title)
                            Text("Watch Video")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .sheet(isPresented: $showVideo) {
                        VideoPlayerView(videoURL: videoUrl)
                    }
                }
                
                Spacer()
            }
        }
    }
}

// MARK: - Video Thumbnail View
struct VideoThumbnailView: View {
    let videoURL: String
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
            
            VStack {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.white)
                Text("Tap to play video")
                    .font(.caption)
                    .foregroundColor(.white)
            }
        }
    }
}

// MARK: - Video Player View
struct VideoPlayerView: View {
    let videoURL: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                if let url = URL(string: videoURL) {
                    VideoPlayer(player: AVPlayer(url: url))
                } else {
                    VStack {
                        Text("Invalid video URL")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Step Video")
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
}

// MARK: - Step List Item View
struct StepListItemView: View {
    let step: RecipeStepDisplay
    let stepNumber: Int
    let isSelected: Bool
    let hasVideo: Bool
    let hasImage: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Step Number
            ZStack {
                Circle()
                    .fill(isSelected ? Color.green : Color.gray.opacity(0.3))
                    .frame(width: 40, height: 40)
                
                Text("\(stepNumber)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            
            // Step Info
            VStack(alignment: .leading, spacing: 4) {
                Text(step.description)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                HStack(spacing: 8) {
                    if hasVideo {
                        Label("Video", systemImage: "play.circle.fill")
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }
                    if hasImage {
                        Label("Image", systemImage: "photo.fill")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
                    if let duration = step.duration, !duration.isEmpty {
                        Label(duration, systemImage: "clock")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Selection Indicator
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(isSelected ? Color.green.opacity(0.1) : Color.gray.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.green : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - Recipe Step Response Model (for API decoding)
struct RecipeStepResponse: Codable {
    let id: Int?
    let step_number: Int
    let description: String
    let duration: String?
    let temperature: String?
    let notes: String?
    let image_url: String?
    let video_url: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case step_number
        case description
        case duration
        case temperature
        case notes
        case image_url
        case video_url
    }
}


