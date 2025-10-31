import SwiftUI

struct LanguageSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var themeManager = ThemeManager.shared
    
    let languages = ["English", "Spanish", "French", "German", "Italian", "Portuguese", "Chinese", "Japanese", "Korean", "Arabic"]
    @State private var selectedLanguage = UserDefaults.standard.string(forKey: "selectedLanguage") ?? "English"
    @State private var showSuccess = false
    
    var body: some View {
        ZStack {
            themeManager.currentTheme.backgroundGradient
                .ignoresSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 24) {
                    // Info Section
                    infoSection
                    
                    // Language List
                    languageListSection
                    
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
                Text("Language")
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
            Text("Language preference saved!")
        }
    }
    
    // MARK: - Info Section
    private var infoSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "globe")
                .font(.system(size: 60))
                .foregroundColor(themeManager.currentTheme.textColor)
                .frame(width: 100, height: 100)
                .background(
                    Circle()
                        .fill(themeManager.currentTheme.cardBackground)
                )
            
            Text("Select Your Language")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.currentTheme.textColor)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Language List Section
    private var languageListSection: some View {
        VStack(spacing: 12) {
            ForEach(languages, id: \.self) { language in
                languageRow(language: language)
            }
        }
        .background(themeManager.currentTheme.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(themeManager.currentTheme.inputFieldBorder, lineWidth: 1)
        )
    }
    
    // MARK: - Language Row
    @ViewBuilder
    private func languageRow(language: String) -> some View {
        Button(action: {
            selectedLanguage = language
        }) {
            HStack(spacing: 16) {
                Text(language)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(themeManager.currentTheme.textColor)
                
                Spacer()
                
                if selectedLanguage == language {
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
        
        if language != languages.last {
            Divider()
                .background(themeManager.currentTheme.dividerColor)
                .padding(.leading, 20)
        }
    }
    
    // MARK: - Save Button
    private var saveButton: some View {
        Button(action: {
            saveLanguage()
        }) {
            Text("Save Language")
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
    
    // MARK: - Save Language
    private func saveLanguage() {
        UserDefaults.standard.set(selectedLanguage, forKey: "selectedLanguage")
        showSuccess = true
    }
}

#Preview {
    NavigationView {
        LanguageSelectionView()
    }
}

