import SwiftUI

struct FileGenerationResultView: View {
    let fileURL: URL
    let fileType: String
    let originalImage: UIImage?
    
    @StateObject private var mainViewModel = MainViewModel.shared
    @StateObject private var themeManager = ThemeManager.shared
    @State private var showingShareSheet = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            themeManager.currentTheme.backgroundGradient
                .ignoresSafeArea(.all)
            
            VStack(spacing: 30) {
                Spacer()
                
                // Success Icon
                successSection
                
                // File Info
                fileInfoSection
                
                // Action Buttons
                actionButtonsSection
                
                Spacer()
                Spacer()
            }
            .padding(.horizontal, 24)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    mainViewModel.navigateToRoot()
                    FormatSelectionViewModel.shared.resetState()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                            .font(.title3)
                        Text("Back")
                            .font(.body)
                    }
                    .foregroundColor(themeManager.currentTheme.textColor)
                }
            }
            
            ToolbarItem(placement: .principal) {
                Text("File Generated")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.currentTheme.textColor)
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(activityItems: [fileURL])
        }
    }
    
    // MARK: - Success Section
    private var successSection: some View {
        VStack(spacing: 20) {
            // Success checkmark
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.2))
                    .frame(width: 120, height: 120)
                
                Circle()
                    .fill(Color.green.opacity(0.3))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
            }
            
            Text("File Created Successfully!")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(themeManager.currentTheme.textColor)
                .multilineTextAlignment(.center)
            
            Text("Your \(fileType) file is ready")
                .font(.subheadline)
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
        }
    }
    
    // MARK: - File Info Section
    private var fileInfoSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: fileIcon)
                    .font(.system(size: 40))
                    .foregroundColor(fileColor)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(fileURL.lastPathComponent)
                        .font(.headline)
                        .foregroundColor(themeManager.currentTheme.textColor)
                        .lineLimit(2)
                    
                    if let fileSize = getFileSize() {
                        Text(fileSize)
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    }
                }
                
                Spacer()
            }
            .padding()
            .background(themeManager.currentTheme.cardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(themeManager.currentTheme.inputFieldBorder, lineWidth: 1)
            )
        }
    }
    
    // MARK: - Action Buttons Section
    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            // Share/Export Button
            Button(action: {
                showingShareSheet = true
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.title3)
                    
                    Text("Share/Export File")
                        .font(.body)
                        .fontWeight(.semibold)
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [Color(red: 0.4, green: 0.2, blue: 0.8), Color(red: 0.6, green: 0.3, blue: 0.9)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(12)
                .shadow(color: Color(red: 0.4, green: 0.2, blue: 0.8).opacity(0.3), radius: 8, x: 0, y: 4)
            }
            
            // Done Button
            Button(action: {
                mainViewModel.navigateToRoot()
                FormatSelectionViewModel.shared.resetState()
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle")
                        .font(.title3)
                    
                    Text("Done")
                        .font(.body)
                        .fontWeight(.semibold)
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(themeManager.currentTheme.buttonBackground)
                .foregroundColor(themeManager.currentTheme.textColor)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(themeManager.currentTheme.buttonBorder, lineWidth: 1)
                )
            }
        }
    }
    
    // MARK: - Helper Properties
    private var fileIcon: String {
        switch fileType.lowercased() {
        case "pdf":
            return "doc.text.fill"
        case "word", "docx":
            return "doc.richtext.fill"
        default:
            return "doc.fill"
        }
    }
    
    private var fileColor: Color {
        switch fileType.lowercased() {
        case "pdf":
            return .red
        case "word", "docx":
            return .blue
        default:
            return .gray
        }
    }
    
    // MARK: - Get File Size
    private func getFileSize() -> String? {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
              let fileSize = attributes[.size] as? Int64 else {
            return nil
        }
        
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }
}

#Preview {
    FileGenerationResultView(
        fileURL: URL(fileURLWithPath: "/tmp/sample.pdf"),
        fileType: "PDF",
        originalImage: nil
    )
}

