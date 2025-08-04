import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        LoginFormView(
            viewModel: viewModel,
            onSignUpTapped: {
                // Navigate to signup
            },
            onSocialLoginTapped: { socialType in
                switch socialType {
                case .google:
                    Task {
                        await viewModel.signInWithGoogle()
                    }
                }
            }
        )
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") { }
        } message: {
            Text(viewModel.errorMessage)
        }
        .alert("Success", isPresented: $viewModel.showSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Login successful!")
        }
    }
}

#Preview {
    LoginView()
} 
