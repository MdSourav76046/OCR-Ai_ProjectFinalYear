import Foundation
import SwiftUI

// MARK: - Navigation Destination Enum
enum NavigationDestination: Hashable {
    case imageEditor(image: UIImage, conversionType: ConversionType)
    case formatSelection(image: UIImage, conversionType: ConversionType)
    case textResult(extractedText: String, originalImage: UIImage?, conversionType: String, outputFormat: String)
    case settings
    case history
    case savedPDFs
}

// MARK: - Navigation Extensions
extension NavigationDestination {
    var id: String {
        switch self {
        case .imageEditor: return "imageEditor"
        case .formatSelection: return "formatSelection"
        case .textResult: return "textResult"
        case .settings: return "settings"
        case .history: return "history"
        case .savedPDFs: return "savedPDFs"
        }
    }
}
