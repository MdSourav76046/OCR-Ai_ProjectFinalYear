import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color(red: 0.1, green: 0.1, blue: 0.2), Color(red: 0.2, green: 0.2, blue: 0.4)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea(.all)
                
                VStack(spacing: 30) {
                    // Welcome text
                    welcomeSection
                    
                    // Social Login Buttons
                    socialLoginSection
                    
                    // Separator
                    separatorSection
                    
                    // Form Fields
                    formSection
                    
                    // Forgot Password
                    forgotPasswordSection
                    
                    // Sign In Button
                    signInButton
                    
                    // Sign Up link
                    signUpLinkSection
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
            }
        }
        .navigationBarHidden(true)
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
    
    // MARK: - Welcome Section
    private var welcomeSection: some View {
        VStack(spacing: 16) {
            // App logo/icon
            Image(systemName: "doc.text.viewfinder")
                .font(.system(size: 60))
                .foregroundColor(.white)
                .frame(width: 100, height: 100)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.2))
                )
            
            VStack(spacing: 8) {
                Text("Welcome Back")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text("Enter credential to sign in")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 20)
    }
    
    // MARK: - Social Login Section
    private var socialLoginSection: some View {
        VStack(spacing: 16) {
            // Google Sign In
            Button(action: {
                viewModel.signInWithGoogle()
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "globe")
                        .font(.title3)
                        .foregroundColor(.white)
                    
                    Text("Continue with Google")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.black.opacity(0.3))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
            }
            
            // Facebook Sign In
            Button(action: {
                viewModel.signInWithFacebook()
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "person.2")
                        .font(.title3)
                        .foregroundColor(.white)
                    
                    Text("Continue with Facebook")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.blue.opacity(0.3))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
            }
        }
    }
    
    // MARK: - Separator Section
    private var separatorSection: some View {
        HStack {
            Rectangle()
                .frame(height: 1)
                .foregroundColor(.white.opacity(0.3))
            
            Text("or sign in with email")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                .padding(.horizontal, 16)
            
            Rectangle()
                .frame(height: 1)
                .foregroundColor(.white.opacity(0.3))
        }
    }
    
    // MARK: - Form Section
    private var formSection: some View {
        VStack(spacing: 16) {
            // Email
            inputField(
                icon: "envelope",
                placeholder: "example@email.com",
                text: $viewModel.email,
                keyboardType: .emailAddress,
                textContentType: .emailAddress
            )
            
            // Password
            inputField(
                icon: "lock",
                placeholder: "Enter your password",
                text: $viewModel.password,
                isSecure: true,
                textContentType: .password
            )
        }
    }
    
    // MARK: - Input Field Helper
    private func inputField(
        icon: String,
        placeholder: String,
        text: Binding<String>,
        isSecure: Bool = false,
        keyboardType: UIKeyboardType = .default,
        textContentType: UITextContentType? = nil
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 20)
            
            ZStack(alignment: .leading) {
                // Custom placeholder
                if text.wrappedValue.isEmpty {
                    Text(placeholder)
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Group {
                    if isSecure && !viewModel.isPasswordVisible {
                        SecureField("", text: text)
                    } else {
                        TextField("", text: text)
                    }
                }
                .textContentType(textContentType)
                .keyboardType(keyboardType)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .foregroundColor(.white)
                .accentColor(.white)
                .tint(.white)
            }
            
            if isSecure {
                Button(action: {
                    viewModel.isPasswordVisible.toggle()
                }) {
                    Image(systemName: viewModel.isPasswordVisible ? "eye.slash" : "eye")
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - Forgot Password Section
    private var forgotPasswordSection: some View {
        HStack {
            Spacer()
            
            Button("Forget Password??") {
                viewModel.forgotPassword()
            }
            .font(.caption)
            .foregroundColor(.white.opacity(0.8))
        }
    }
    
    // MARK: - Sign In Button
    private var signInButton: some View {
        Button(action: {
            Task {
                await viewModel.signIn()
            }
        }) {
            HStack {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Text("Sign in")
                        .font(.body)
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                LinearGradient(
                    colors: viewModel.isFormValid ? 
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
        .disabled(!viewModel.isFormValid || viewModel.isLoading)
    }
    
    // MARK: - Sign Up Link Section
    private var signUpLinkSection: some View {
        HStack {
            Text("Don't have any account?")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
            
            Button("Sign up Now") {
                // Navigate to signup
            }
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundColor(.white)
        }
        .padding(.top, 20)
    }
}

#Preview {
    LoginView()
} 