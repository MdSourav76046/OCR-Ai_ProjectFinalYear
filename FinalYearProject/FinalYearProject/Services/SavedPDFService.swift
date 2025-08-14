import Foundation
import FirebaseDatabase
import FirebaseAuth
import UIKit

// MARK: - Firebase Service for Saved PDFs
class SavedPDFService: ObservableObject {
    static let shared = SavedPDFService()
    
    private let database = Database.database().reference()
    @Published var savedPDFs: [SavedPDF] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var currentObserverHandle: DatabaseHandle?
    private var currentUserId: String?
    private var isDataCached = false
    private var lastFetchTime: Date?
    
    // Maximum number of saved PDFs allowed
    private let maxSavedPDFs = 20
    
    private init() {
        // Don't start observing until user is explicitly set
    }
    
    // MARK: - Image Compression Helpers
    private func compressImage(_ image: UIImage, maxSizeKB: Int = 500) -> String? {
        var compressionQuality: CGFloat = 0.8
        var imageData = image.jpegData(compressionQuality: compressionQuality)
        
        // Reduce quality until size is under maxSizeKB
        while let data = imageData, 
              data.count > maxSizeKB * 1024 && compressionQuality > 0.1 {
            compressionQuality -= 0.1
            imageData = image.jpegData(compressionQuality: compressionQuality)
        }
        
        // If still too large, resize the image
        if let data = imageData, data.count > maxSizeKB * 1024 {
            let resizedImage = resizeImage(image, maxDimension: 1024)
            imageData = resizedImage.jpegData(compressionQuality: 0.7)
        }
        
        guard let finalData = imageData else { return nil }
        return finalData.base64EncodedString()
    }
    
    private func createThumbnail(_ image: UIImage, maxDimension: CGFloat = 200) -> String? {
        let resized = resizeImage(image, maxDimension: maxDimension)
        guard let thumbnailData = resized.jpegData(compressionQuality: 0.6) else { return nil }
        return thumbnailData.base64EncodedString()
    }
    
    private func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let aspectRatio = size.width / size.height
        
        var newSize: CGSize
        if size.width > size.height {
            newSize = CGSize(width: maxDimension, height: maxDimension / aspectRatio)
        } else {
            newSize = CGSize(width: maxDimension * aspectRatio, height: maxDimension)
        }
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext() ?? image
        UIGraphicsEndImageContext()
        
        return resizedImage
    }
    
    // MARK: - Save PDF
    func savePDF(title: String, text: String, image: UIImage?, conversionType: String, outputFormat: String, saveFullImage: Bool = false) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw SavedPDFError.userNotAuthenticated
        }
        
        // Check if user has reached the limit
        if savedPDFs.count >= maxSavedPDFs {
            throw SavedPDFError.limitReached
        }
        
        print("💾 Saving PDF for user: \(userId)")
        print("📝 Text length: \(text.count) characters")
        print("🖼️ Has image: \(image != nil)")
        print("🔄 Conversion type: \(conversionType)")
        print("📄 Output format: \(outputFormat)")
        
        let itemId = UUID().uuidString
        let timestamp = Date().timeIntervalSince1970
        let deviceName = await UIDevice.current.name
        
        // Prepare image data
        var imageBase64: String? = nil
        var thumbnailBase64: String? = nil
        var imageSize: Int? = nil
        
        if let image = image {
            // Always create thumbnail for list view
            thumbnailBase64 = createThumbnail(image)
            print("✅ Thumbnail created")
            
            // Optionally save full image (compressed)
            if saveFullImage {
                imageBase64 = compressImage(image)
                imageSize = imageBase64?.count
                print("✅ Full image compressed")
            }
        }
        
        let savedPDF = SavedPDF(
            id: itemId,
            userId: userId,
            title: title,
            extractedText: text,
            imageBase64: imageBase64,
            thumbnailBase64: thumbnailBase64,
            timestamp: timestamp,
            deviceName: deviceName,
            textLength: text.count,
            imageSize: imageSize,
            conversionType: conversionType,
            outputFormat: outputFormat
        )
        
        print("📊 Saving to Firebase path: saved_pdfs/\(userId)/\(itemId)")
        
        // Save to Firebase
        return try await withCheckedThrowingContinuation { continuation in
            database.child("saved_pdfs").child(userId).child(itemId).setValue(savedPDF.dictionary) { error, _ in
                if let error = error {
                    print("❌ Firebase save failed: \(error.localizedDescription)")
                    continuation.resume(throwing: SavedPDFError.saveFailed(error.localizedDescription))
                } else {
                    print("✅ Successfully saved PDF to Firebase")
                    continuation.resume()
                }
            }
        }
    }
    
    // MARK: - Fetch Saved PDFs (Force Refresh)
    func fetchSavedPDFs(forceRefresh: Bool = false) {
        guard let userId = Auth.auth().currentUser?.uid else {
            DispatchQueue.main.async {
                self.errorMessage = "User not authenticated"
                self.isLoading = false
            }
            return
        }
        
        // If data is cached and not forcing refresh, show cached data immediately
        if isDataCached && !forceRefresh && !savedPDFs.isEmpty {
            DispatchQueue.main.async {
                self.isLoading = false
            }
            return
        }
        
        DispatchQueue.main.async {
            self.isLoading = true
        }
        
        // Add timeout to prevent infinite loading
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            if self.isLoading {
                self.isLoading = false
                self.errorMessage = "Request timed out. Please try again."
            }
        }
        
        database.child("saved_pdfs").child(userId)
            .queryOrdered(byChild: "timestamp")
            .queryLimited(toLast: 50)  // Increased limit for better caching
            .observeSingleEvent(of: .value) { snapshot in
                var items: [SavedPDF] = []
                
                for child in snapshot.children {
                    if let snapshot = child as? DataSnapshot,
                       let dict = snapshot.value as? [String: Any],
                       let item = SavedPDF(from: dict) {
                        items.append(item)
                    }
                }
                
                DispatchQueue.main.async {
                    self.savedPDFs = items.reversed()  // Most recent first
                    self.isLoading = false
                    self.isDataCached = true
                    self.lastFetchTime = Date()
                }
            } withCancel: { error in
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to fetch saved PDFs: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
    }
    
    // MARK: - Real-time Updates
    private func observeSavedPDFsChanges() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // Remove any existing observer
        removeCurrentObserver()
        
        // Store current user ID
        currentUserId = userId
        
        print("Setting up observer for saved PDFs for user: \(userId)")
        
        // Start new observer for real-time updates
        currentObserverHandle = database.child("saved_pdfs").child(userId)
            .queryOrdered(byChild: "timestamp")
            .queryLimited(toLast: 50)  // Increased limit for better caching
            .observe(.value) { snapshot in
                var items: [SavedPDF] = []
                
                for child in snapshot.children {
                    if let snapshot = child as? DataSnapshot,
                       let dict = snapshot.value as? [String: Any],
                       let item = SavedPDF(from: dict) {
                        items.append(item)
                    }
                }
                
                DispatchQueue.main.async {
                    print("Received \(items.count) saved PDFs for user: \(userId)")
                    self.savedPDFs = items.reversed()
                    self.isDataCached = true
                    self.lastFetchTime = Date()
                }
            } withCancel: { error in
                DispatchQueue.main.async {
                    print("Observer cancelled for saved PDFs for user: \(userId), error: \(error.localizedDescription)")
                    self.errorMessage = "Failed to observe saved PDFs changes: \(error.localizedDescription)"
                }
            }
    }
    
    // MARK: - Remove Current Observer
    private func removeCurrentObserver() {
        if let handle = currentObserverHandle, let userId = currentUserId {
            print("Removing observer for saved PDFs for user: \(userId)")
            database.child("saved_pdfs").child(userId).removeObserver(withHandle: handle)
            currentObserverHandle = nil
        }
        currentUserId = nil
    }
    
    // MARK: - Delete PDF
    func deletePDF(_ pdf: SavedPDF) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        database.child("saved_pdfs").child(userId).child(pdf.id).removeValue { error, _ in
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to delete: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // MARK: - Clear All Saved PDFs
    func clearAllSavedPDFs() {
        guard let userId = Auth.auth().currentUser?.uid else { 
            DispatchQueue.main.async {
                self.errorMessage = "User not authenticated"
            }
            return 
        }
        
        // Clear local items first
        DispatchQueue.main.async {
            self.savedPDFs.removeAll()
        }
        
        database.child("saved_pdfs").child(userId).removeValue { error, _ in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = "Failed to clear saved PDFs: \(error.localizedDescription)"
                } else {
                    print("Successfully cleared all saved PDFs")
                }
            }
        }
    }
    
    // MARK: - Search Saved PDFs
    func searchSavedPDFs(query: String) -> [SavedPDF] {
        guard !query.isEmpty else { return savedPDFs }
        
        return savedPDFs.filter { pdf in
            pdf.title.localizedCaseInsensitiveContains(query) ||
            pdf.extractedText.localizedCaseInsensitiveContains(query) ||
            pdf.deviceName.localizedCaseInsensitiveContains(query) ||
            pdf.conversionType.localizedCaseInsensitiveContains(query)
        }
    }
    
    // MARK: - Get Storage Usage
    func getStorageUsage(completion: @escaping (String) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion("Not authenticated")
            return
        }
        
        database.child("saved_pdfs").child(userId).observeSingleEvent(of: .value) { snapshot in
            var sizeInBytes = 0
            
            // Safely calculate size from snapshot
            if let value = snapshot.value {
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: value)
                    sizeInBytes = jsonData.count
                } catch {
                    print("Error serializing Firebase data: \(error)")
                    // Fallback: estimate size based on number of items
                    sizeInBytes = Int(snapshot.childrenCount * 1000) // Rough estimate
                }
            }
            
            let formatter = ByteCountFormatter()
            formatter.countStyle = .binary
            let sizeString = formatter.string(fromByteCount: Int64(sizeInBytes))
            
            completion("Storage used: \(sizeString) of 1 GB free")
        }
    }
    
    // MARK: - Get Storage Stats
    func getStorageStats() -> (count: Int, totalSize: Int64) {
        let totalSize = savedPDFs.reduce(0) { total, pdf in
            total + Int64(pdf.imageSize ?? 0)
        }
        return (savedPDFs.count, totalSize)
    }
    
    // MARK: - Check if limit reached
    func isLimitReached() -> Bool {
        return savedPDFs.count >= maxSavedPDFs
    }
    
    // MARK: - Get remaining slots
    func getRemainingSlots() -> Int {
        return max(0, maxSavedPDFs - savedPDFs.count)
    }
    
    // MARK: - Format File Size
    func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    // MARK: - Start Observing (call when user logs in)
    func startObserving() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // Only start observing if this is a different user
        if currentUserId != userId {
            print("Starting observer for saved PDFs for user: \(userId)")
            observeSavedPDFsChanges()
            
            // Test Firebase write access
            testFirebaseAccess(userId: userId)
        }
    }
    
    // MARK: - Test Firebase Access
    private func testFirebaseAccess(userId: String) {
        let testData = ["test": "data", "timestamp": Date().timeIntervalSince1970] as [String : Any]
        database.child("test_access").child(userId).setValue(testData) { error, _ in
            if let error = error {
                print("❌ Firebase write test failed: \(error.localizedDescription)")
            } else {
                print("✅ Firebase write test successful")
            }
        }
    }
    
    // MARK: - Stop Observing (call when user logs out)
    func stopObserving() {
        removeCurrentObserver()
        DispatchQueue.main.async {
            self.savedPDFs.removeAll()
            self.isLoading = false
            self.errorMessage = nil
            self.isDataCached = false
            self.lastFetchTime = nil
        }
    }
    
    // MARK: - Switch User (call when user changes)
    func switchUser() {
        print("Switching user - stopping current observer")
        stopObserving()
        
        // Small delay to ensure observer is properly removed
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            print("Switching user - starting new observer")
            self.startObserving()
        }
    }
    
    // MARK: - Get Cached Data Status
    func getCacheStatus() -> (isCached: Bool, lastUpdate: Date?, itemCount: Int) {
        return (isDataCached, lastFetchTime, savedPDFs.count)
    }
    
    // MARK: - Force Refresh Cache
    func forceRefresh() {
        fetchSavedPDFs(forceRefresh: true)
    }
    
    // MARK: - Check if Cache is Stale (older than 5 minutes)
    func isCacheStale() -> Bool {
        guard let lastUpdate = lastFetchTime else { return true }
        return Date().timeIntervalSince(lastUpdate) > 300 // 5 minutes
    }
}

// MARK: - Custom Errors
enum SavedPDFError: Error, LocalizedError {
    case userNotAuthenticated
    case limitReached
    case saveFailed(String)
    case fetchFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .userNotAuthenticated:
            return "User not authenticated"
        case .limitReached:
            return "You have reached the maximum limit of 20 saved PDFs. Please delete some existing PDFs to save new ones."
        case .saveFailed(let message):
            return "Failed to save PDF: \(message)"
        case .fetchFailed(let message):
            return "Failed to fetch saved PDFs: \(message)"
        }
    }
}
