//
//  StepDetailView.swift
//  ChefmanApp
//
//  Detailed view for a single cooking step
//

import SwiftUI
import AVKit

// MARK: - Step Detail View
struct StepDetailView: View {
    let step: RecipeStepDisplay
    let recipeTitle: String
    @Environment(\.dismiss) private var dismiss
    @State private var showVideo = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Step Number and Title
                    HStack {
                        ZStack {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 50, height: 50)
                            
                            Text("\(step.stepNumber)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Step \(step.stepNumber)")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text(recipeTitle)
                                .font(.subheadline)
                                .foregroundColor(.blue)
                                .lineLimit(2)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    
                    // Step Image
                    if let imageUrl = step.imageUrl, !imageUrl.isEmpty {
                        AsyncImage(url: URL(string: imageUrl)) { phase in
                            switch phase {
                            case .empty:
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: 250)
                                    .overlay(
                                        ProgressView()
                                    )
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(height: 250)
                                    .clipped()
                                    .cornerRadius(12)
                            case .failure:
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: 250)
                                    .overlay(
                                        Image(systemName: "photo")
                                            .font(.system(size: 50))
                                            .foregroundColor(.gray)
                                    )
                            @unknown default:
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: 250)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 16)
                    }
                    
                    // Step Description
                    VStack(alignment: .leading, spacing: 16) {
                        Text(step.description)
                            .font(.body)
                            .lineSpacing(6)
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        // Step Details
                        VStack(alignment: .leading, spacing: 12) {
                            if let duration = step.duration, !duration.isEmpty {
                                HStack(spacing: 8) {
                                    Image(systemName: "clock")
                                        .foregroundColor(.blue)
                                    Text("Duration: \(duration)")
                                        .font(.subheadline)
                                }
                            }
                            
                            if let temperature = step.temperature, !temperature.isEmpty {
                                HStack(spacing: 8) {
                                    Image(systemName: "thermometer")
                                        .foregroundColor(.orange)
                                    Text("Temperature: \(temperature)")
                                        .font(.subheadline)
                                }
                            }
                            
                            if let notes = step.notes, !notes.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Notes:")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    Text(notes)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .italic()
                                }
                                .padding(.top, 4)
                            }
                        }
                        .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Video Section
                    if let videoUrl = step.videoUrl, !videoUrl.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Video Guide")
                                .font(.headline)
                                .padding(.horizontal, 16)
                            
                            Button(action: {
                                showVideo = true
                            }) {
                                HStack {
                                    Image(systemName: "play.circle.fill")
                                        .font(.title)
                                    Text("Play Video")
                                        .font(.headline)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                            }
                            .padding(.horizontal, 16)
                        }
                        .padding(.top, 8)
                    }
                    
                    Spacer(minLength: 20)
                }
                .frame(maxWidth: .infinity)
            }
            .navigationTitle("Step \(step.stepNumber)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .fullScreenCover(isPresented: $showVideo) {
                if let videoUrl = step.videoUrl, !videoUrl.isEmpty {
                    VideoPlayerView(videoURL: videoUrl)
                }
            }
        }
    }
}

