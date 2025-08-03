import SwiftUI

struct MainView: View {
    @StateObject private var viewModel = MainViewModel()
    @State private var showingMenu = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color(red: 0.1, green: 0.1, blue: 0.2), Color(red: 0.2, green: 0.2, blue: 0.4)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
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
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $viewModel.showingImagePicker) {
            ImagePicker(selectedImage: $viewModel.selectedImage, sourceType: .photoLibrary)
        }
        .sheet(isPresented: $viewModel.showingCamera) {
            ImagePicker(selectedImage: $viewModel.selectedImage, sourceType: .camera)
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
                .foregroundColor(.white)
            
            Spacer()
            
            // Temporary Sign Out Button
            Button(action: {
                viewModel.signOut()
            }) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Color.red.opacity(0.3))
                    .clipShape(Circle())
            }
            
            Button(action: {
                showingMenu = true
            }) {
                Image(systemName: "line.horizontal.3")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.2))
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
                .foregroundColor(.white)
                .frame(width: 100, height: 100)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.2))
                )
            
            Text("Choose your document source")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.white)
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
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.white.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
        }
    }
}

// MARK: - Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    let sourceType: UIImagePickerController.SourceType
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