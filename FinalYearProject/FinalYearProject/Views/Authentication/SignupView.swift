import SwiftUI

struct SignupView: View {
    @StateObject private var viewModel = SignupViewModel()
    @StateObject private var themeManager = ThemeManager.shared
    @Binding var showingLogin: Bool
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.currentTheme.backgroundGradient
                    .ignoresSafeArea(.all)
                
                VStack(spacing: 30) {
                    welcomeSection
                    
                    socialLoginSection
                    
                    separatorSection
                    
                    formSection
                    
                    termsSection
                    
                    signupButton
                    
                    loginLinkSection
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
    }
    
    
    // MARK: - Welcome Section
    private var welcomeSection: some View {
        VStack(spacing: 8) {
            Text("Join OCR Scanner")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.currentTheme.textColor)
            
            Text("Transform your documents into digital text")
                .font(.subheadline)
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Social Login Section
    private var socialLoginSection: some View {
        VStack(spacing: 16) {
            Button(action: {
                Task {
                    await viewModel.signUpWithGoogle()
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
            
            Text("or sign up with email")
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
            inputField(
                icon: "envelope",
                placeholder: "example@email.com",
                text: $viewModel.email,
                keyboardType: .emailAddress,
                textContentType: .emailAddress
            )
            
            inputField(
                icon: "lock",
                placeholder: "At least 6 characters",
                text: $viewModel.password,
                isSecure: true,
                textContentType: .newPassword
            )
            
            inputField(
                icon: "person",
                placeholder: "Name(3-20 characters)",
                text: $viewModel.username,
                textContentType: .username
            )
            
            dateOfBirthField
            
            genderField
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
    
    // MARK: - Date of Birth Field
    private var dateOfBirthField: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: "calendar")
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    .frame(width: 20)
                
                Button(action: {
                    viewModel.showDatePicker = true
                }) {
                    HStack {
                        Text(viewModel.dateOfBirth.isEmpty ? "Select your birthday" : viewModel.dateOfBirth)
                            .foregroundColor(viewModel.dateOfBirth.isEmpty ? themeManager.currentTheme.secondaryTextColor.opacity(0.8) : themeManager.currentTheme.textColor)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.down")
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                            .font(.caption)
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
            
            Text("Select your date of birth")
                .font(.caption)
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                .padding(.leading, 16)
        }
        .sheet(isPresented: $viewModel.showDatePicker) {
            datePickerSheet
        }
    }
    
    // MARK: - Date Picker Sheet
    private var datePickerSheet: some View {
        NavigationView {
            VStack {
                DatePicker(
                    "Date of Birth",
                    selection: $viewModel.selectedDate,
                    displayedComponents: .date
                )
                .datePickerStyle(WheelDatePickerStyle())
                .padding()
                
                Button("Done") {
                    let formatter = DateFormatter()
                    formatter.dateStyle = .medium
                    viewModel.dateOfBirth = formatter.string(from: viewModel.selectedDate)
                    viewModel.showDatePicker = false
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppColors.primary)
                .cornerRadius(12)
                .padding(.horizontal)
            }
            .navigationTitle("Select Birthday")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        viewModel.showDatePicker = false
                    }
                }
            }
        }
    }
    
    // MARK: - Gender Field
    private var genderField: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: "person.2")
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    .frame(width: 20)
                
                Menu {
                    Button("Male") {
                        viewModel.gender = "Male"
                    }
                    Button("Female") {
                        viewModel.gender = "Female"
                    }
                    Button("Other") {
                        viewModel.gender = "Other"
                    }
                } label: {
                    HStack {
                        Text(viewModel.gender.isEmpty ? "Select gender" : viewModel.gender)
                            .foregroundColor(viewModel.gender.isEmpty ? themeManager.currentTheme.secondaryTextColor.opacity(0.8) : themeManager.currentTheme.textColor)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.down")
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                            .font(.caption)
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
            
            Text("Choose your gender")
                .font(.caption)
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                .padding(.leading, 16)
        }
    }
    
    // MARK: - Terms Section
    private var termsSection: some View {
        Text("By creating an account, you agree to our Terms of Service and Privacy Policy")
            .font(.caption)
            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 20)
    }
    
    // MARK: - Sign Up Button
    private var signupButton: some View {
        Button(action: {
            Task {
                await viewModel.signUp()
            }
        }) {
            HStack {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Text("Create Account")
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
    
    private var loginLinkSection: some View {
        HStack {
            Text("Already have an account?")
                .font(.subheadline)
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
            
            Button("Sign In") {
                showingLogin = true
            }
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundColor(themeManager.currentTheme.textColor)
        }
        .padding(.top, 20)
    }
}

#Preview {
    SignupView(showingLogin: .constant(false))
} 
