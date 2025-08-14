import SwiftUI

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Info Row Helper
struct InfoRow: View {
    let label: String
    let value: String
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                .frame(width: 80, alignment: .leading)
            
            Text(value)
                .font(.caption)
                .foregroundColor(themeManager.currentTheme.textColor)
                .fontWeight(.medium)
            
            Spacer()
        }
    }
}
