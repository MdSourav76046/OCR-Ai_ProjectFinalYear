import SwiftUI

struct DefaultFormatView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var themeManager = ThemeManager.shared
    
    let formats: [OutputFormat] = [.pdf, .docs, .word, .text]
    @State private var selectedFormat: OutputFormat = {
        if let saved = UserDefaults.standard.string(forKey: "defaultFormat"),
           let format = OutputFormat(rawValue: saved) {
            return format
        }
        return .pdf
    }()
    @State private var showSuccess = false
    
    var body: some View {
        ZStack {
            themeManager.currentTheme.backgroundGradient
                .ignoresSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 24) {
                    // Info Section
                    infoSection
                    
                    // Format List
                    formatListSection
                    
                    // Save Button
                    saveButton
                    
                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
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
                Text("Default Format")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.currentTheme.textColor)
            }
        }
        .alert("Success", isPresented: $showSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Default format saved!")
        }
    }
    
    // MARK: - Info Section
    private var infoSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text.fill")
                .font(.system(size: 60))
                .foregroundColor(themeManager.currentTheme.textColor)
                .frame(width: 100, height: 100)
                .background(
                    Circle()
                        .fill(themeManager.currentTheme.cardBackground)
                )
            
            Text("Select Default Format")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.currentTheme.textColor)
                .multilineTextAlignment(.center)
            
            Text("This format will be pre-selected when processing documents")
                .font(.caption)
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Format List Section
    private var formatListSection: some View {
        VStack(spacing: 12) {
            ForEach(formats, id: \.self) { format in
                formatRow(format: format)
            }
        }
        .background(themeManager.currentTheme.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(themeManager.currentTheme.inputFieldBorder, lineWidth: 1)
        )
    }
    
    // MARK: - Format Row
    @ViewBuilder
    private func formatRow(format: OutputFormat) -> some View {
        Button(action: {
            selectedFormat = format
        }) {
            HStack(spacing: 16) {
                Image(systemName: formatIcon(for: format))
                    .font(.title3)
                    .foregroundColor(themeManager.currentTheme.textColor)
                    .frame(width: 30)
                
                Text(format.displayName)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(themeManager.currentTheme.textColor)
                
                Spacer()
                
                if selectedFormat == format {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title3)
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        .font(.title3)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        
        if format != formats.last {
            Divider()
                .background(themeManager.currentTheme.dividerColor)
                .padding(.leading, 66)
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
        case .text:
            return "text.alignleft"
        default:
            return "doc"
        }
    }
    
    // MARK: - Save Button
    private var saveButton: some View {
        Button(action: {
            saveFormat()
        }) {
            Text("Save Format")
                .font(.body)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
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
    }
    
    // MARK: - Save Format
    private func saveFormat() {
        UserDefaults.standard.set(selectedFormat.rawValue, forKey: "defaultFormat")
        showSuccess = true
    }
}

#Preview {
    NavigationView {
        DefaultFormatView()
    }
}

