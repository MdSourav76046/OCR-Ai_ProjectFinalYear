import Foundation
import FirebaseDatabase
import FirebaseAuth
import UIKit

// MARK: - OCR History Model
struct OCRHistoryItem: Codable {
    let id: String
    let userId: String
    let extractedText: String
    let imageBase64: String?  // Store full image as base64 (compressed)
    let thumbnailBase64: String?  // Small thumbnail for list view
    let timestamp: TimeInterval
    let deviceName: String
    let textLength: Int
    let imageSize: Int?  // Size in bytes
    let conversionType: String
    let outputFormat: String
    
    // Convert to dictionary for Firebase
    var dictionary: [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "userId": userId,
            "extractedText": extractedText,
            "timestamp": timestamp,
            "deviceName": deviceName,
            "textLength": textLength,
            "conversionType": conversionType,
            "outputFormat": outputFormat
        ]
        
        // Only include image data if it exists
        if let thumbnail = thumbnailBase64 {
            dict["thumbnailBase64"] = thumbnail
        }
        
        if let image = imageBase64 {
            dict["imageBase64"] = image
        }
        
        if let size = imageSize {
            dict["imageSize"] = size
        }
        
        return dict
    }
    
    // Create from Firebase dictionary
    init?(from dictionary: [String: Any]) {
        guard let id = dictionary["id"] as? String,
              let userId = dictionary["userId"] as? String,
              let extractedText = dictionary["extractedText"] as? String,
              let timestamp = dictionary["timestamp"] as? TimeInterval,
              let deviceName = dictionary["deviceName"] as? String,
              let textLength = dictionary["textLength"] as? Int,
              let conversionType = dictionary["conversionType"] as? String,
              let outputFormat = dictionary["outputFormat"] as? String else {
            return nil
        }
        
        self.id = id
        self.userId = userId
        self.extractedText = extractedText
        self.timestamp = timestamp
        self.deviceName = deviceName
        self.textLength = textLength
        self.conversionType = conversionType
        self.outputFormat = outputFormat
        self.thumbnailBase64 = dictionary["thumbnailBase64"] as? String
        self.imageBase64 = dictionary["imageBase64"] as? String
        self.imageSize = dictionary["imageSize"] as? Int
    }
    
    // Regular initializer
    init(id: String, userId: String, extractedText: String, imageBase64: String? = nil, 
         thumbnailBase64: String? = nil, timestamp: TimeInterval, deviceName: String, 
         textLength: Int, imageSize: Int? = nil, conversionType: String, outputFormat: String) {
        self.id = id
        self.userId = userId
        self.extractedText = extractedText
        self.imageBase64 = imageBase64
        self.thumbnailBase64 = thumbnailBase64
        self.timestamp = timestamp
        self.deviceName = deviceName
        self.textLength = textLength
        self.imageSize = imageSize
        self.conversionType = conversionType
        self.outputFormat = outputFormat
    }
}

// MARK: - Firebase Service for OCR History
class OCRHistoryService: ObservableObject {
    static let shared = OCRHistoryService()
    
    private let database = Database.database().reference()
    @Published var historyItems: [OCRHistoryItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var currentObserverHandle: DatabaseHandle?
    private var currentUserId: String?
    private var isDataCached = false
    private var lastFetchTime: Date?
    
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
    
    // MARK: - Save OCR Result
    func saveOCRResult(text: String, image: UIImage?, conversionType: String, outputFormat: String, saveFullImage: Bool = false) {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("❌ Save failed: User not authenticated")
            self.errorMessage = "User not authenticated"
            return
        }
        
        print("💾 Saving OCR result for user: \(userId)")
        print("📝 Text length: \(text.count) characters")
        print("🖼️ Has image: \(image != nil)")
        print("🔄 Conversion type: \(conversionType)")
        print("📄 Output format: \(outputFormat)")
        
        let itemId = UUID().uuidString
        let timestamp = Date().timeIntervalSince1970
        let deviceName = UIDevice.current.name
        
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
        
        let historyItem = OCRHistoryItem(
            id: itemId,
            userId: userId,
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
        
        print("📊 Saving to Firebase path: ocr_history/\(userId)/\(itemId)")
        
        // Save to Firebase
        database.child("ocr_history").child(userId).child(itemId).setValue(historyItem.dictionary) { error, _ in
            if let error = error {
                print("❌ Firebase save failed: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to save: \(error.localizedDescription)"
                }
            } else {
                print("✅ Successfully saved OCR result to Firebase")
            }
        }
    }
    
    // MARK: - Fetch History (Force Refresh)
    func fetchHistory(forceRefresh: Bool = false) {
        guard let userId = Auth.auth().currentUser?.uid else {
            DispatchQueue.main.async {
                self.errorMessage = "User not authenticated"
                self.isLoading = false
            }
            return
        }
        
        // If data is cached and not forcing refresh, show cached data immediately
        if isDataCached && !forceRefresh && !historyItems.isEmpty {
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
        
        database.child("ocr_history").child(userId)
            .queryOrdered(byChild: "timestamp")
            .queryLimited(toLast: 50)  // Increased limit for better caching
            .observeSingleEvent(of: .value) { snapshot in
                var items: [OCRHistoryItem] = []
                
                for child in snapshot.children {
                    if let snapshot = child as? DataSnapshot,
                       let dict = snapshot.value as? [String: Any],
                       let item = OCRHistoryItem(from: dict) {
                        items.append(item)
                    }
                }
                
                DispatchQueue.main.async {
                    self.historyItems = items.reversed()  // Most recent first
                    self.isLoading = false
                    self.isDataCached = true
                    self.lastFetchTime = Date()
                }
            } withCancel: { error in
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to fetch history: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
    }
    
    // MARK: - Real-time Updates
    private func observeHistoryChanges() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // Remove any existing observer
        removeCurrentObserver()
        
        // Store current user ID
        currentUserId = userId
        
        print("Setting up observer for user: \(userId)")
        
        // Start new observer for real-time updates
        currentObserverHandle = database.child("ocr_history").child(userId)
            .queryOrdered(byChild: "timestamp")
            .queryLimited(toLast: 50)  // Increased limit for better caching
            .observe(.value) { snapshot in
                var items: [OCRHistoryItem] = []
                
                for child in snapshot.children {
                    if let snapshot = child as? DataSnapshot,
                       let dict = snapshot.value as? [String: Any],
                       let item = OCRHistoryItem(from: dict) {
                        items.append(item)
                    }
                }
                
                DispatchQueue.main.async {
                    print("Received \(items.count) items for user: \(userId)")
                    self.historyItems = items.reversed()
                    self.isDataCached = true
                    self.lastFetchTime = Date()
                }
            } withCancel: { error in
                DispatchQueue.main.async {
                    print("Observer cancelled for user: \(userId), error: \(error.localizedDescription)")
                    self.errorMessage = "Failed to observe history changes: \(error.localizedDescription)"
                }
            }
    }
    
    // MARK: - Remove Current Observer
    private func removeCurrentObserver() {
        if let handle = currentObserverHandle, let userId = currentUserId {
            print("Removing observer for user: \(userId)")
            database.child("ocr_history").child(userId).removeObserver(withHandle: handle)
            currentObserverHandle = nil
        }
        currentUserId = nil
    }
    
    // MARK: - Delete Item
    func deleteItem(_ item: OCRHistoryItem) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        database.child("ocr_history").child(userId).child(item.id).removeValue { error, _ in
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to delete: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // MARK: - Clear All History
    func clearAllHistory() {
        guard let userId = Auth.auth().currentUser?.uid else { 
            DispatchQueue.main.async {
                self.errorMessage = "User not authenticated"
            }
            return 
        }
        
        // Clear local items first
        DispatchQueue.main.async {
            self.historyItems.removeAll()
        }
        
        database.child("ocr_history").child(userId).removeValue { error, _ in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = "Failed to clear history: \(error.localizedDescription)"
                } else {
                    print("Successfully cleared all history")
                }
            }
        }
    }
    
    // MARK: - Search History
    func searchHistory(query: String) -> [OCRHistoryItem] {
        guard !query.isEmpty else { return historyItems }
        
        return historyItems.filter { item in
            item.extractedText.localizedCaseInsensitiveContains(query) ||
            item.deviceName.localizedCaseInsensitiveContains(query) ||
            item.conversionType.localizedCaseInsensitiveContains(query)
        }
    }
    
    // MARK: - Get Storage Usage
    func getStorageUsage(completion: @escaping (String) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion("Not authenticated")
            return
        }
        
        database.child("ocr_history").child(userId).observeSingleEvent(of: .value) { snapshot in
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
        let totalSize = historyItems.reduce(0) { total, item in
            total + Int64(item.imageSize ?? 0)
        }
        return (historyItems.count, totalSize)
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
            print("Starting observer for user: \(userId)")
            observeHistoryChanges()
            
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
            self.historyItems.removeAll()
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
        return (isDataCached, lastFetchTime, historyItems.count)
    }
    
    // MARK: - Force Refresh Cache
    func forceRefresh() {
        fetchHistory(forceRefresh: true)
    }
    
    // MARK: - Check if Cache is Stale (older than 5 minutes)
    func isCacheStale() -> Bool {
        guard let lastUpdate = lastFetchTime else { return true }
        return Date().timeIntervalSince(lastUpdate) > 300 // 5 minutes
    }
}

// MARK: - Helper Extensions
extension UIImage {
    func base64String(compressionQuality: CGFloat = 0.8) -> String? {
        guard let imageData = self.jpegData(compressionQuality: compressionQuality) else { return nil }
        return imageData.base64EncodedString()
    }
}

extension String {
    func toImage() -> UIImage? {
        guard let imageData = Data(base64Encoded: self) else { return nil }
        return UIImage(data: imageData)
    }
}
