import Foundation
import GoogleSignIn
import FirebaseAuth
import FirebaseCore

@MainActor
class GoogleSignInService: ObservableObject {
    static let shared = GoogleSignInService()
    
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var showError = false
    
    private init() {}
    
    // MARK: - Configure Google Sign-In
    func configure() {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            print("Error: Firebase client ID not found")
            return
        }
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
    }
    
    // MARK: - Sign In with Google
    func signIn() async throws -> AuthDataResult {
        isLoading = true
        
        defer { isLoading = false }
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            throw GoogleSignInError.presentationError
        }
        
        do {
            // Sign in with Google
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
            
            guard let idToken = result.user.idToken?.tokenString else {
                throw GoogleSignInError.noIdToken
            }
            
            // Create Firebase credential
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: result.user.accessToken.tokenString
            )
            
            // Sign in to Firebase
            let authResult = try await Auth.auth().signIn(with: credential)
            
            return authResult
            
        } catch {
            throw GoogleSignInError.signInFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Sign Out
    func signOut() {
        GIDSignIn.sharedInstance.signOut()
    }
    
    // MARK: - Check if user is signed in
    func isSignedIn() -> Bool {
        return GIDSignIn.sharedInstance.currentUser != nil
    }
}

// MARK: - Google Sign-In Errors
enum GoogleSignInError: LocalizedError {
    case presentationError
    case noIdToken
    case signInFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .presentationError:
            return "Unable to present Google Sign-In"
        case .noIdToken:
            return "Failed to get ID token from Google"
        case .signInFailed(let message):
            return "Google Sign-In failed: \(message)"
        }
    }
} 