import SwiftUI

struct EmailPreferencesView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var themeManager = ThemeManager.shared
    @State private var emailNotifications = true
    @State private var documentUpdates = true
    @State private var marketingEmails = false
    @State private var weeklyDigest = true
    @State private var showSuccess = false
    
    var body: some View {
        ZStack {
            themeManager.currentTheme.backgroundGradient
                .ignoresSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 24) {
                    // Info Section
                    infoSection
                    
                    // Preferences Section
                    preferencesSection
                    
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
                Text("Email Preferences")
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
            Text("Email preferences saved successfully!")
        }
    }
    
    // MARK: - Info Section
    private var infoSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "envelope.fill")
                .font(.system(size: 60))
                .foregroundColor(themeManager.currentTheme.textColor)
                .frame(width: 100, height: 100)
                .background(
                    Circle()
                        .fill(themeManager.currentTheme.cardBackground)
                )
            
            Text("Manage Your Email Preferences")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.currentTheme.textColor)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Preferences Section
    private var preferencesSection: some View {
        VStack(spacing: 16) {
            preferenceToggle(
                title: "Email Notifications",
                description: "Receive notifications about your account activities",
                isOn: $emailNotifications
            )
            
            preferenceToggle(
                title: "Document Updates",
                description: "Get notified when your documents are processed",
                isOn: $documentUpdates
            )
            
            preferenceToggle(
                title: "Marketing Emails",
                description: "Receive updates about new features and offers",
                isOn: $marketingEmails
            )
            
            preferenceToggle(
                title: "Weekly Digest",
                description: "Get a weekly summary of your activities",
                isOn: $weeklyDigest
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
            savePreferences()
        }) {
            Text("Save Preferences")
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
    
    // MARK: - Save Preferences
    private func savePreferences() {
        // Save to UserDefaults (in a real app, you'd save to Firebase)
        UserDefaults.standard.set(emailNotifications, forKey: "emailNotifications")
        UserDefaults.standard.set(documentUpdates, forKey: "documentUpdates")
        UserDefaults.standard.set(marketingEmails, forKey: "marketingEmails")
        UserDefaults.standard.set(weeklyDigest, forKey: "weeklyDigest")
        
        showSuccess = true
    }
}

#Preview {
    NavigationView {
        EmailPreferencesView()
    }
}

