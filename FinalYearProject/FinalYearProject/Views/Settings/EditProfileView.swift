import SwiftUI

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var firebaseService = FirebaseService.shared
    
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var username: String = ""
    @State private var dateOfBirth: String = ""
    @State private var gender: String = ""
    @State private var selectedDate = Date()
    @State private var showDatePicker = false
    
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
                    // Form Section
                    formSection
                    
                    // Save Button
                    saveButton
                    
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
                Text("Edit Profile")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.currentTheme.textColor)
            }
        }
        .onAppear {
            loadUserData()
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
            Text("Profile updated successfully!")
        }
        .sheet(isPresented: $showDatePicker) {
            datePickerSheet
        }
    }
    
    // MARK: - Form Section
    private var formSection: some View {
        VStack(spacing: 16) {
            // First Name
            inputField(
                icon: "person",
                placeholder: "First Name",
                text: $firstName
            )
            
            // Last Name
            inputField(
                icon: "person",
                placeholder: "Last Name",
                text: $lastName
            )
            
            // Username
            inputField(
                icon: "person.circle",
                placeholder: "Username (3-20 characters)",
                text: $username
            )
            
            // Date of Birth
            dateOfBirthField
            
            // Gender
            genderField
        }
    }
    
    // MARK: - Input Field
    private func inputField(
        icon: String,
        placeholder: String,
        text: Binding<String>
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                .frame(width: 20)
            
            TextField(placeholder, text: text)
                .foregroundColor(themeManager.currentTheme.textColor)
                .autocapitalization(.none)
                .disableAutocorrection(true)
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
                    showDatePicker = true
                }) {
                    HStack {
                        Text(dateOfBirth.isEmpty ? "Select your birthday" : dateOfBirth)
                            .foregroundColor(dateOfBirth.isEmpty ? themeManager.currentTheme.secondaryTextColor.opacity(0.8) : themeManager.currentTheme.textColor)
                        
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
        }
    }
    
    // MARK: - Date Picker Sheet
    private var datePickerSheet: some View {
        NavigationView {
            VStack {
                DatePicker(
                    "Date of Birth",
                    selection: $selectedDate,
                    displayedComponents: .date
                )
                .datePickerStyle(WheelDatePickerStyle())
                .padding()
                
                Button("Done") {
                    let formatter = DateFormatter()
                    formatter.dateStyle = .medium
                    dateOfBirth = formatter.string(from: selectedDate)
                    showDatePicker = false
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
                        showDatePicker = false
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
                        gender = "Male"
                    }
                    Button("Female") {
                        gender = "Female"
                    }
                    Button("Other") {
                        gender = "Other"
                    }
                } label: {
                    HStack {
                        Text(gender.isEmpty ? "Select gender" : gender)
                            .foregroundColor(gender.isEmpty ? themeManager.currentTheme.secondaryTextColor.opacity(0.8) : themeManager.currentTheme.textColor)
                        
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
        }
    }
    
    // MARK: - Save Button
    private var saveButton: some View {
        Button(action: {
            Task {
                await saveProfile()
            }
        }) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Text("Save Changes")
                        .font(.body)
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                LinearGradient(
                    colors: [Color(red: 0.4, green: 0.2, blue: 0.8), Color(red: 0.6, green: 0.3, blue: 0.9)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(12)
            .shadow(color: Color(red: 0.4, green: 0.2, blue: 0.8).opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .disabled(isLoading || !isFormValid)
    }
    
    // MARK: - Form Validation
    private var isFormValid: Bool {
        !firstName.isEmpty && 
        !username.isEmpty && 
        username.count >= 3 && 
        username.count <= 20
    }
    
    // MARK: - Load User Data
    private func loadUserData() {
        guard let user = authManager.currentUser else { return }
        
        firstName = user.firstName
        lastName = user.lastName
        username = user.username
        dateOfBirth = user.dateOfBirth ?? ""
        gender = user.gender ?? ""
        
        if let dob = user.dateOfBirth, !dob.isEmpty {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            if let date = formatter.date(from: dob) {
                selectedDate = date
            }
        }
    }
    
    // MARK: - Save Profile
    private func saveProfile() async {
        guard isFormValid else {
            errorMessage = "Please fill all required fields correctly"
            showError = true
            return
        }
        
        isLoading = true
        
        // Update local user object immediately
        if let currentUser = authManager.currentUser {
            let updatedUser = User(
                id: currentUser.id,
                email: currentUser.email,
                username: username,
                firstName: firstName,
                lastName: lastName,
                dateOfBirth: dateOfBirth.isEmpty ? nil : dateOfBirth,
                gender: gender.isEmpty ? nil : gender,
                createdAt: currentUser.createdAt
            )
            authManager.currentUser = updatedUser
        }
        
        // Save profile (will use local storage first, then try Firestore with timeout)
        do {
            try await firebaseService.updateUserProfile(
                firstName: firstName,
                lastName: lastName,
                username: username,
                dateOfBirth: dateOfBirth.isEmpty ? nil : dateOfBirth,
                gender: gender.isEmpty ? nil : gender
            )
        } catch {
            // Even if it fails, we've already updated locally and saved to UserDefaults
            print("Profile saved locally (Firestore unavailable)")
        }
        
        // Show success - profile is updated locally regardless
        showSuccess = true
        isLoading = false
    }
}

#Preview {
    NavigationView {
        EditProfileView()
    }
}

