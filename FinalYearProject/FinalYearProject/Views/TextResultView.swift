import SwiftUI

struct TextResultView: View {
    let extractedText: String
    let originalImage: UIImage?
    let conversionType: String
    let outputFormat: String
    @StateObject private var mainViewModel = MainViewModel.shared
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var savedPDFService = SavedPDFService.shared
    @State private var showingShareSheet = false
    @State private var showingSaveAlert = false
    @State private var showingTitleInput = false
    @State private var pdfTitle = ""
    @State private var isSaving = false
    @State private var saveError: String?
    @State private var editableText: String = ""
    @State private var isEditing: Bool = false
    
    var body: some View {
        ZStack {
            themeManager.currentTheme.backgroundGradient
                .ignoresSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 20) {
                    // Header (hide when editing to save space)
                    if !isEditing {
                        headerSection
                    }
                    
                    // Text Content
                    textContentSection
                    
                    // Action Buttons
                    actionButtonsSection
                    
                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
            }
        }
        .onAppear {
            // Initialize editable text when view appears
            editableText = extractedText
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    // Navigate directly back to main page using NavigationPath
                    mainViewModel.navigateToRoot()
                    FormatSelectionViewModel.shared.resetState()
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
                Text("Extracted Text")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.currentTheme.textColor)
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(activityItems: [editableText])
        }
        .alert("Save PDF", isPresented: $showingTitleInput) {
            TextField("Enter PDF title", text: $pdfTitle)
            Button("Cancel", role: .cancel) { }
            Button("Save") {
                savePDF()
            }
        } message: {
            Text("Enter a title for your saved PDF")
        }
        .alert("Save Error", isPresented: .constant(saveError != nil)) {
            Button("OK") {
                saveError = nil
            }
        } message: {
            if let error = saveError {
                Text(error)
            }
        }
        .alert("PDF Saved", isPresented: $showingSaveAlert) {
            Button("OK") { }
        } message: {
            Text("Your PDF has been saved successfully!")
        }


    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text.viewfinder")
                .font(.system(size: 60))
                .foregroundColor(themeManager.currentTheme.textColor)
                .frame(width: 100, height: 100)
                .background(
                    Circle()
                        .fill(themeManager.currentTheme.cardBackground)
                )
            
            Text("Text Extraction Complete")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.currentTheme.textColor)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Text Content Section
    private var textContentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Extracted Text:")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.currentTheme.textColor)
                
                Spacer()
                
                // Edit indicator
                HStack(spacing: 4) {
                    Image(systemName: "pencil")
                        .font(.caption)
                    Text(isEditing ? "Editing" : "Tap to Edit")
                        .font(.caption)
                }
                .foregroundColor(isEditing ? .blue : themeManager.currentTheme.secondaryTextColor)
                
                // Done button when editing
                if isEditing {
                    Button("Done") {
                        isEditing = false
                        hideKeyboard()
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(6)
                }
            }
            
            ZStack(alignment: .topLeading) {
                // Editable TextEditor
                TextEditor(text: $editableText)
                    .font(.body)
                    .foregroundColor(themeManager.currentTheme.textColor)
                    .padding(12)
                    .scrollContentBackground(.hidden) // Hide default background
                    .background(themeManager.currentTheme.cardBackground)
                    .frame(minHeight: isEditing ? 300 : 200, maxHeight: isEditing ? 500 : 400)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isEditing ? Color.blue.opacity(0.5) : themeManager.currentTheme.inputFieldBorder, lineWidth: isEditing ? 2 : 1)
                    )
                
                // Placeholder text when empty
                if editableText.isEmpty {
                    Text("No text found in image")
                        .font(.body)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 20)
                        .allowsHitTesting(false)
                }
            }
        }
    }
    
    // MARK: - Action Buttons Section
    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            // Save Button
            Button(action: {
                if savedPDFService.isLimitReached() {
                    saveError = "You have reached the maximum limit of 20 saved PDFs. Please delete some existing PDFs to save new ones."
                } else {
                    showingTitleInput = true
                }
            }) {
                HStack(spacing: 12) {
                    if isSaving {
                        ProgressView()
                            .scaleEffect(0.8)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "bookmark")
                            .font(.title3)
                    }
                    
                    Text(isSaving ? "Saving..." : "Save PDF")
                        .font(.body)
                        .fontWeight(.semibold)
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [Color.green, Color.green.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(12)
                .shadow(color: Color.green.opacity(0.3), radius: 8, x: 0, y: 4)
                .disabled(isSaving)
            }
            
            // Copy Button
            Button(action: {
                UIPasteboard.general.string = editableText
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "doc.on.doc")
                        .font(.title3)
                    
                    Text("Copy Text")
                        .font(.body)
                        .fontWeight(.semibold)
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(themeManager.currentTheme.buttonBackground)
                .foregroundColor(themeManager.currentTheme.textColor)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(themeManager.currentTheme.buttonBorder, lineWidth: 1)
                )
            }
            
            // Share Button
            Button(action: {
                showingShareSheet = true
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.title3)
                    
                    Text("Share Text")
                        .font(.body)
                        .fontWeight(.semibold)
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
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
        }
    }
    
    // MARK: - Save PDF Function
    private func savePDF() {
        guard !pdfTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            saveError = "Please enter a title for your PDF"
            return
        }
        
        isSaving = true
        
        Task {
            do {
                try await savedPDFService.savePDF(
                    title: pdfTitle.trimmingCharacters(in: .whitespacesAndNewlines),
                    text: editableText,
                    image: originalImage,
                    conversionType: conversionType,
                    outputFormat: outputFormat,
                    saveFullImage: true
                )
                
                await MainActor.run {
                    isSaving = false
                    showingSaveAlert = true
                    pdfTitle = ""
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    saveError = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}



#Preview {
    TextResultView(
        extractedText: "This is sample extracted text from an image using OCR technology.",
        originalImage: nil,
        conversionType: "cameraToPdf",
        outputFormat: "text"
    )
}

