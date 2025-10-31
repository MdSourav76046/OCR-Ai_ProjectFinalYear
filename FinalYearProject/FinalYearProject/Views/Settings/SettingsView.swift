import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var mainViewModel = MainViewModel.shared
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    
    var body: some View {
        ZStack {
            // Background gradient
            themeManager.currentTheme.backgroundGradient
                .ignoresSafeArea(.all)
            
            VStack(spacing: 24) {
                // Profile Section
                profileSection
                
                // Account Settings
                accountSettingsSection
                
                // App Settings
                appSettingsSection
                
                Spacer(minLength: 50)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    mainViewModel.navigateBack()
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
                Text("Settings")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.currentTheme.textColor)
                    .padding(.horizontal, 20)
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImage: $selectedImage, sourceType: .photoLibrary, onImageSelected: {})
        }
    }
    
    // MARK: - Profile Section
    private var profileSection: some View {
        VStack(spacing: 16) {
            // Profile Image
            Button(action: {
                showingImagePicker = true
            }) {
                ZStack {
                    if let selectedImage = selectedImage {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 100))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    // Edit icon overlay
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Image(systemName: "camera.fill")
                                .font(.caption)
                                .foregroundColor(.white)
                                .frame(width: 24, height: 24)
                                .background(Color.blue)
                                .clipShape(Circle())
                        }
                    }
                    .frame(width: 100, height: 100)
                }
            }
            
            // User Info
            VStack(spacing: 8) {
                Text(userDisplayName)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.currentTheme.textColor)
                
                Text(authManager.currentUser?.email ?? "")
                    .font(.subheadline)
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
            }
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(themeManager.currentTheme.cardBackground)
        .cornerRadius(16)
    }
    
    // MARK: - Account Settings Section
    private var accountSettingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Account")
            
            VStack(spacing: 0) {
                settingsRow(icon: "person.fill", title: "Edit Profile", action: {
                    mainViewModel.navigationPath.append(NavigationDestination.editProfile)
                })
                settingsRow(icon: "lock.fill", title: "Change Password", action: {
                    mainViewModel.navigationPath.append(NavigationDestination.changePassword)
                })
                settingsRow(icon: "envelope.fill", title: "Email Preferences", action: {
                    mainViewModel.navigationPath.append(NavigationDestination.emailPreferences)
                })
                settingsRow(icon: "bell.fill", title: "Notifications", action: {
                    mainViewModel.navigationPath.append(NavigationDestination.notifications)
                })
            }
            .background(themeManager.currentTheme.cardBackground)
            .cornerRadius(12)
        }
    }
    
    // MARK: - App Settings Section
    private var appSettingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("App Settings")
            
            VStack(spacing: 0) {
                settingsRow(icon: "paintbrush.fill", title: "Theme", subtitle: themeManager.currentTheme.rawValue, action: {
                    mainViewModel.navigationPath.append(NavigationDestination.themeSelection)
                })
                settingsRow(icon: "globe", title: "Language", subtitle: UserDefaults.standard.string(forKey: "selectedLanguage") ?? "English", action: {
                    mainViewModel.navigationPath.append(NavigationDestination.languageSelection)
                })
                settingsRow(icon: "doc.text.fill", title: "Default Format", subtitle: defaultFormatSubtitle, action: {
                    mainViewModel.navigationPath.append(NavigationDestination.defaultFormat)
                })
                settingsRow(icon: "icloud.fill", title: "Auto Backup", action: {
                    // Auto Backup - intentionally left empty as requested
                })
            }
            .background(themeManager.currentTheme.cardBackground)
            .cornerRadius(12)
        }
    }
    
    
    // MARK: - Helper Views
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundColor(themeManager.currentTheme.textColor)
            .padding(.leading, 4)
    }
    
    private func settingsRow(icon: String, title: String, subtitle: String? = nil, action: @escaping () -> Void) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(themeManager.currentTheme.textColor)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(themeManager.currentTheme.textColor)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture {
                action()
            }
            
            if title != "Terms of Service" {
                Divider()
                    .background(themeManager.currentTheme.dividerColor)
                    .padding(.leading, 56)
            }
        }
    }
    
    // MARK: - Computed Properties
    private var userDisplayName: String {
        guard let user = authManager.currentUser else { return "User" }
        
        // For Google Sign-In users, use firstName (which contains the full name)
        if !user.firstName.isEmpty {
            return user.firstName
        }
        
        // For regular signup users, combine firstName and lastName
        let fullName = [user.firstName, user.lastName].filter { !$0.isEmpty }.joined(separator: " ")
        return fullName.isEmpty ? user.username : fullName
    }
    
    private var defaultFormatSubtitle: String {
        if let saved = UserDefaults.standard.string(forKey: "defaultFormat"),
           let format = OutputFormat(rawValue: saved) {
            return format.displayName
        }
        return "PDF Format"
    }
}

#Preview {
    SettingsView()
} 
