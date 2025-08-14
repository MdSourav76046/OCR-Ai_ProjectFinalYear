import SwiftUI

struct SavedPDFView: View {
    @StateObject private var savedPDFService = SavedPDFService.shared
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var mainViewModel = MainViewModel.shared
    @State private var searchText = ""
    @State private var showingDeleteAlert = false
    @State private var pdfToDelete: SavedPDF?
    @State private var showingStorageInfo = false
    @State private var showingLimitAlert = false
    @State private var showingClearAllAlert = false
    
    private var filteredPDFs: [SavedPDF] {
        if searchText.isEmpty {
            return savedPDFService.savedPDFs
        } else {
            return savedPDFService.searchSavedPDFs(query: searchText)
        }
    }
    
    var body: some View {
        ZStack {
            themeManager.currentTheme.backgroundGradient
                .ignoresSafeArea(.all)
            
            VStack(spacing: 0) {
                // Header
                headerSection
                
                // Search Bar
                searchSection
                
                // PDFs List
                pdfsListSection
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    mainViewModel.navigateBack()
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
                Text("Saved PDFs")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.currentTheme.textColor)
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingStorageInfo = true
                }) {
                    Image(systemName: "info.circle")
                        .font(.title3)
                        .foregroundColor(themeManager.currentTheme.textColor)
                }
            }
        }
        .onAppear {
            savedPDFService.startObserving()
        }
        .onDisappear {
            savedPDFService.stopObserving()
        }
        .alert("Delete PDF", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let pdf = pdfToDelete {
                    savedPDFService.deletePDF(pdf)
                }
            }
        } message: {
            Text("Are you sure you want to delete this PDF? This action cannot be undone.")
        }
        .alert("Storage Info", isPresented: $showingStorageInfo) {
            Button("OK") { }
        } message: {
            Text("You have \(savedPDFService.getRemainingSlots()) slots remaining out of 20 total slots.")
        }
        .alert("Limit Reached", isPresented: $showingLimitAlert) {
            Button("OK") { }
        } message: {
            Text("You have reached the maximum limit of 20 saved PDFs. Please delete some existing PDFs to save new ones.")
        }
        .alert("Clear All PDFs", isPresented: $showingClearAllAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear All", role: .destructive) {
                savedPDFService.clearAllSavedPDFs()
            }
        } message: {
            Text("Are you sure you want to delete all saved PDFs? This action cannot be undone.")
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Saved PDFs")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.currentTheme.textColor)
                    
                    Text("\(savedPDFService.savedPDFs.count) of 20 PDFs saved")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        .padding([.bottom])
                }
                
                Spacer()
                
                // Storage indicator and Clear All button
                HStack(spacing: 12) {
                    // Storage indicator
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(savedPDFService.getRemainingSlots()) slots left")
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        
                        // Progress bar
                        ProgressView(value: Double(savedPDFService.savedPDFs.count), total: 20)
                            .progressViewStyle(LinearProgressViewStyle(tint: savedPDFService.isLimitReached() ? .red : .blue))
                            .frame(width: 60, height: 4)
                    }
                    
                    // Clear all button
                    if !savedPDFService.savedPDFs.isEmpty {
                        Button(action: {
                            showingClearAllAlert = true
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "trash")
                                    .font(.caption2)
                                Text("Clear All")
                                    .font(.caption2)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.red)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 10)
    }
    
    // MARK: - Search Section
    private var searchSection: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
            
            TextField("Search saved PDFs...", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
                .foregroundColor(themeManager.currentTheme.textColor)
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(themeManager.currentTheme.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(themeManager.currentTheme.inputFieldBorder, lineWidth: 1)
        )
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
    }
    
    // MARK: - PDFs List Section
    private var pdfsListSection: some View {
        Group {
            if savedPDFService.isLoading {
                loadingView
            } else if filteredPDFs.isEmpty {
                emptyStateView
            } else {
                pdfsListView
            }
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .progressViewStyle(CircularProgressViewStyle(tint: themeManager.currentTheme.textColor))
            
            Text("Loading saved PDFs...")
                .font(.body)
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text")
                .font(.system(size: 60))
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
            
            Text(searchText.isEmpty ? "No saved PDFs yet" : "No PDFs found")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.currentTheme.textColor)
            
            Text(searchText.isEmpty ? "Save PDFs from your extracted text to access them here" : "Try adjusting your search terms")
                .font(.body)
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 40)
    }
    
    // MARK: - PDFs List View
    private var pdfsListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredPDFs) { pdf in
                    SavedPDFRowView(
                        pdf: pdf,
                        onDelete: {
                            pdfToDelete = pdf
                            showingDeleteAlert = true
                        }
                    )
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
    }
}

// MARK: - Saved PDF Row View
struct SavedPDFRowView: View {
    let pdf: SavedPDF
    let onDelete: () -> Void
    @StateObject private var themeManager = ThemeManager.shared
    @State private var showingDetail = false
    
    var body: some View {
        Button(action: {
            showingDetail = true
        }) {
            HStack(spacing: 16) {
                // Thumbnail
                if let thumbnailBase64 = pdf.thumbnailBase64,
                   let image = thumbnailBase64.toImage() {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(themeManager.currentTheme.cardBackground)
                        .frame(width: 60, height: 60)
                        .overlay(
                            Image(systemName: "doc.text")
                                .font(.title2)
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        )
                }
                
                // PDF Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(pdf.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.currentTheme.textColor)
                        .lineLimit(1)
                    
                    Text(pdf.extractedText.prefix(50) + (pdf.extractedText.count > 50 ? "..." : ""))
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        .lineLimit(2)
                    
                    HStack(spacing: 8) {
                        Text(pdf.conversionType)
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(themeManager.currentTheme.buttonBackground)
                            .foregroundColor(themeManager.currentTheme.textColor)
                            .cornerRadius(4)
                        
                        Text(pdf.outputFormat)
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(themeManager.currentTheme.buttonBackground)
                            .foregroundColor(themeManager.currentTheme.textColor)
                            .cornerRadius(4)
                        
                        Text(formatDate(pdf.timestamp))
                            .font(.caption2)
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    }
                }
                
                Spacer()
                
                // Delete Button
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundColor(.red)
                        .frame(width: 30, height: 30)
                        .background(Color.red.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(themeManager.currentTheme.cardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(themeManager.currentTheme.inputFieldBorder, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingDetail) {
            SavedPDFDetailView(pdf: pdf)
        }
    }
    
    private func formatDate(_ timestamp: TimeInterval) -> String {
        let date = Date(timeIntervalSince1970: timestamp)
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Saved PDF Detail View
struct SavedPDFDetailView: View {
    let pdf: SavedPDF
    @StateObject private var themeManager = ThemeManager.shared
    @Environment(\.presentationMode) private var presentationMode
    @State private var showingShareSheet = false
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.currentTheme.backgroundGradient
                    .ignoresSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Image Section
                        if let imageBase64 = pdf.imageBase64,
                           let image = imageBase64.toImage() {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 300)
                                .cornerRadius(12)
                                .shadow(radius: 5)
                        }
                        
                        // PDF Info
                        VStack(alignment: .leading, spacing: 8) {
                            InfoRow(label: "Title", value: pdf.title)
                            InfoRow(label: "Device", value: pdf.deviceName)
                            InfoRow(label: "Conversion Type", value: pdf.conversionType)
                            InfoRow(label: "Output Format", value: pdf.outputFormat)
                            InfoRow(label: "Text Length", value: "\(pdf.textLength) characters")
                            InfoRow(label: "Created", value: formatDate(pdf.timestamp))
                            
                            if let imageSize = pdf.imageSize {
                                InfoRow(label: "Image Size", value: formatFileSize(Int64(imageSize)))
                            }
                        }
                        .padding()
                        .background(themeManager.currentTheme.cardBackground)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(themeManager.currentTheme.inputFieldBorder, lineWidth: 1)
                        )
                        
                        // Text Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Extracted Text")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(themeManager.currentTheme.textColor)
                            
                            Text(pdf.extractedText)
                                .font(.body)
                                .foregroundColor(themeManager.currentTheme.textColor)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(themeManager.currentTheme.cardBackground)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(themeManager.currentTheme.inputFieldBorder, lineWidth: 1)
                                )
                        }
                        
                        // Action Buttons
                        HStack(spacing: 16) {
                            Button(action: {
                                UIPasteboard.general.string = pdf.extractedText
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "doc.on.doc")
                                    Text("Copy Text")
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(themeManager.currentTheme.buttonBackground)
                                .foregroundColor(themeManager.currentTheme.textColor)
                                .cornerRadius(8)
                            }
                            
                            Button(action: {
                                showingShareSheet = true
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "square.and.arrow.up")
                                    Text("Share")
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    LinearGradient(
                                        colors: [Color(red: 0.4, green: 0.2, blue: 0.8), Color(red: 0.6, green: 0.3, blue: 0.9)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .foregroundColor(.white)
                                .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                }
            }
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
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
                    Text("PDF Details")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.currentTheme.textColor)
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(activityItems: [pdf.extractedText])
        }
    }
    
    private func formatDate(_ timestamp: TimeInterval) -> String {
        let date = Date(timeIntervalSince1970: timestamp)
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

#Preview {
    SavedPDFView()
}
