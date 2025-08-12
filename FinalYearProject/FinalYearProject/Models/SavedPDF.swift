import Foundation

// MARK: - Saved PDF Model
struct SavedPDF: Codable, Identifiable {
    let id: String
    let userId: String
    let title: String
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
            "title": title,
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
              let title = dictionary["title"] as? String,
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
        self.title = title
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
    init(id: String, userId: String, title: String, extractedText: String, imageBase64: String? = nil, 
         thumbnailBase64: String? = nil, timestamp: TimeInterval, deviceName: String, 
         textLength: Int, imageSize: Int? = nil, conversionType: String, outputFormat: String) {
        self.id = id
        self.userId = userId
        self.title = title
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
