import SwiftUI

struct ChangePasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var firebaseService = FirebaseService.shared
    
    @State private var currentPassword: String = ""
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var isCurrentPasswordVisible = false
    @State private var isNewPasswordVisible = false
    @State private var isConfirmPasswordVisible = false
    
    @State private var isLoading = false
    @State private var showError = false
    @State private var showSuccess = false
    @State private var errorMessage = ""
    
    var body: some View {
        ZStack {
            themeManager.currentTheme.backgroundGradient
                .ignoresSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 24) {
                    // Info Section
                    infoSection
                    
                    // Form Section
                    formSection
                    
                    // Change Password Button
                    changePasswordButton
                    
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
                Text("Change Password")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.currentTheme.textColor)
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .alert("Success", isPresented: $showSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Password changed successfully!")
        }
    }
    
    // MARK: - Info Section
    private var infoSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "lock.rotation")
                .font(.system(size: 60))
                .foregroundColor(themeManager.currentTheme.textColor)
                .frame(width: 100, height: 100)
                .background(
                    Circle()
                        .fill(themeManager.currentTheme.cardBackground)
                )
            
            Text("Change Your Password")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.currentTheme.textColor)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Form Section
    private var formSection: some View {
        VStack(spacing: 16) {
            // Current Password
            passwordField(
                icon: "lock",
                placeholder: "Current Password",
                text: $currentPassword,
                isVisible: $isCurrentPasswordVisible
            )
            
            // New Password
            passwordField(
                icon: "lock.fill",
                placeholder: "New Password (at least 6 characters)",
                text: $newPassword,
                isVisible: $isNewPasswordVisible
            )
            
            // Confirm Password
            passwordField(
                icon: "lock.fill",
                placeholder: "Confirm New Password",
                text: $confirmPassword,
                isVisible: $isConfirmPasswordVisible
            )
        }
    }
    
    // MARK: - Password Field
    private func passwordField(
        icon: String,
        placeholder: String,
        text: Binding<String>,
        isVisible: Binding<Bool>
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                .frame(width: 20)
            
            ZStack(alignment: .leading) {
                if text.wrappedValue.isEmpty {
                    Text(placeholder)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor.opacity(0.8))
                }
                
                Group {
                    if isVisible.wrappedValue {
                        TextField("", text: text)
                    } else {
                        SecureField("", text: text)
                    }
                }
                .foregroundColor(themeManager.currentTheme.textColor)
                .autocapitalization(.none)
                .disableAutocorrection(true)
            }
            
            Button(action: {
                isVisible.wrappedValue.toggle()
            }) {
                Image(systemName: isVisible.wrappedValue ? "eye.slash" : "eye")
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(themeManager.currentTheme.inputFieldBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(themeManager.currentTheme.inputFieldBorder, lineWidth: 1)
        )
    }
    
    // MARK: - Change Password Button
    private var changePasswordButton: some View {
        Button(action: {
            Task {
                await changePassword()
            }
        }) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Text("Change Password")
                        .font(.body)
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                LinearGradient(
                    colors: isFormValid ? 
                        [Color(red: 0.4, green: 0.2, blue: 0.8), Color(red: 0.6, green: 0.3, blue: 0.9)] :
                        [Color.gray.opacity(0.5), Color.gray.opacity(0.5)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(12)
            .shadow(color: Color(red: 0.4, green: 0.2, blue: 0.8).opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .disabled(!isFormValid || isLoading)
    }
    
    // MARK: - Form Validation
    private var isFormValid: Bool {
        !currentPassword.isEmpty &&
        !newPassword.isEmpty &&
        !confirmPassword.isEmpty &&
        newPassword.count >= 6 &&
        newPassword == confirmPassword
    }
    
    // MARK: - Change Password
    private func changePassword() async {
        guard isFormValid else {
            errorMessage = "Please fill all fields correctly. Passwords must match and be at least 6 characters."
            showError = true
            return
        }
        
        if newPassword != confirmPassword {
            errorMessage = "New passwords do not match"
            showError = true
            return
        }
        
        isLoading = true
        
        do {
            try await firebaseService.changePassword(
                currentPassword: currentPassword,
                newPassword: newPassword
            )
            
            // Clear form
            currentPassword = ""
            newPassword = ""
            confirmPassword = ""
            
            showSuccess = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isLoading = false
    }
}

#Preview {
    NavigationView {
        ChangePasswordView()
    }
}

