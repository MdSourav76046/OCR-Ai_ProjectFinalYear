import SwiftUI

struct MainView: View {
    @StateObject private var viewModel = MainViewModel()
    @StateObject private var themeManager = ThemeManager.shared
    @State private var showingMenu = false
    @State private var navigateToSettings = false
    @State private var navigateToHistory = false
    @State private var navigateToSavedPDFs = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                themeManager.currentTheme.backgroundGradient
                    .ignoresSafeArea(.all)
                
                VStack(spacing: 30) {
                    // Header
                    headerSection
                    
                    // Welcome Section
                    welcomeSection
                    
                    // Document Upload Options
                    uploadOptionsSection
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
                
                // Side Menu
                SideMenuView(
                    isShowing: $showingMenu, 
                    onSignOut: {
                        viewModel.signOut()
                    },
                    onSettingsTapped: {
                        navigateToSettings = true
                    },
                    onHistoryTapped: {
                        navigateToHistory = true
                    },
                    onSavedPDFsTapped: {
                        navigateToSavedPDFs = true
                    }
                )
            }
            
            // Navigation Destinations
            .navigationDestination(isPresented: $navigateToSettings) {
                SettingsView()
            }
            .navigationDestination(isPresented: $navigateToHistory) {
                DocumentHistoryView()
            }
            .navigationDestination(isPresented: $navigateToSavedPDFs) {
                SavedPDFView()
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            // Start observing services when main view appears
            OCRHistoryService.shared.startObserving()
            SavedPDFService.shared.startObserving()
        }
        .onDisappear {
            // Stop observing services when main view disappears
            OCRHistoryService.shared.stopObserving()
            SavedPDFService.shared.stopObserving()
        }
        .sheet(isPresented: $viewModel.showingImagePicker) {
            ImagePicker(selectedImage: $viewModel.selectedImage, sourceType: .photoLibrary, onImageSelected: {
                viewModel.showingFormatPicker = true
            })
        }
        .sheet(isPresented: $viewModel.showingCamera) {
            ImagePicker(selectedImage: $viewModel.selectedImage, sourceType: .camera, onImageSelected: {
                viewModel.showingFormatPicker = true
            })
        }
        .sheet(isPresented: $viewModel.showingFormatPicker) {
            FormatSelectionView(selectedImage: viewModel.selectedImage!, conversionType: viewModel.selectedConversionType)
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") { }
        } message: {
            Text(viewModel.errorMessage)
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            Text("Convert Image To Text")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(themeManager.currentTheme.textColor)
            
            Spacer()
            
            // Menu Button
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showingMenu = true
                }
            }) {
                Image(systemName: "line.horizontal.3")
                    .font(.title2)
                    .foregroundColor(themeManager.currentTheme.textColor)
                    .frame(width: 40, height: 40)
                    .background(themeManager.currentTheme.cardBackground)
                    .clipShape(Circle())
            }
        }
        .padding(.top, 20)
    }
    
    // MARK: - Welcome Section
    private var welcomeSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text.viewfinder")
                .font(.system(size: 60))
                .foregroundColor(themeManager.currentTheme.textColor)
                .frame(width: 100, height: 100)
                .background(
                    Circle()
                        .fill(themeManager.currentTheme.cardBackground)
                )
            
            Text("Choose your document source")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.currentTheme.textColor)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Upload Options Section
    private var uploadOptionsSection: some View {
        VStack(spacing: 16) {
            // Scan Image Button
            uploadOptionButton(
                icon: "camera",
                title: "Scan Image",
                description: "Take a new photo to scan",
                action: {
                    viewModel.selectedConversionType = .cameraToPdf
                    viewModel.showingCamera = true
                }
            )
            
            // Scan PDF Button
            uploadOptionButton(
                icon: "doc.text",
                title: "Scan PDF",
                description: "Select a PDF document to process",
                action: {
                    viewModel.selectedConversionType = .pdfToPdf
                    viewModel.showingImagePicker = true
                }
            )
            
            // Select from Gallery Button
            uploadOptionButton(
                icon: "photo.on.rectangle",
                title: "Select from Gallery",
                description: "Choose an existing image from your gallery",
                action: {
                    viewModel.selectedConversionType = .galleryToPdf
                    viewModel.showingImagePicker = true
                }
            )
        }
    }
    
    // MARK: - Upload Option Button Helper
    private func uploadOptionButton(
        icon: String,
        title: String,
        description: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(themeManager.currentTheme.textColor)
                    .frame(width: 40, height: 40)
                    .background(themeManager.currentTheme.cardBackground)
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.currentTheme.textColor)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(themeManager.currentTheme.cardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(themeManager.currentTheme.inputFieldBorder, lineWidth: 1)
            )
        }
    }
}

// MARK: - Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    let sourceType: UIImagePickerController.SourceType
    let onImageSelected: () -> Void
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
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
                parent.onImageSelected()
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

#Preview {
    MainView()
} 
