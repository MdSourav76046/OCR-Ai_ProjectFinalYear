import Foundation

struct Document: Codable, Identifiable {
    let id: String
    let fileName: String
    let fileType: DocumentType
    let conversionType: ConversionType
    let originalImage: String?
    let extractedText: String?
    let correctedText: String?
    let outputFormat: OutputFormat
    let status: ProcessingStatus
    let createdAt: Date
    let updatedAt: Date
    
    init(id: String, fileName: String, fileType: DocumentType, conversionType: ConversionType, originalImage: String? = nil, extractedText: String? = nil, correctedText: String? = nil, outputFormat: OutputFormat, status: ProcessingStatus = .pending) {
        self.id = id
        self.fileName = fileName
        self.fileType = fileType
        self.conversionType = conversionType
        self.originalImage = originalImage
        self.extractedText = extractedText
        self.correctedText = correctedText
        self.outputFormat = outputFormat
        self.status = status
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

enum DocumentType: String, CaseIterable, Codable {
    case image = "image"
    case pdf = "pdf"
    
    var displayName: String {
        switch self {
        case .image:
            return "Image"
        case .pdf:
            return "PDF"
        }
    }
}

enum ConversionType: String, CaseIterable, Codable {
    case cameraToPdf = "Camera to PDF"
    case galleryToPdf = "Gallery to PDF"
    case pdfToPdf = "PDF to PDF"
    case imageToText = "Image to Text"
    
    var displayName: String {
        return self.rawValue
    }
}

enum OutputFormat: String, CaseIterable, Codable {
    case pdf = "PDF Format"
    case docs = "DOCS Format"
    case word = "WORD Format"
    case odt = "ODT Format"
    case text = "TEXT Format"
    case application = "Application"
    
    var displayName: String {
        return self.rawValue
    }
}

enum ProcessingStatus: String, CaseIterable, Codable {
    case pending = "pending"
    case processing = "processing"
    case completed = "completed"
    case failed = "failed"
    
    var displayName: String {
        switch self {
        case .pending:
            return "Pending"
        case .processing:
            return "Processing"
        case .completed:
            return "Completed"
        case .failed:
            return "Failed"
        }
    }
} 