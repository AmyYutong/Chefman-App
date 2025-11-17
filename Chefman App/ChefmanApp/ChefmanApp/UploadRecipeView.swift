//
//  UploadRecipeView.swift
//  ChefmanApp
//
//  Created by 杨雨桐 on 9/14/25.
//

import SwiftUI
import PhotosUI

// MARK: - Recipe Types
enum RecipeType: String, CaseIterable {
    case bakery = "Bakery"
    case dish = "Dish"
    
    var systemImage: String {
        switch self {
        case .bakery: return "birthday.cake"
        case .dish: return "fork.knife"
        }
    }
}

// MARK: - Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    let sourceType: UIImagePickerController.SourceType
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

    // MARK: - Recipe Steps Editor View
    struct RecipeStepsEditorView: View {
        @Environment(\.dismiss) private var dismiss
        @Binding var recipeSteps: [RecipeStep]
        @State private var showAddStep = false
        
        var body: some View {
            NavigationView {
                VStack(spacing: 0) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recipe Steps")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("Add detailed cooking instructions with photos and videos")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    
                    // Steps List
                    if recipeSteps.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "list.bullet.clipboard")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            
                            Text("No steps added yet")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text("Tap the + button to add your first cooking step")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.gray.opacity(0.05))
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(recipeSteps.indices, id: \.self) { index in
                                    StepCardView(step: $recipeSteps[index], stepIndex: index, onDelete: {
                                        removeStep(at: index)
                                    })
                                }
                            }
                            .padding()
                        }
                    }
                    
                    // Add Step Button
                    VStack {
                        Button(action: {
                            addNewStep()
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add Step")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                        }
                        .padding()
                    }
                    .background(Color.white)
                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: -2)
                }
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarBackButtonHidden(true)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
        }
        
        private func addNewStep() {
            let newStepNumber = recipeSteps.count + 1
            recipeSteps.append(RecipeStep(stepNumber: newStepNumber))
        }
        
        private func removeStep(at index: Int) {
            recipeSteps.remove(at: index)
            // Renumber remaining steps
            for i in 0..<recipeSteps.count {
                recipeSteps[i].stepNumber = i + 1
            }
        }
    }
    
    // MARK: - Step Card View
    struct StepCardView: View {
        @Binding var step: RecipeStep
        let stepIndex: Int
        let onDelete: () -> Void
        @State private var showStepDetail = false
        
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                // Step Header
                HStack {
                    Text("Step \(step.stepNumber)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    
                    Spacer()
                    
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                }
                
                // Step Description Preview
                if !step.description.isEmpty {
                    Text(step.description)
                        .font(.body)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                } else {
                    Text("Tap to add step details")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .italic()
                }
                
                // Media Preview
                if step.stepImage != nil || step.stepVideoURL != nil {
                    HStack(spacing: 8) {
                        if step.stepImage != nil {
                            HStack(spacing: 4) {
                                Image(systemName: "photo")
                                    .foregroundColor(.blue)
                                Text("Photo")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        if step.stepVideoURL != nil {
                            HStack(spacing: 4) {
                                Image(systemName: "video")
                                    .foregroundColor(.green)
                                Text("Video")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }
                        
                        Spacer()
                    }
                }
                
                // Duration and Temperature
                if !step.duration.isEmpty || !step.temperature.isEmpty {
                    HStack {
                        if !step.duration.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .foregroundColor(.orange)
                                Text(step.duration)
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }
                        
                        if !step.temperature.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "thermometer")
                                    .foregroundColor(.red)
                                Text(step.temperature)
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        
                        Spacer()
                    }
                }
                
                // Edit Button
                Button(action: {
                    showStepDetail = true
                }) {
                    HStack {
                        Image(systemName: "pencil")
                        Text("Edit Details")
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
            .sheet(isPresented: $showStepDetail) {
                StepDetailEditorView(step: $step)
            }
        }
    }
    
    // MARK: - Step Detail Editor View
    struct StepDetailEditorView: View {
        @Environment(\.dismiss) private var dismiss
        @Binding var step: RecipeStep
        @State private var showImagePicker = false
        @State private var showCamera = false
        @State private var showVideoPicker = false
        @State private var showPhotoActionSheet = false
        
        var body: some View {
            NavigationView {
                ScrollView {
                    VStack(spacing: 24) {
                        // Step Header
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Step \(step.stepNumber)")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text("Add detailed instructions for this step")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Step Description
                        VStack(alignment: .leading, spacing: 12) {
                            Text("What to do:")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            TextField("Describe this step in detail...", text: $step.description, axis: .vertical)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .font(.body)
                                .lineLimit(3...8)
                        }
                        
                        // Duration and Temperature
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Duration")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                
                                TextField("e.g., 5 minutes", text: $step.duration)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .font(.body)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Temperature")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                
                                TextField("e.g., 180°C", text: $step.temperature)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .font(.body)
                            }
                        }
                        
                        // Media Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Add Media")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            HStack(spacing: 16) {
                                // Photo Preview
                                if let stepImage = step.stepImage {
                                    Image(uiImage: stepImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 100, height: 100)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                } else {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(width: 100, height: 100)
                                        .overlay(
                                            VStack {
                                                Image(systemName: "photo")
                                                    .font(.title2)
                                                Text("Photo")
                                                    .font(.caption)
                                            }
                                            .foregroundColor(.gray)
                                        )
                                }
                                
                                // Video Preview
                                if step.stepVideoURL != nil {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.blue.opacity(0.2))
                                        .frame(width: 100, height: 100)
                                        .overlay(
                                            VStack {
                                                Image(systemName: "play.circle.fill")
                                                    .font(.title2)
                                                Text("Video")
                                                    .font(.caption)
                                            }
                                            .foregroundColor(.blue)
                                        )
                                } else {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(width: 100, height: 100)
                                        .overlay(
                                            VStack {
                                                Image(systemName: "video")
                                                    .font(.title2)
                                                Text("Video")
                                                    .font(.caption)
                                            }
                                            .foregroundColor(.gray)
                                        )
                                }
                                
                                Spacer()
                            }
                            
                            // Media Buttons
                            HStack(spacing: 12) {
                                Button(action: {
                                    showPhotoActionSheet = true
                                }) {
                                    HStack {
                                        Image(systemName: "camera")
                                        Text("Add Photo")
                                    }
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color.blue)
                                    .cornerRadius(8)
                                }
                                
                                Button(action: {
                                    showVideoPicker = true
                                }) {
                                    HStack {
                                        Image(systemName: "video")
                                        Text("Add Video")
                                    }
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color.green)
                                    .cornerRadius(8)
                                }
                                
                                Spacer()
                            }
                            
                            // Remove Media Buttons
                            if step.stepImage != nil || step.stepVideoURL != nil {
                                HStack(spacing: 12) {
                                    if step.stepImage != nil {
                                        Button(action: {
                                            step.stepImage = nil
                                        }) {
                                            HStack {
                                                Image(systemName: "trash")
                                                Text("Remove Photo")
                                            }
                                            .font(.caption)
                                            .foregroundColor(.red)
                                        }
                                    }
                                    
                                    if step.stepVideoURL != nil {
                                        Button(action: {
                                            step.stepVideoURL = nil
                                        }) {
                                            HStack {
                                                Image(systemName: "trash")
                                                Text("Remove Video")
                                            }
                                            .font(.caption)
                                            .foregroundColor(.red)
                                        }
                                    }
                                    
                                    Spacer()
                                }
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(12)
                    }
                    .padding()
                }
                .navigationTitle("Edit Step")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarBackButtonHidden(true)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Save") {
                            dismiss()
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(selectedImage: $step.stepImage, sourceType: .photoLibrary)
            }
            .sheet(isPresented: $showCamera) {
                ImagePicker(selectedImage: $step.stepImage, sourceType: .camera)
            }
            .sheet(isPresented: $showVideoPicker) {
                VideoPicker(selectedVideoURL: $step.stepVideoURL)
            }
            .actionSheet(isPresented: $showPhotoActionSheet) {
                ActionSheet(
                    title: Text("Select Photo"),
                    buttons: [
                        .default(Text("Camera")) {
                            showCamera = true
                        },
                        .default(Text("Photo Library")) {
                            showImagePicker = true
                        },
                        .cancel()
                    ]
                )
            }
        }
    }

// MARK: - Video Picker
struct VideoPicker: UIViewControllerRepresentable {
    @Binding var selectedVideoURL: URL?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.mediaTypes = ["public.movie"]
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: VideoPicker
        
        init(_ parent: VideoPicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let videoURL = info[.mediaURL] as? URL {
                parent.selectedVideoURL = videoURL
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}


// MARK: - Cuisine Types
enum CuisineType: String, CaseIterable {
    case chinese = "Chinese"
    case italian = "Italian"
    case french = "French"
    case japanese = "Japanese"
    case korean = "Korean"
    case mexican = "Mexican"
    case indian = "Indian"
    case american = "American"
    case other = "Other"
}

// MARK: - Ingredient Model
struct Ingredient: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var amount: String
    var unit: String
    
    init(name: String = "", amount: String = "", unit: String = "g") {
        self.name = name
        self.amount = amount
        self.unit = unit
    }
}

// MARK: - Equipment Model
struct Equipment: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var brand: String
    var isChefman: Bool
    
    init(name: String = "", brand: String = "", isChefman: Bool = false) {
        self.name = name
        self.brand = brand
        self.isChefman = isChefman
    }
}

// MARK: - Recipe Step Model
struct RecipeStep: Identifiable, Hashable {
    let id = UUID()
    var stepNumber: Int
    var description: String
    var duration: String // e.g., "5 minutes", "until golden brown"
    var temperature: String // e.g., "180°C", "medium heat"
    var stepImage: UIImage? // Photo for this step
    var stepVideoURL: URL? // Video for this step
    
    init(stepNumber: Int, description: String = "", duration: String = "", temperature: String = "", stepImage: UIImage? = nil, stepVideoURL: URL? = nil) {
        self.stepNumber = stepNumber
        self.description = description
        self.duration = duration
        self.temperature = temperature
        self.stepImage = stepImage
        self.stepVideoURL = stepVideoURL
    }
}

// MARK: - Upload Recipe View
struct UploadRecipeView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var library: Library
    @StateObject private var apiClient = APIClient.shared
    
    // Basic Info
    @State private var title = ""
    @State private var imageUrl = ""
    @State private var recipeType: RecipeType = .dish
    @State private var cuisineType: CuisineType = .chinese
    
    // Equipment
    @State private var isChefmanUser = false
    @State private var equipment: [Equipment] = [Equipment()]
    
    // Ingredients
    @State private var ingredients: [Ingredient] = [Ingredient()]
    
    // Recipe Steps
    @State private var recipeSteps: [RecipeStep] = [RecipeStep(stepNumber: 1)]
    @State private var showStepEditor = false
    @State private var editingStepIndex = 0
    
    // Additional recipe fields
    @State private var prepTime = ""
    @State private var cookTime = ""
    @State private var totalTime = ""
    @State private var servings = 1
    @State private var difficulty = "Easy"
    
    // Photo Selection
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    @State private var showCamera = false
    @State private var showPhotoActionSheet = false
    @State private var uploadedImageUrl: String?
    @State private var isUploadingImage = false
    
    // UI State
    @State private var isUploading = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var showSuccessBanner = false
    @State private var successMessage = "Recipe created successfully!"
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Create Recipe")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("Share your delicious recipe with the community")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    // Form Sections
                    VStack(spacing: 24) {
                        // Basic Information
                        basicInfoSection
                        
                        // Recipe Type & Cuisine
                        typeAndCuisineSection
                        
                        // Equipment Section
                        equipmentSection
                        
                        // Ingredients Section
                        ingredientsSection
                        
                        // Recipe Steps Section
                        recipeStepsSection
                        
                        // Preview
                        if !title.isEmpty {
                            recipePreview
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 40)
                }
            }
            .navigationTitle("Create Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.red)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        uploadRecipe()
                    }
                    .disabled(title.isEmpty || isUploading)
                    .foregroundColor(title.isEmpty ? .gray : .blue)
                }
            }
            .overlay {
                if isUploading {
                    uploadingOverlay
                }
            }
            .overlay(alignment: .top) {
                if showSuccessBanner {
                    SuccessBannerView(message: successMessage)
                        .padding(.top, 16)
                        .padding(.horizontal, 20)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showSuccessBanner)
                }
            }
            .alert("Error", isPresented: $showErrorAlert) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Basic Info Section
    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Basic Information")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                // Recipe Title
                VStack(alignment: .leading, spacing: 6) {
                    Text("Recipe Name")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    TextField("Enter recipe name", text: $title)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.body)
                }
                
                // Recipe Photo
                VStack(alignment: .leading, spacing: 6) {
                    Text("Recipe Photo")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 12) {
                        // Image Preview
                        if let selectedImage = selectedImage {
                            Image(uiImage: selectedImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        } else {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Image(systemName: "photo")
                                        .foregroundColor(.gray)
                                )
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Button(action: {
                                showPhotoActionSheet = true
                            }) {
                                HStack {
                                    Image(systemName: "camera")
                                    Text("Add Photo")
                                }
                                .font(.subheadline)
                                .foregroundColor(.blue)
                            }
                            
                            if isUploadingImage {
                                HStack {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text("Uploading...")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            } else if uploadedImageUrl != nil {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text("Uploaded")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                }
                            }
                            
                            if selectedImage != nil {
                                Button(action: {
                                    selectedImage = nil
                                    selectedPhoto = nil
                                }) {
                                    HStack {
                                        Image(systemName: "trash")
                                        Text("Remove")
                                    }
                                    .font(.caption)
                                    .foregroundColor(.red)
                                }
                            }
                        }
                        
                        Spacer()
                    }
                }
                
                // Image URL (Alternative)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Image URL (Alternative)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    TextField("https://example.com/image.jpg", text: $imageUrl)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.body)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(selectedImage: $selectedImage, sourceType: .photoLibrary)
        }
        .sheet(isPresented: $showCamera) {
            ImagePicker(selectedImage: $selectedImage, sourceType: .camera)
        }
        .actionSheet(isPresented: $showPhotoActionSheet) {
            ActionSheet(
                title: Text("Select Photo"),
                buttons: [
                    .default(Text("Camera")) {
                        showCamera = true
                    },
                    .default(Text("Photo Library")) {
                        showImagePicker = true
                    },
                    .cancel()
                ]
            )
        }
        .onChange(of: selectedPhoto) { _, newValue in
            Task {
                if let data = try? await newValue?.loadTransferable(type: Data.self) {
                    if let uiImage = UIImage(data: data) {
                        selectedImage = uiImage
                        await uploadImageToServer(uiImage)
                    }
                }
            }
        }
        .sheet(isPresented: $showStepEditor) {
            RecipeStepsEditorView(recipeSteps: $recipeSteps)
        }
    }
    
    // MARK: - Type and Cuisine Section
    private var typeAndCuisineSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recipe Type & Cuisine")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 16) {
                // Recipe Type
                VStack(alignment: .leading, spacing: 8) {
                    Text("Type")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 12) {
                        ForEach(RecipeType.allCases, id: \.self) { type in
                            Button(action: {
                                recipeType = type
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: type.systemImage)
                                    Text(type.rawValue)
                                }
                                .font(.subheadline)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(recipeType == type ? Color.blue : Color.gray.opacity(0.2))
                                .foregroundColor(recipeType == type ? .white : .primary)
                                .cornerRadius(8)
                            }
                        }
                    }
                }
                
                // Cuisine Type
                VStack(alignment: .leading, spacing: 8) {
                    Text("Cuisine")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Menu {
                        ForEach(CuisineType.allCases, id: \.self) { cuisine in
                            Button(cuisine.rawValue) {
                                cuisineType = cuisine
                            }
                        }
                    } label: {
                        HStack {
                            Text(cuisineType.rawValue)
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
    
    // MARK: - Equipment Section
    private var equipmentSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Kitchen Equipment")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                // Chefman User Question
                VStack(alignment: .leading, spacing: 8) {
                    Text("Are you using Chefman products?")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 16) {
                        Button(action: { isChefmanUser = true }) {
                            HStack {
                                Image(systemName: isChefmanUser ? "checkmark.circle.fill" : "circle")
                                Text("Yes")
                            }
                            .foregroundColor(isChefmanUser ? .blue : .secondary)
                        }
                        
                        Button(action: { isChefmanUser = false }) {
                            HStack {
                                Image(systemName: !isChefmanUser ? "checkmark.circle.fill" : "circle")
                                Text("No")
                            }
                            .foregroundColor(!isChefmanUser ? .blue : .secondary)
                        }
                        
                        Spacer()
                    }
                }
                
                // Equipment List
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Equipment Used")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Button("+ Add Equipment") {
                            equipment.append(Equipment())
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                    
                    ForEach(equipment.indices, id: \.self) { index in
                        equipmentRow(for: index)
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
    
    // MARK: - Equipment Row
    private func equipmentRow(for index: Int) -> some View {
        HStack(spacing: 8) {
            TextField("Equipment name", text: $equipment[index].name)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .font(.body)
            
            if !isChefmanUser {
                TextField("Brand", text: $equipment[index].brand)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.body)
            }
            
            Button(action: {
                equipment.remove(at: index)
            }) {
                Image(systemName: "minus.circle.fill")
                    .foregroundColor(.red)
            }
        }
    }
    
    // MARK: - Ingredients Section
    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Ingredients")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                HStack {
                    Text("Add your ingredients with precise measurements")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button("+ Add Ingredient") {
                        ingredients.append(Ingredient())
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
                
                ForEach(ingredients.indices, id: \.self) { index in
                    ingredientRow(for: index)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
    
    // MARK: - Ingredient Row
    private func ingredientRow(for index: Int) -> some View {
        HStack(spacing: 8) {
            TextField("Ingredient", text: $ingredients[index].name)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .font(.body)
            
            TextField("Amount", text: $ingredients[index].amount)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .font(.body)
                .keyboardType(.decimalPad)
                .frame(width: 80)
            
            Menu {
                ForEach(["g", "kg", "ml", "L", "tsp", "tbsp", "cup", "piece"], id: \.self) { unit in
                    Button(unit) {
                        ingredients[index].unit = unit
                    }
                }
            } label: {
                Text(ingredients[index].unit)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(6)
            }
            
            Button(action: {
                ingredients.remove(at: index)
            }) {
                Image(systemName: "minus.circle.fill")
                    .foregroundColor(.red)
            }
        }
    }
    
        // MARK: - Recipe Steps Section
        private var recipeStepsSection: some View {
            VStack(alignment: .leading, spacing: 16) {
                Text("Recipe Steps")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                VStack(spacing: 12) {
                    HStack {
                        Text("Add detailed cooking instructions")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Button("Edit Steps") {
                            showStepEditor = true
                        }
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .cornerRadius(8)
                    }
                    
                    // Steps Summary
                    if !recipeSteps.isEmpty && recipeSteps.first?.description != "" {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Steps Summary:")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            ForEach(recipeSteps.filter { !$0.description.isEmpty }, id: \.id) { step in
                                HStack {
                                    Text("Step \(step.stepNumber):")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.blue)
                                    
                                    Text(step.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                    
                                    Spacer()
                                }
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(8)
                        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                    } else {
                        Text("No steps added yet. Tap 'Edit Steps' to add cooking instructions.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .italic()
                    }
                }
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
        }
    
    
    
    // MARK: - Recipe Preview
    private var recipePreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Preview")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 12) {
                // Title and Type
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        HStack(spacing: 8) {
                            Label(recipeType.rawValue, systemImage: recipeType.systemImage)
                                .font(.caption)
                                .foregroundColor(.blue)
                            
                            Label(cuisineType.rawValue, systemImage: "globe")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                    
                    Spacer()
                }
                
                // Image
                if !imageUrl.isEmpty {
                    AsyncImage(url: URL(string: imageUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundColor(.gray)
                            )
                    }
                    .frame(height: 120)
                    .clipped()
                    .cornerRadius(8)
                }
                
                // Equipment Summary
                if !equipment.isEmpty && equipment.first?.name != "" {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Equipment:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        ForEach(equipment.filter { !$0.name.isEmpty }, id: \.id) { equipment in
                            HStack {
                                Text("• \(equipment.name)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                if !equipment.brand.isEmpty {
                                    Text("(\(equipment.brand))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                if equipment.isChefman {
                                    Text("Chefman")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 2)
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(4)
                                }
                            }
                        }
                    }
                }
                
                // Ingredients Summary
                if !ingredients.isEmpty && ingredients.first?.name != "" {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Ingredients:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        ForEach(ingredients.filter { !$0.name.isEmpty }, id: \.id) { ingredient in
                            HStack {
                                Text("• \(ingredient.name)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                if !ingredient.amount.isEmpty {
                                    Text("\(ingredient.amount) \(ingredient.unit)")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
                
                // Recipe Steps Summary
                if !recipeSteps.isEmpty && recipeSteps.first?.description != "" {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Cooking Steps:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        ForEach(recipeSteps.filter { !$0.description.isEmpty }, id: \.id) { step in
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text("Step \(step.stepNumber):")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.blue)
                                    
                                    if !step.duration.isEmpty {
                                        Text("(\(step.duration))")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    if !step.temperature.isEmpty {
                                        Text("at \(step.temperature)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Text(step.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }
                        }
                    }
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Uploading Overlay
    private var uploadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.2)
                
                Text("Creating Recipe...")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(24)
            .background(Color.black.opacity(0.8))
            .cornerRadius(16)
        }
    }
    
    // MARK: - Upload Function
    private func uploadRecipe() {
        guard !title.isEmpty else { return }
        
        isUploading = true
        
        // Create detailed description from all the information
        let detailedDescription = createDetailedDescription()
        
        // Convert ingredients to RecipeIngredientData
        // Filter out empty ingredients
        let ingredientData = ingredients
            .filter { !$0.name.isEmpty }
            .map { ingredient in
                RecipeIngredientData(
                    ingredient_name: ingredient.name,
                    amount: ingredient.amount.isEmpty ? nil : ingredient.amount,
                    unit: ingredient.unit.isEmpty ? nil : ingredient.unit,
                    notes: nil
                )
            }
        
        // Validate that we have at least one ingredient and one step
        guard !ingredientData.isEmpty else {
            errorMessage = "Please add at least one ingredient"
            showErrorAlert = true
            isUploading = false
            return
        }
        
        let validSteps = recipeSteps.filter { !$0.description.isEmpty }
        guard !validSteps.isEmpty else {
            errorMessage = "Please add at least one cooking step"
            showErrorAlert = true
            isUploading = false
            return
        }
        
        // Upload step images first, then create recipe with image URLs
        Task {
            do {
                // Upload all step images
                var stepImageUrls: [Int: String] = [:]
                for step in validSteps {
                    if let stepImage = step.stepImage {
                        print("📤 Uploading image for step \(step.stepNumber)...")
                        let uploadResponse = try await apiClient.uploadImage(image: stepImage, category: "steps")
                        // Use originalUrl from ImageInfo (not optional, so no ? needed)
                        stepImageUrls[step.stepNumber] = uploadResponse.image.originalUrl
                        print("✅ Step \(step.stepNumber) image uploaded: \(uploadResponse.image.originalUrl)")
                    }
                }
                
                // Convert steps to RecipeStepData with uploaded image URLs
                let stepData = validSteps.map { step in
                    RecipeStepData(
                        step_number: step.stepNumber,
                        description: step.description,
                        duration: step.duration.isEmpty ? nil : step.duration,
                        temperature: step.temperature.isEmpty ? nil : step.temperature,
                        notes: nil,
                        image_url: stepImageUrls[step.stepNumber],  // Use uploaded image URL
                        video_url: step.stepVideoURL?.absoluteString  // Video URL (can be local or remote)
                    )
                }
        
                // Convert equipment to RecipeEquipmentData
                // Filter out empty equipment
                let equipmentData = equipment
                    .filter { !$0.name.isEmpty }
                    .map { equip in
                        RecipeEquipmentData(
                            equipment_name: equip.name,
                            brand: equip.brand.isEmpty ? nil : equip.brand,
                            is_chefman: equip.isChefman
                        )
                    }
                
                // Create RecipeCreateData
                // Convert empty strings to nil for optional fields
                let recipeData = RecipeCreateData(
                    title: title,
                    description: detailedDescription.isEmpty ? nil : detailedDescription,
                    image_url: uploadedImageUrl ?? (imageUrl.isEmpty ? nil : imageUrl),
                    recipe_type: recipeType.rawValue,
                    cuisine_type: cuisineType.rawValue,
                    prep_time: prepTime.isEmpty ? nil : prepTime,
                    cook_time: cookTime.isEmpty ? nil : cookTime,
                    total_time: totalTime.isEmpty ? nil : totalTime,
                    servings: servings,
                    difficulty: difficulty,
                    ingredients: ingredientData,
                    steps: stepData,
                    equipment: equipmentData
                )
                
                // Debug: Print recipe data summary
                print("🔍 Recipe Data Summary:")
                print("  - Title: \(recipeData.title)")
                print("  - Description: \(recipeData.description ?? "nil")")
                print("  - Image URL: \(recipeData.image_url ?? "nil")")
                print("  - Recipe Type: \(recipeData.recipe_type)")
                print("  - Cuisine Type: \(recipeData.cuisine_type)")
                print("  - Ingredients: \(recipeData.ingredients.count)")
                print("  - Steps: \(recipeData.steps.count)")
                for (index, step) in recipeData.steps.enumerated() {
                    print("    Step \(index + 1):")
                    print("      - Description: \(step.description)")
                    print("      - Image URL: \(step.image_url ?? "nil")")
                    print("      - Video URL: \(step.video_url ?? "nil")")
                }
                print("  - Equipment: \(recipeData.equipment.count)")
                
                let recipe = try await apiClient.createRecipe(recipeData: recipeData)
                
                await MainActor.run {
                    isUploading = false
                    successMessage = "Recipe created successfully!"
                    withAnimation {
                        showSuccessBanner = true
                    }
                    print("✅ Recipe created successfully: \(recipe.title)")
                    // Refresh the library to show the new recipe
                    library.loadRecipes()
                    // Reset form after successful upload
                    resetForm()
                    scheduleDismissal()
                }
            } catch {
                print("❌ Failed to upload recipe: \(error.localizedDescription)")
                await MainActor.run {
                    isUploading = false
                    errorMessage = "Failed to upload recipe: \(error.localizedDescription)"
                    showErrorAlert = true
                }
            }
        }
    }
    
    // MARK: - Reset Form
    private func resetForm() {
        title = ""
        imageUrl = ""
        recipeType = .dish
        cuisineType = .chinese
        ingredients = [Ingredient()]
        recipeSteps = [RecipeStep(stepNumber: 1)]
        equipment = [Equipment()]
        prepTime = ""
        cookTime = ""
        totalTime = ""
        servings = 1
        difficulty = "Easy"
        uploadedImageUrl = nil
        selectedImage = nil
    }
    
    // MARK: - Create Detailed Description
    private func createDetailedDescription() -> String {
        var description = ""
        
        // Recipe Type and Cuisine
        description += "**Recipe Type:** \(recipeType.rawValue)\n"
        description += "**Cuisine:** \(cuisineType.rawValue)\n\n"
        
        // Equipment
        if !equipment.isEmpty && equipment.first?.name != "" {
            description += "**Equipment Used:**\n"
            for equipment in equipment.filter({ !$0.name.isEmpty }) {
                if equipment.isChefman {
                    description += "• \(equipment.name) (Chefman)\n"
                } else if !equipment.brand.isEmpty {
                    description += "• \(equipment.name) (\(equipment.brand))\n"
                } else {
                    description += "• \(equipment.name)\n"
                }
            }
            description += "\n"
        }
        
        // Ingredients
        if !ingredients.isEmpty && ingredients.first?.name != "" {
            description += "**Ingredients:**\n"
            for ingredient in ingredients.filter({ !$0.name.isEmpty }) {
                if !ingredient.amount.isEmpty {
                    description += "• \(ingredient.name): \(ingredient.amount) \(ingredient.unit)\n"
                } else {
                    description += "• \(ingredient.name)\n"
                }
            }
            description += "\n"
        }
        
        // Recipe Steps
        if !recipeSteps.isEmpty && recipeSteps.first?.description != "" {
            description += "**Cooking Instructions:**\n"
            for step in recipeSteps.filter({ !$0.description.isEmpty }) {
                description += "**Step \(step.stepNumber):** \(step.description)"
                
                if !step.duration.isEmpty {
                    description += " (Duration: \(step.duration))"
                }
                
                if !step.temperature.isEmpty {
                    description += " (Temperature: \(step.temperature))"
                }
                
                description += "\n\n"
            }
        }
        
        return description
    }

    private func scheduleDismissal() {
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            await MainActor.run {
                withAnimation {
                    showSuccessBanner = false
                }
                dismiss()
            }
        }
    }
    
    // MARK: - Image Upload Methods
    private func uploadImageToServer(_ image: UIImage) async {
        isUploadingImage = true
        
        do {
            let response = try await APIClient.shared.uploadImage(image: image, category: "recipes")
            uploadedImageUrl = response.image.originalUrl
            print("✅ Image uploaded successfully: \(response.image.originalUrl)")
        } catch {
            print("❌ Failed to upload image: \(error)")
            // Handle error - could show alert to user
        }
        
        isUploadingImage = false
    }
}

struct SuccessBannerView: View {
    let message: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.white)
            Text(message)
                .font(.headline)
                .foregroundColor(.white)
            Spacer()
        }
        .padding()
        .background(.green.opacity(0.9))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Preview
#Preview {
    UploadRecipeView()
}
