import SwiftUI

enum AppTheme: String, CaseIterable {
    case dark = "Dark"
    case light = "Light"
    
    var backgroundGradient: LinearGradient {
        switch self {
        case .dark:
            return LinearGradient(
                colors: [Color(red: 0.1, green: 0.1, blue: 0.2), Color(red: 0.2, green: 0.2, blue: 0.4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .light:
            return LinearGradient(
                colors: [Color(red: 0.85, green: 0.9, blue: 1.0), Color(red: 0.7, green: 0.8, blue: 0.95)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    var textColor: Color {
        switch self {
        case .dark:
            return .white
        case .light:
            return .black
        }
    }
    
    var secondaryTextColor: Color {
        switch self {
        case .dark:
            return .white.opacity(0.8)
        case .light:
            return .black.opacity(0.7)
        }
    }
    
    var cardBackground: Color {
        switch self {
        case .dark:
            return Color.white.opacity(0.1)
        case .light:
            return Color.white.opacity(0.9)
        }
    }
    
    var dividerColor: Color {
        switch self {
        case .dark:
            return Color.white.opacity(0.2)
        case .light:
            return Color.black.opacity(0.15)
        }
    }
    
    var buttonBackground: Color {
        switch self {
        case .dark:
            return Color.black.opacity(0.3)
        case .light:
            return Color.black.opacity(0.1)
        }
    }
    
    var buttonBorder: Color {
        switch self {
        case .dark:
            return Color.white.opacity(0.3)
        case .light:
            return Color.black.opacity(0.2)
        }
    }
    
    var primaryButtonBackground: Color {
        switch self {
        case .dark:
            return Color.blue
        case .light:
            return Color.blue
        }
    }
    
    var inputFieldBackground: Color {
        switch self {
        case .dark:
            return Color.white.opacity(0.1)
        case .light:
            return Color.white.opacity(0.7)
        }
    }
    
    var inputFieldBorder: Color {
        switch self {
        case .dark:
            return Color.white.opacity(0.3)
        case .light:
            return Color.black.opacity(0.2)
        }
    }
}

@MainActor
class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var currentTheme: AppTheme = .dark
    
    private let userDefaults = UserDefaults.standard
    private let themeKey = "selectedTheme"
    
    private init() {
        loadTheme()
    }
    
    func setTheme(_ theme: AppTheme) {
        currentTheme = theme
        saveTheme()
    }
    
    private func loadTheme() {
        if let savedTheme = userDefaults.string(forKey: themeKey),
           let theme = AppTheme(rawValue: savedTheme) {
            currentTheme = theme
        }
    }
    
    private func saveTheme() {
        userDefaults.set(currentTheme.rawValue, forKey: themeKey)
    }
} 