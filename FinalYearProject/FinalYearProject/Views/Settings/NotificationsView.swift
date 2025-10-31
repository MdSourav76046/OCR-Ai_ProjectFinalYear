import SwiftUI

struct NotificationsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var themeManager = ThemeManager.shared
    @State private var pushNotifications = true
    @State private var soundEnabled = true
    @State private var badgeEnabled = true
    @State private var documentProcessing = true
    @State private var appUpdates = false
    @State private var showSuccess = false
    
    var body: some View {
        ZStack {
            themeManager.currentTheme.backgroundGradient
                .ignoresSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 24) {
                    // Info Section
                    infoSection
                    
                    // Notifications Section
                    notificationsSection
                    
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
                Text("Notifications")
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
            Text("Notification settings saved successfully!")
        }
    }
    
    // MARK: - Info Section
    private var infoSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "bell.fill")
                .font(.system(size: 60))
                .foregroundColor(themeManager.currentTheme.textColor)
                .frame(width: 100, height: 100)
                .background(
                    Circle()
                        .fill(themeManager.currentTheme.cardBackground)
                )
            
            Text("Manage Your Notifications")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.currentTheme.textColor)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Notifications Section
    private var notificationsSection: some View {
        VStack(spacing: 16) {
            preferenceToggle(
                title: "Push Notifications",
                description: "Receive push notifications on your device",
                isOn: $pushNotifications
            )
            
            preferenceToggle(
                title: "Sound",
                description: "Play sound when receiving notifications",
                isOn: $soundEnabled
            )
            
            preferenceToggle(
                title: "Badge",
                description: "Show badge count on app icon",
                isOn: $badgeEnabled
            )
            
            preferenceToggle(
                title: "Document Processing",
                description: "Get notified when documents are processed",
                isOn: $documentProcessing
            )
            
            preferenceToggle(
                title: "App Updates",
                description: "Receive notifications about app updates",
                isOn: $appUpdates
            )
        }
    }
    
    // MARK: - Preference Toggle
    private func preferenceToggle(
        title: String,
        description: String,
        isOn: Binding<Bool>
    ) -> some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.currentTheme.textColor)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
            }
            
            Spacer()
            
            Toggle("", isOn: isOn)
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
    
    // MARK: - Save Button
    private var saveButton: some View {
        Button(action: {
            saveSettings()
        }) {
            Text("Save Settings")
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
    
    // MARK: - Save Settings
    private func saveSettings() {
        // Save to UserDefaults (in a real app, you'd save to Firebase)
        UserDefaults.standard.set(pushNotifications, forKey: "pushNotifications")
        UserDefaults.standard.set(soundEnabled, forKey: "soundEnabled")
        UserDefaults.standard.set(badgeEnabled, forKey: "badgeEnabled")
        UserDefaults.standard.set(documentProcessing, forKey: "documentProcessing")
        UserDefaults.standard.set(appUpdates, forKey: "appUpdates")
        
        showSuccess = true
    }
}

#Preview {
    NavigationView {
        NotificationsView()
    }
}

