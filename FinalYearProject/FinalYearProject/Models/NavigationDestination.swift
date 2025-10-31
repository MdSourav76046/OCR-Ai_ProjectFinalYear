import Foundation
import SwiftUI

// MARK: - Navigation Destination Enum
enum NavigationDestination: Hashable {
    case imageEditor(image: UIImage, conversionType: ConversionType)
    case formatSelection(image: UIImage, conversionType: ConversionType)
    case textResult(extractedText: String, originalImage: UIImage?, conversionType: String, outputFormat: String)
    case fileGenerationResult(fileURL: URL, fileType: String, originalImage: UIImage?)
    case settings
    case history
    case savedPDFs
    // Settings sub-views
    case editProfile
    case changePassword
    case emailPreferences
    case notifications
    case themeSelection
    case languageSelection
    case defaultFormat
}

// MARK: - Navigation Extensions
extension NavigationDestination {
    var id: String {
        switch self {
        case .imageEditor: return "imageEditor"
        case .formatSelection: return "formatSelection"
        case .textResult: return "textResult"
        case .fileGenerationResult: return "fileGenerationResult"
        case .settings: return "settings"
        case .history: return "history"
        case .savedPDFs: return "savedPDFs"
        case .editProfile: return "editProfile"
        case .changePassword: return "changePassword"
        case .emailPreferences: return "emailPreferences"
        case .notifications: return "notifications"
        case .themeSelection: return "themeSelection"
        case .languageSelection: return "languageSelection"
        case .defaultFormat: return "defaultFormat"
        }
    }
}
