import SwiftUI
import FirebaseAuth

struct RootView: View {
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var authWrapper = AuthManagerWrapper()
    @State private var showingSignup = false
    @State private var showingLogin = false
    
    var body: some View { 
        Group {
            if authManager.isAuthenticated {
                MainView()
            } else if showingSignup {
                SignupView(showingLogin: $showingLogin)
                    .onDisappear {
                        showingSignup = false
                        authManager.checkAuthState()
                    }
                    .onChange(of: showingLogin) { _, newValue in
                        if newValue {
                            showingSignup = false
                        }
                    }
            } else if showingLogin {
                LoginView()
                    .onDisappear {
                        showingLogin = false
                        authManager.checkAuthState()
                    }
            } else {
                LoginFormView(
                    viewModel: authWrapper,
                    onSignUpTapped: {
                        showingSignup = true
                    },
                    onSocialLoginTapped: { socialType in
                        // Handle social login for AuthManager
                        switch socialType {
                        case .google:
                            Task {
                                do {
                                    let user = try await FirebaseService.shared.signInWithGoogle()
                                    authManager.currentUser = user
                                    authManager.isAuthenticated = true
                                } catch {
                                    authManager.showError(message: error.localizedDescription)
                                }
                            }
                        }
                    }
                )
            }
        }
        .alert("Error", isPresented: $authManager.showError) {
            Button("OK") { }
        } message: {
            Text(authManager.errorMessage)
        }
    }
}

#Preview {
    RootView()
} 
