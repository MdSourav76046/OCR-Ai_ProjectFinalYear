import SwiftUI

struct DocumentHistoryView: View {
    @StateObject private var ocrHistoryService = OCRHistoryService.shared
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var mainViewModel = MainViewModel.shared
    @State private var searchText = ""
    @State private var showingDeleteAlert = false
    @State private var itemToDelete: OCRHistoryItem?
    @State private var showingStorageInfo = false
    @State private var showingClearAllAlert = false
    
    private var filteredItems: [OCRHistoryItem] {
        if searchText.isEmpty {
            return ocrHistoryService.historyItems
        } else {
            return ocrHistoryService.searchHistory(query: searchText)
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
                
                // Documents List
                documentsListSection
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
                Text("Document History")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.currentTheme.textColor)
            }
        }
        .onAppear {
            print("DocumentHistoryView appeared")
            ocrHistoryService.startObserving()
            
            // Smart loading: use cache if available, otherwise fetch
            let cacheStatus = ocrHistoryService.getCacheStatus()
            print("Cache status: isCached=\(cacheStatus.isCached), itemCount=\(cacheStatus.itemCount)")
            
            if cacheStatus.isCached && cacheStatus.itemCount > 0 {
                // Data is cached, show immediately
                print("Using cached data: \(cacheStatus.itemCount) items")
                
                // Check if cache is stale and refresh in background
                if ocrHistoryService.isCacheStale() {
                    print("Cache is stale, refreshing in background...")
                    ocrHistoryService.fetchHistory(forceRefresh: true)
                }
            } else {
                // No cache, fetch from Firebase
                print("No cache available, fetching from Firebase...")
                ocrHistoryService.fetchHistory()
            }
        }
        .alert("Delete Document", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let item = itemToDelete {
                    ocrHistoryService.deleteItem(item)
                }
            }
        } message: {
            Text("Are you sure you want to delete this document? This action cannot be undone.")
        }
        .alert("Storage Information", isPresented: $showingStorageInfo) {
            Button("OK") { }
        } message: {
            Text(ocrHistoryService.errorMessage ?? "No storage information available")
        }
        .alert("Clear All Documents", isPresented: $showingClearAllAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear All", role: .destructive) {
                ocrHistoryService.clearAllHistory()
            }
        } message: {
            Text("Are you sure you want to delete all documents? This action cannot be undone.")
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Documents")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.currentTheme.textColor)
                    
                    let stats = ocrHistoryService.getStorageStats()
                    let cacheStatus = ocrHistoryService.getCacheStatus()
                    Text("\(stats.count) documents • \(ocrHistoryService.formatFileSize(stats.totalSize))")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    
                    if cacheStatus.isCached {
                        Text("📱 Cached • \(cacheStatus.itemCount) items")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button(action: {
                        ocrHistoryService.getStorageUsage { usage in
                            ocrHistoryService.errorMessage = usage
                            showingStorageInfo = true
                        }
                    }) {
                        Image(systemName: "info.circle")
                            .font(.title3)
                            .foregroundColor(themeManager.currentTheme.textColor)
                    }
                    
                    Button(action: {
                        showingClearAllAlert = true
                    }) {
                        Text("Clear All")
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
        }
    }
    
    // MARK: - Search Section
    private var searchSection: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
            
            TextField("Search documents...", text: $searchText)
                .foregroundColor(themeManager.currentTheme.textColor)
                .textFieldStyle(PlainTextFieldStyle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(themeManager.currentTheme.inputFieldBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(themeManager.currentTheme.inputFieldBorder, lineWidth: 1)
        )
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }
    
    // MARK: - Documents List Section
    private var documentsListSection: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if ocrHistoryService.isLoading {
                    loadingView
                } else if filteredItems.isEmpty {
                    emptyStateView
                } else {
                    ForEach(filteredItems, id: \.id) { item in
                        OCRHistoryRowView(
                            item: item,
                            onDelete: {
                                itemToDelete = item
                                showingDeleteAlert = true
                            }
                        )
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
        .refreshable {
            // Pull to refresh - force update from Firebase
            ocrHistoryService.forceRefresh()
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .foregroundColor(themeManager.currentTheme.textColor)
            
            Text("Loading documents...")
                .font(.body)
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
        }
        .padding(.top, 60)
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.viewfinder")
                .font(.system(size: 60))
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
            
            Text("No Documents Yet")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.currentTheme.textColor)
            
            Text("Your scanned documents will appear here")
                .font(.body)
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 60)
    }
}

// MARK: - OCR History Row View
struct OCRHistoryRowView: View {
    let item: OCRHistoryItem
    let onDelete: () -> Void
    @StateObject private var themeManager = ThemeManager.shared
    @State private var showingDetail = false
    
    var body: some View {
        Button(action: {
            showingDetail = true
        }) {
            HStack(spacing: 16) {
                // Thumbnail
                if let thumbnailBase64 = item.thumbnailBase64,
                   let thumbnail = thumbnailBase64.toImage() {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .cornerRadius(8)
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(themeManager.currentTheme.cardBackground)
                        .frame(width: 60, height: 60)
                        .overlay(
                            Image(systemName: "doc.text")
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        )
                }
                
                // Document Info
                VStack(alignment: .leading, spacing: 4) {
                    Text("Document \(item.id.prefix(8))")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.currentTheme.textColor)
                        .lineLimit(1)
                    
                    Text(item.extractedText.prefix(50) + (item.extractedText.count > 50 ? "..." : ""))
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        .lineLimit(2)
                    
                    HStack(spacing: 8) {
                        Text(item.conversionType)
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(themeManager.currentTheme.buttonBackground)
                            .foregroundColor(themeManager.currentTheme.textColor)
                            .cornerRadius(4)
                        
                        Text(item.outputFormat)
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(themeManager.currentTheme.buttonBackground)
                            .foregroundColor(themeManager.currentTheme.textColor)
                            .cornerRadius(4)
                        
                        Text(formatDate(item.timestamp))
                            .font(.caption2)
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    }
                }
                
                Spacer()
                
                // Delete Button
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .font(.title3)
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
            OCRHistoryDetailView(item: item)
        }
    }
    
    private func formatDate(_ timestamp: TimeInterval) -> String {
        let date = Date(timeIntervalSince1970: timestamp)
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - OCR History Detail View
struct OCRHistoryDetailView: View {
    let item: OCRHistoryItem
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
                        if let imageBase64 = item.imageBase64,
                           let image = imageBase64.toImage() {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 300)
                                .cornerRadius(12)
                                .shadow(radius: 5)
                        }
                        
                        // Document Info
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Document Information")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(themeManager.currentTheme.textColor)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                InfoRow(label: "Device", value: item.deviceName)
                                InfoRow(label: "Type", value: item.conversionType)
                                InfoRow(label: "Format", value: item.outputFormat)
                                InfoRow(label: "Text Length", value: "\(item.textLength) characters")
                                InfoRow(label: "Date", value: formatDate(item.timestamp))
                                if let imageSize = item.imageSize {
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
                        }
                        
                        // Text Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Extracted Text")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(themeManager.currentTheme.textColor)
                            
                            Text(item.extractedText)
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
                                UIPasteboard.general.string = item.extractedText
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
                Text("Document Details")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.currentTheme.textColor)
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(activityItems: [item.extractedText])
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
    DocumentHistoryView()
}
