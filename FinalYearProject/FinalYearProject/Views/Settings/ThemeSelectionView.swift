import SwiftUI

struct ThemeSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.presentationMode) private var presentationMode
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                themeManager.currentTheme.backgroundGradient
                    .ignoresSafeArea(.all)
                
                VStack(spacing: 24) {
                    // Theme Options
                    VStack(spacing: 16) {
                        ForEach(AppTheme.allCases, id: \.self) { theme in
                            themeOptionRow(theme: theme)
                        }
                    }
                    .background(themeManager.currentTheme.cardBackground)
                    .cornerRadius(16)
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                            .font(.title3)
                            .foregroundColor(themeManager.currentTheme.textColor)
                        
                        Text("Back")
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundColor(themeManager.currentTheme.textColor)
                    }
                }
            }
            
            ToolbarItem(placement: .principal) {
                Text("Theme")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.currentTheme.textColor)
                    .padding(.horizontal, 20)
            }
        }
    }
    
    private func themeOptionRow(theme: AppTheme) -> some View {
        VStack(spacing: 0) {
            Button(action: {
                themeManager.setTheme(theme)
            }) {
                HStack(spacing: 16) {
                    // Theme Preview
                    RoundedRectangle(cornerRadius: 8)
                        .fill(theme.backgroundGradient)
                        .frame(width: 60, height: 40)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(themeManager.currentTheme == theme ? Color.blue : Color.clear, lineWidth: 2)
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(theme.rawValue)
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(themeManager.currentTheme.textColor)
                        
                        Text(theme == .dark ? "Dark background with light text" : "Light background with dark text")
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    }
                    
                    Spacer()
                    
                    // Checkmark for selected theme
                    if themeManager.currentTheme == theme {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .buttonStyle(PlainButtonStyle())
            
            if theme != AppTheme.allCases.last {
                Divider()
                    .background(themeManager.currentTheme.dividerColor)
                    .padding(.leading, 92)
            }
        }
    }
}

#Preview {
    ThemeSelectionView()
} 