import SwiftUI

struct LoginFormView<ViewModel: LoginFormViewModelProtocol>: View {
    @ObservedObject var viewModel: ViewModel
    @StateObject private var themeManager = ThemeManager.shared
    let onSignUpTapped: () -> Void
    let onSocialLoginTapped: (SocialLoginType) -> Void
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                themeManager.currentTheme.backgroundGradient
                    .ignoresSafeArea(.all)
                
                VStack(spacing: 30) {
                    welcomeSection
                    
                    socialLoginSection
                    
                    separatorSection
                    
                    formSection
                    
                    forgotPasswordSection
                    
                    signInButton
                    
                    signUpLinkSection
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
            }
        }
        .navigationBarHidden(true)
    }
    
    // MARK: - Welcome Section
    private var welcomeSection: some View {
        VStack(spacing: 16) {
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
                    .foregroundColor(themeManager.currentTheme.textColor)
                
                Text("Enter credential to sign in")
                    .font(.subheadline)
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
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
                Task {
                    onSocialLoginTapped(.google)
                }
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "envelope.circle.fill")
                        .font(.title3)
                        .foregroundColor(themeManager.currentTheme.textColor)
                    
                    Text("Continue with Google")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(themeManager.currentTheme.textColor)
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(themeManager.currentTheme.buttonBackground)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(themeManager.currentTheme.buttonBorder, lineWidth: 1)
                )
            }
        }
    }
    
    // MARK: - Separator Section
    private var separatorSection: some View {
        HStack {
            Rectangle()
                .frame(height: 1)
                .foregroundColor(themeManager.currentTheme.dividerColor)
            
            Text("or sign in with email")
                .font(.caption)
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                .padding(.horizontal, 16)
            
            Rectangle()
                .frame(height: 1)
                .foregroundColor(themeManager.currentTheme.dividerColor)
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
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                .frame(width: 20)
            
            ZStack(alignment: .leading) {
                // Custom placeholder
                if text.wrappedValue.isEmpty {
                    Text(placeholder)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor.opacity(0.8))
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
                .foregroundColor(themeManager.currentTheme.textColor)
                .accentColor(themeManager.currentTheme.textColor)
                .tint(themeManager.currentTheme.textColor)
            }
            
            if isSecure {
                Button(action: {
                    viewModel.isPasswordVisible.toggle()
                }) {
                    Image(systemName: viewModel.isPasswordVisible ? "eye.slash" : "eye")
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                }
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
    
    // MARK: - Forgot Password Section
    private var forgotPasswordSection: some View {
        HStack {
            Spacer()
            
            Button("Forget Password??") {
                viewModel.forgotPassword()
            }
            .font(.caption)
            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
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
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
            
            Button("Sign up Now") {
                onSignUpTapped()
            }
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundColor(themeManager.currentTheme.textColor)
        }
        .padding(.top, 20)
    }
}

// MARK: - Protocol for Login Form ViewModel
protocol LoginFormViewModelProtocol: ObservableObject {
    var email: String { get set }
    var password: String { get set }
    var isPasswordVisible: Bool { get set }
    var isLoading: Bool { get }
    var isFormValid: Bool { get }
    
    func signIn() async
    func forgotPassword()
}

// MARK: - Social Login Types
enum SocialLoginType {
    case google
}

#Preview {
    LoginFormView(
        viewModel: LoginViewModel(),
        onSignUpTapped: {},
        onSocialLoginTapped: { _ in }
    )
} 