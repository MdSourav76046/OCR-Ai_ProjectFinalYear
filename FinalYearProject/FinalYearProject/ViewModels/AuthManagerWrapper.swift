import Foundation
import SwiftUI

@MainActor
class AuthManagerWrapper: ObservableObject, LoginFormViewModelProtocol {
    private let authManager = AuthManager.shared
    
    var email: String {
        get { authManager.email }
        set { authManager.email = newValue }
    }
    
    var password: String {
        get { authManager.password }
        set { authManager.password = newValue }
    }
    
    var isPasswordVisible: Bool {
        get { authManager.isPasswordVisible }
        set { authManager.isPasswordVisible = newValue }
    }
    
    var isLoading: Bool {
        authManager.isLoading
    }
    
    var isFormValid: Bool {
        authManager.isFormValid
    }
    
    func signIn() async {
        await authManager.signIn()
    }
    
    func forgotPassword() {
        // Implement forgot password for AuthManager if needed
    }
} 