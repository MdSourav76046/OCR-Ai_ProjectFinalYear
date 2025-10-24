import SwiftUI

struct FormatSelectionView: View {
    let selectedImage: UIImage
    let conversionType: ConversionType
    @StateObject private var viewModel = FormatSelectionViewModel.shared
    @StateObject private var mainViewModel = MainViewModel.shared
    @StateObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            themeManager.currentTheme.backgroundGradient
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
        .navigationBarHidden(true)
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") {
                // Reset app state and dismiss all sheets
                MainViewModel.shared.resetState()
                FormatSelectionViewModel.shared.resetState()
                dismiss()
            }
        } message: {
            Text(viewModel.errorMessage)
        }
        .alert("Success", isPresented: $viewModel.showSuccess) {
            Button("OK") {
                // Reset app state and dismiss
                MainViewModel.shared.resetState()
                FormatSelectionViewModel.shared.resetState()
                dismiss()
            }
        } message: {
            Text("Document processed successfully!")
        }


    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            Button(action: {
                // Navigate back to image editor
                mainViewModel.navigateBack()
            }) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(themeManager.currentTheme.textColor)
                    .frame(width: 40, height: 40)
                    .background(themeManager.currentTheme.cardBackground)
                    .clipShape(Circle())
            }
            
            Spacer()
            
            Text("Select Format")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(themeManager.currentTheme.textColor)
            
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
                .foregroundColor(themeManager.currentTheme.textColor)
                .multilineTextAlignment(.center)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(OutputFormat.allCases, id: \.self) { format in
                    formatOptionCard(format: format)
                }
            }
            
            // Grammar Correction Toggle
            grammarCorrectionToggle
        }
    }
    
    // MARK: - Grammar Correction Toggle
    private var grammarCorrectionToggle: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "checkmark.circle")
                    .font(.title2)
                    .foregroundColor(themeManager.currentTheme.textColor)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Correct Grammar")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.currentTheme.textColor)
                    
                    Text("Use AI to correct grammar in extracted text")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                }
                
                Spacer()
                
                Toggle("", isOn: $viewModel.correctGrammar)
                    .toggleStyle(SwitchToggleStyle(tint: .green))
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
    
    // MARK: - Format Option Card
    private func formatOptionCard(format: OutputFormat) -> some View {
        Button(action: {
            viewModel.selectedFormat = format
        }) {
            VStack(spacing: 12) {
                // Format Icon
                Image(systemName: formatIcon(for: format))
                    .font(.system(size: 30))
                    .foregroundColor(viewModel.selectedFormat == format ? themeManager.currentTheme.textColor : themeManager.currentTheme.secondaryTextColor)
                
                // Format Name
                Text(format.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(themeManager.currentTheme.textColor)
                    .multilineTextAlignment(.center)
                
                // Selection Indicator
                Image(systemName: viewModel.selectedFormat == format ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(viewModel.selectedFormat == format ? .green : themeManager.currentTheme.secondaryTextColor)
                    .font(.title3)
            }
            .frame(height: 120)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                viewModel.selectedFormat == format ? 
                    themeManager.currentTheme.cardBackground : themeManager.currentTheme.inputFieldBackground
            )
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        viewModel.selectedFormat == format ? 
                            Color.green.opacity(0.6) : themeManager.currentTheme.inputFieldBorder,
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
        case .cv:
            return "person.text.rectangle"
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
                Group {
                    if viewModel.selectedFormat != nil {
                        LinearGradient(
                            colors: [Color(red: 0.4, green: 0.2, blue: 0.8), Color(red: 0.6, green: 0.3, blue: 0.9)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    } else {
                        themeManager.currentTheme.buttonBackground
                    }
                }
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
