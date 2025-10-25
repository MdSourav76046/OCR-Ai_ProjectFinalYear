import Foundation
import PDFKit
import UIKit

// MARK: - PDF Generation Service
class PDFGenerationService: ObservableObject {
    static let shared = PDFGenerationService()
    
    @Published var isProcessing = false
    @Published var errorMessage = ""
    
    private init() {}
    
    // MARK: - Generate PDF from Text
    func generatePDF(text: String, title: String) async throws -> URL {
        await MainActor.run {
            isProcessing = true
            errorMessage = ""
        }
        
        defer {
            Task { @MainActor in
                isProcessing = false
            }
        }
        
        // Create PDF
        let pdfData = try createPDFData(text: text, title: title)
        
        // Save to temporary directory
        let fileName = "\(title.replacingOccurrences(of: " ", with: "_"))_\(Date().timeIntervalSince1970).pdf"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        try pdfData.write(to: tempURL)
        
        return tempURL
    }
    
    // MARK: - Create PDF Data
    private func createPDFData(text: String, title: String) throws -> Data {
        // PDF page format
        let pageSize = CGRect(x: 0, y: 0, width: 612, height: 792) // US Letter size
        let pageMargins = UIEdgeInsets(top: 72, left: 72, bottom: 72, right: 72) // 1 inch margins
        
        // Create PDF context
        let pdfRenderer = UIGraphicsPDFRenderer(bounds: pageSize)
        
        let pdfData = pdfRenderer.pdfData { context in
            // Start first page
            context.beginPage()
            
            var yPosition: CGFloat = pageMargins.top
            let textWidth = pageSize.width - pageMargins.left - pageMargins.right
            
            // Draw title
            let titleFont = UIFont.boldSystemFont(ofSize: 24)
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: titleFont,
                .foregroundColor: UIColor.black
            ]
            
            let titleSize = title.boundingRect(
                with: CGSize(width: textWidth, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: titleAttributes,
                context: nil
            ).size
            
            title.draw(
                in: CGRect(x: pageMargins.left, y: yPosition, width: textWidth, height: titleSize.height),
                withAttributes: titleAttributes
            )
            
            yPosition += titleSize.height + 20
            
            // Draw date
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .long
            let dateString = dateFormatter.string(from: Date())
            
            let dateFont = UIFont.systemFont(ofSize: 12)
            let dateAttributes: [NSAttributedString.Key: Any] = [
                .font: dateFont,
                .foregroundColor: UIColor.gray
            ]
            
            let dateSize = dateString.boundingRect(
                with: CGSize(width: textWidth, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: dateAttributes,
                context: nil
            ).size
            
            dateString.draw(
                in: CGRect(x: pageMargins.left, y: yPosition, width: textWidth, height: dateSize.height),
                withAttributes: dateAttributes
            )
            
            yPosition += dateSize.height + 30
            
            // Draw separator line
            let linePath = UIBezierPath()
            linePath.move(to: CGPoint(x: pageMargins.left, y: yPosition))
            linePath.addLine(to: CGPoint(x: pageSize.width - pageMargins.right, y: yPosition))
            UIColor.lightGray.setStroke()
            linePath.lineWidth = 1
            linePath.stroke()
            
            yPosition += 20
            
            // Draw main content
            let contentFont = UIFont.systemFont(ofSize: 12)
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 4
            paragraphStyle.alignment = .left
            
            let contentAttributes: [NSAttributedString.Key: Any] = [
                .font: contentFont,
                .foregroundColor: UIColor.black,
                .paragraphStyle: paragraphStyle
            ]
            
            // Split text into paragraphs and draw
            let paragraphs = text.components(separatedBy: "\n\n")
            
            for paragraph in paragraphs {
                let trimmedParagraph = paragraph.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmedParagraph.isEmpty { continue }
                
                let paragraphSize = trimmedParagraph.boundingRect(
                    with: CGSize(width: textWidth, height: .greatestFiniteMagnitude),
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    attributes: contentAttributes,
                    context: nil
                ).size
                
                // Check if need new page
                if yPosition + paragraphSize.height > pageSize.height - pageMargins.bottom {
                    context.beginPage()
                    yPosition = pageMargins.top
                }
                
                trimmedParagraph.draw(
                    in: CGRect(x: pageMargins.left, y: yPosition, width: textWidth, height: paragraphSize.height),
                    withAttributes: contentAttributes
                )
                
                yPosition += paragraphSize.height + 15
            }
            
            // Draw footer on last page
            let footerText = "Generated by OCR App - \(dateString)"
            let footerFont = UIFont.systemFont(ofSize: 10)
            let footerAttributes: [NSAttributedString.Key: Any] = [
                .font: footerFont,
                .foregroundColor: UIColor.gray
            ]
            
            let footerY = pageSize.height - pageMargins.bottom + 20
            footerText.draw(
                at: CGPoint(x: pageMargins.left, y: footerY),
                withAttributes: footerAttributes
            )
        }
        
        return pdfData
    }
}

// MARK: - Custom Errors
enum PDFGenerationError: Error, LocalizedError {
    case emptyText
    case generationFailed
    case saveFailed
    
    var errorDescription: String? {
        switch self {
        case .emptyText:
            return "Cannot generate PDF from empty text"
        case .generationFailed:
            return "Failed to generate PDF"
        case .saveFailed:
            return "Failed to save PDF file"
        }
    }
}

