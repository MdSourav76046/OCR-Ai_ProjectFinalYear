import SwiftUI

struct SideMenuView: View {
    @Binding var isShowing: Bool
    let onSignOut: () -> Void
    let onSettingsTapped: () -> Void
    let onHistoryTapped: () -> Void
    let onSavedPDFsTapped: () -> Void
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        ZStack {
            // Background overlay
            if isShowing {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isShowing = false
                        }
                    }
            }
            
            // Side menu
            HStack {
                Spacer()
                
                VStack(spacing: 0) {
                    // User Profile Section
                    userProfileSection
                    
                    // Menu Items
                    menuItemsSection
                    
                    Spacer()
                    
                    // Sign Out Button
                    signOutButton
                }
                .frame(width: UIScreen.main.bounds.width * 0.7)
                .background(themeManager.currentTheme.backgroundGradient)
                .offset(x: isShowing ? 0 : UIScreen.main.bounds.width)
                .animation(.easeInOut(duration: 0.3), value: isShowing)
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
    
    // MARK: - User Profile Section
    private var userProfileSection: some View {
        VStack(spacing: 16) {
            // Profile Image
            Image(systemName: "person.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 100, height: 100)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.2))
                )
            
                               // User Name
                   Text(userDisplayName)
                       .font(.title2)
                       .fontWeight(.semibold)
                       .foregroundColor(themeManager.currentTheme.textColor)
        }
        .padding(.top, 40)
        .padding(.bottom, 30)
    }
    
    // MARK: - Menu Items Section
    private var menuItemsSection: some View {
        VStack(spacing: 0) {
            menuItem(icon: "gearshape", title: "Settings") {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isShowing = false
                }
                onSettingsTapped()
            }
            
            menuItem(icon: "clock.arrow.circlepath", title: "History") {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isShowing = false
                }
                onHistoryTapped()
            }
            
            menuItem(icon: "doc.fill", title: "Saved PDFs") {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isShowing = false
                }
                onSavedPDFsTapped()
            }
            
            menuItem(icon: "square.and.arrow.up", title: "Invite friends") {
                // Handle invite friends
            }
            
            menuItem(icon: "star", title: "Rate us") {
                // Handle rate us
            }
        }
    }
    
    // MARK: - Menu Item Helper
    private func menuItem(icon: String, title: String, action: @escaping () -> Void) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(themeManager.currentTheme.textColor)
                .frame(width: 24, height: 24)
            
            Text(title)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(themeManager.currentTheme.textColor)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.clear)
        .contentShape(Rectangle())
        .onTapGesture {
            action()
        }
    }
    
    // MARK: - Sign Out Button
    private var signOutButton: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
                isShowing = false
            }
            onSignOut()
        }) {
            HStack {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.body)
                    .foregroundColor(.white)
                
                Text("Sign Out")
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.red.opacity(0.8))
            .cornerRadius(12)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 40)
    }
}

#Preview {
    SideMenuView(isShowing: .constant(true), onSignOut: {}, onSettingsTapped: {}, onHistoryTapped: {}, onSavedPDFsTapped: {})
}
