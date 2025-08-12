import SwiftUI

struct FormatSelectionView: View {
    let selectedImage: UIImage
    let conversionType: ConversionType
    @StateObject private var viewModel = FormatSelectionViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [Color(red: 0.1, green: 0.1, blue: 0.2), Color(red: 0.2, green: 0.2, blue: 0.4)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea(.all)
                
                VStack(spacing: 30) {
                    headerSection
                    
                    imagePreviewSection
                    
                    formatOptionsSection
                    
                    proceedButton
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
            }
        }
        .navigationBarHidden(true)
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") { }
        } message: {
            Text(viewModel.errorMessage)
        }
        .alert("Success", isPresented: $viewModel.showSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Document processed successfully!")
        }
        .sheet(isPresented: $viewModel.showTextResult) {
            TextResultView(
                extractedText: viewModel.extractedText,
                originalImage: selectedImage,
                conversionType: conversionType.rawValue,
                outputFormat: viewModel.selectedFormat?.rawValue ?? "text"
            )
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Circle())
            }
            
            Spacer()
            
            Text("Select Format")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Spacer()
            
            Color.clear
                .frame(width: 40)
        }
    }
    
    // MARK: - Image Preview Section
    private var imagePreviewSection: some View {
        Image(uiImage: selectedImage)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: 200, maxHeight: 200)
            .cornerRadius(12)
            .shadow(radius: 5)
    }
    
    // MARK: - Format Options Section
    private var formatOptionsSection: some View {
        VStack(spacing: 20) {
            Text("Select your preferable format type")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(OutputFormat.allCases, id: \.self) { format in
                    formatOptionCard(format: format)
                }
            }
        }
    }
    
    // MARK: - Format Option Card
    private func formatOptionCard(format: OutputFormat) -> some View {
        Button(action: {
            viewModel.selectedFormat = format
        }) {
            VStack(spacing: 12) {
                // Format Icon
                Image(systemName: formatIcon(for: format))
                    .font(.system(size: 30))
                    .foregroundColor(viewModel.selectedFormat == format ? .white : .white.opacity(0.8))
                
                // Format Name
                Text(format.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                // Selection Indicator
                Image(systemName: viewModel.selectedFormat == format ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(viewModel.selectedFormat == format ? .green : .white.opacity(0.6))
                    .font(.title3)
            }
            .frame(height: 120)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                viewModel.selectedFormat == format ? 
                    Color.white.opacity(0.2) : Color.white.opacity(0.1)
            )
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        viewModel.selectedFormat == format ? 
                            Color.green.opacity(0.6) : Color.white.opacity(0.2),
                        lineWidth: viewModel.selectedFormat == format ? 2 : 1
                    )
            )
        }
    }
    
    // MARK: - Format Icon Helper
    private func formatIcon(for format: OutputFormat) -> String {
        switch format {
        case .pdf:
            return "doc.text"
        case .docs:
            return "doc.richtext"
        case .word:
            return "doc"
        case .odt:
            return "doc.plaintext"
        case .text:
            return "text.alignleft"
        case .application:
            return "app"
        }
    }
    
    // MARK: - Proceed Button
    private var proceedButton: some View {
        Button(action: {
            Task {
                await viewModel.processDocument(
                    image: selectedImage,
                    conversionType: conversionType
                )
            }
        }) {
            HStack {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Text("Proceed")
                        .font(.body)
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                LinearGradient(
                    colors: viewModel.selectedFormat != nil ? 
                        [Color(red: 0.4, green: 0.2, blue: 0.8), Color(red: 0.6, green: 0.3, blue: 0.9)] :
                        [Color.gray.opacity(0.5), Color.gray.opacity(0.5)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(12)
            .shadow(color: Color(red: 0.4, green: 0.2, blue: 0.8).opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .disabled(viewModel.selectedFormat == nil || viewModel.isLoading)
    }
}

#Preview {
    FormatSelectionView(
        selectedImage: UIImage(),
        conversionType: .cameraToPdf
    )
} 