import SwiftUI
import UIKit

struct ImageEditorView: View {
    let originalImage: UIImage
    let conversionType: ConversionType
    @State private var editedImage: UIImage
    @State private var showingCropView = false
    @StateObject private var mainViewModel = MainViewModel.shared
    @StateObject private var themeManager = ThemeManager.shared
    
    init(originalImage: UIImage, conversionType: ConversionType) {
        self.originalImage = originalImage
        self.conversionType = conversionType
        self._editedImage = State(initialValue: originalImage)
    }
    
    var body: some View {
        ZStack {
            themeManager.currentTheme.backgroundGradient
                .ignoresSafeArea(.all)
            
            VStack(spacing: 20) {
                // Header
                headerSection
                
                // Image Display
                imageDisplaySection
                
                // Controls
                controlsSection
                
                Spacer()
                
                // Action Buttons
                actionButtonsSection
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
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
                Text("Crop Image")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.currentTheme.textColor)
            }
        }
        .fullScreenCover(isPresented: $showingCropView) {
            CleanCropView(image: editedImage) { croppedImage in
                editedImage = croppedImage
                showingCropView = false
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "crop")
                .font(.system(size: 60))
                .foregroundColor(themeManager.currentTheme.textColor)
                .frame(width: 100, height: 100)
                .background(
                    Circle()
                        .fill(themeManager.currentTheme.cardBackground)
                )
            
            Text("Crop Your Image")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.currentTheme.textColor)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Image Display Section
    private var imageDisplaySection: some View {
        VStack(spacing: 16) {
            Text("Image Preview")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.currentTheme.textColor)
            
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeManager.currentTheme.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(themeManager.currentTheme.inputFieldBorder, lineWidth: 1)
                    )
                
                Image(uiImage: editedImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(20)
            }
            .frame(maxHeight: 400)
        }
    }
    
    // MARK: - Controls Section
    private var controlsSection: some View {
        VStack(spacing: 20) {
            // Crop Button
            Button(action: {
                showingCropView = true
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "crop")
                        .font(.title3)
                    
                    Text("Crop Image")
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
            
            // Instructions
            VStack(spacing: 8) {
                Text("Instructions")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.currentTheme.textColor)
                
                Text("Tap 'Crop Image' to open the cropping tool. Drag the corners to adjust the crop area and select the portion of the image you want to keep.")
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .background(themeManager.currentTheme.cardBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(themeManager.currentTheme.inputFieldBorder, lineWidth: 1)
        )
    }
    
    // MARK: - Action Buttons Section
    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            // Continue Button
            Button(action: {
                mainViewModel.navigateToFormatSelection(image: editedImage, conversionType: conversionType)
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "arrow.right")
                        .font(.title3)
                    
                    Text("Continue to Format Selection")
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
}

// MARK: - Clean Crop View
struct CleanCropView: View {
    let image: UIImage
    let onCrop: (UIImage) -> Void
    @Environment(\.presentationMode) private var presentationMode
    @State private var cropRect = CGRect.zero
    @State private var imageFrame = CGRect.zero
    @State private var isDragging = false
    @State private var initialCropRect = CGRect.zero
    @State private var activeCorner: Int? = nil
    
    private let minCropSize: CGFloat = 80
    private let dragSensitivity: CGFloat = 0.5 // Keep our smooth sensitivity
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack {
                    // Background
                    Color.black.edgesIgnoringSafeArea(.all)
                    
                    // Image
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .background(
                            GeometryReader { imageGeometry in
                                Color.clear
                                    .onAppear {
                                        setupInitialCropRect(in: geometry.size, imageGeometry: imageGeometry)
                                    }
                            }
                        )
                        .overlay(
                            // Dark overlay with crop hole
                            CropOverlay(cropRect: cropRect)
                                .fill(style: FillStyle(eoFill: true))
                                .foregroundColor(Color.black.opacity(0.6))
                        )
                    
                    // Crop border with grid lines and smooth animations
                    ZStack {
                        Rectangle()
                            .stroke(Color.white, lineWidth: 2)
                        
                        // Grid lines for better composition (rule of thirds)
                        Path { path in
                            // Vertical lines
                            let thirdWidth = cropRect.width / 3
                            for i in 1..<3 {
                                let x = thirdWidth * CGFloat(i)
                                path.move(to: CGPoint(x: x, y: 0))
                                path.addLine(to: CGPoint(x: x, y: cropRect.height))
                            }
                            
                            // Horizontal lines
                            let thirdHeight = cropRect.height / 3
                            for i in 1..<3 {
                                let y = thirdHeight * CGFloat(i)
                                path.move(to: CGPoint(x: 0, y: y))
                                path.addLine(to: CGPoint(x: cropRect.width, y: y))
                            }
                        }
                        .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
                    }
                    .frame(width: cropRect.width, height: cropRect.height)
                    .position(x: cropRect.midX, y: cropRect.midY)
                    .animation(.interactiveSpring(response: 0.6, dampingFraction: 0.8), value: cropRect)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                if !isDragging {
                                    isDragging = true
                                    initialCropRect = cropRect
                                }
                                
                                // Apply sensitivity for smoother movement
                                let translation = CGSize(
                                    width: value.translation.width * dragSensitivity,
                                    height: value.translation.height * dragSensitivity
                                )
                                
                                var newX = initialCropRect.origin.x + translation.width
                                var newY = initialCropRect.origin.y + translation.height
                                
                                // Constrain to image bounds
                                newX = max(imageFrame.minX, min(imageFrame.maxX - cropRect.width, newX))
                                newY = max(imageFrame.minY, min(imageFrame.maxY - cropRect.height, newY))
                                
                                withAnimation(.interactiveSpring(response: 0.4, dampingFraction: 0.8)) {
                                    cropRect.origin.x = newX
                                    cropRect.origin.y = newY
                                }
                            }
                            .onEnded { _ in
                                isDragging = false
                            }
                    )
                    
                    // Corner handles with smooth animations
                    ForEach(0..<4) { corner in
                        CornerHandle()
                            .position(cornerPosition(for: corner))
                            .animation(.interactiveSpring(response: 0.6, dampingFraction: 0.8), value: cropRect)
                            .gesture(cornerGesture(for: corner))
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .principal) {
                    Text("Crop Image")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        performCrop()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                }
            }
            .toolbarBackground(Color.black.opacity(0.9), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
    
    private func setupInitialCropRect(in viewSize: CGSize, imageGeometry: GeometryProxy) {
        // Calculate image frame
        let imageSize = image.size
        let imageAspect = imageSize.width / imageSize.height
        let viewAspect = viewSize.width / viewSize.height
        
        var frameSize: CGSize
        var frameOrigin: CGPoint
        
        if imageAspect > viewAspect {
            // Image is wider - fit to width
            frameSize = CGSize(width: viewSize.width, height: viewSize.width / imageAspect)
            frameOrigin = CGPoint(x: 0, y: (viewSize.height - frameSize.height) / 2)
        } else {
            // Image is taller - fit to height
            frameSize = CGSize(width: viewSize.height * imageAspect, height: viewSize.height)
            frameOrigin = CGPoint(x: (viewSize.width - frameSize.width) / 2, y: 0)
        }
        
        imageFrame = CGRect(origin: frameOrigin, size: frameSize)
        
        // Set initial crop rect to 75% of image
        let cropWidth = frameSize.width * 0.75
        let cropHeight = frameSize.height * 0.75
        let cropX = frameOrigin.x + (frameSize.width - cropWidth) / 2
        let cropY = frameOrigin.y + (frameSize.height - cropHeight) / 2
        
        withAnimation(.easeOut(duration: 0.8)) {
            cropRect = CGRect(x: cropX, y: cropY, width: cropWidth, height: cropHeight)
        }
    }
    
    private func cornerPosition(for corner: Int) -> CGPoint {
        switch corner {
        case 0: return CGPoint(x: cropRect.minX, y: cropRect.minY) // Top-left
        case 1: return CGPoint(x: cropRect.maxX, y: cropRect.minY) // Top-right
        case 2: return CGPoint(x: cropRect.minX, y: cropRect.maxY) // Bottom-left
        case 3: return CGPoint(x: cropRect.maxX, y: cropRect.maxY) // Bottom-right
        default: return .zero
        }
    }
    
    private func cornerGesture(for corner: Int) -> some Gesture {
        DragGesture()
            .onChanged { value in
                if activeCorner == nil {
                    activeCorner = corner
                    initialCropRect = cropRect
                }
                
                guard activeCorner == corner else { return }
                
                var newRect = initialCropRect
                
                // Apply sensitivity for smoother resizing
                let translation = CGSize(
                    width: value.translation.width * dragSensitivity,
                    height: value.translation.height * dragSensitivity
                )
                
                switch corner {
                case 0: // Top-left
                    let newX = initialCropRect.origin.x + translation.width
                    let newY = initialCropRect.origin.y + translation.height
                    
                    // Constrain X
                    newRect.origin.x = max(imageFrame.minX, min(initialCropRect.maxX - minCropSize, newX))
                    // Constrain Y
                    newRect.origin.y = max(imageFrame.minY, min(initialCropRect.maxY - minCropSize, newY))
                    // Update size
                    newRect.size.width = initialCropRect.maxX - newRect.origin.x
                    newRect.size.height = initialCropRect.maxY - newRect.origin.y
                    
                case 1: // Top-right
                    let newWidth = initialCropRect.width + translation.width
                    let newY = initialCropRect.origin.y + translation.height
                    
                    // Constrain Y
                    newRect.origin.y = max(imageFrame.minY, min(initialCropRect.maxY - minCropSize, newY))
                    // Constrain width
                    newRect.size.width = max(minCropSize, min(imageFrame.maxX - initialCropRect.origin.x, newWidth))
                    // Update height
                    newRect.size.height = initialCropRect.maxY - newRect.origin.y
                    
                case 2: // Bottom-left
                    let newX = initialCropRect.origin.x + translation.width
                    let newHeight = initialCropRect.height + translation.height
                    
                    // Constrain X
                    newRect.origin.x = max(imageFrame.minX, min(initialCropRect.maxX - minCropSize, newX))
                    // Update width
                    newRect.size.width = initialCropRect.maxX - newRect.origin.x
                    // Constrain height
                    newRect.size.height = max(minCropSize, min(imageFrame.maxY - initialCropRect.origin.y, newHeight))
                    
                case 3: // Bottom-right
                    let newWidth = initialCropRect.width + translation.width
                    let newHeight = initialCropRect.height + translation.height
                    
                    // Constrain width
                    newRect.size.width = max(minCropSize, min(imageFrame.maxX - initialCropRect.origin.x, newWidth))
                    // Constrain height
                    newRect.size.height = max(minCropSize, min(imageFrame.maxY - initialCropRect.origin.y, newHeight))
                    
                default: break
                }
                
                // Final boundary check
                newRect.origin.x = max(imageFrame.minX, newRect.origin.x)
                newRect.origin.y = max(imageFrame.minY, newRect.origin.y)
                newRect.size.width = min(newRect.width, imageFrame.maxX - newRect.origin.x)
                newRect.size.height = min(newRect.height, imageFrame.maxY - newRect.origin.y)
                
                withAnimation(.interactiveSpring(response: 0.4, dampingFraction: 0.8)) {
                    cropRect = newRect
                }
            }
            .onEnded { _ in
                activeCorner = nil
            }
    }
    
    private func performCrop() {
        // Fix image orientation first
        let orientedImage = image.fixedOrientation()
        
        // Calculate scale factors
        let scaleX = orientedImage.size.width / imageFrame.width
        let scaleY = orientedImage.size.height / imageFrame.height
        
        // Convert crop rect to image coordinates
        let relativeRect = CGRect(
            x: (cropRect.origin.x - imageFrame.origin.x) * scaleX,
            y: (cropRect.origin.y - imageFrame.origin.y) * scaleY,
            width: cropRect.width * scaleX,
            height: cropRect.height * scaleY
        )
        
        // Ensure rect is within image bounds
        let finalRect = CGRect(
            x: max(0, min(relativeRect.origin.x, orientedImage.size.width - relativeRect.width)),
            y: max(0, min(relativeRect.origin.y, orientedImage.size.height - relativeRect.height)),
            width: min(relativeRect.width, orientedImage.size.width),
            height: min(relativeRect.height, orientedImage.size.height)
        )
        
        // Perform crop
        if let cgImage = orientedImage.cgImage?.cropping(to: finalRect) {
            let croppedImage = UIImage(cgImage: cgImage, scale: orientedImage.scale, orientation: .up)
            onCrop(croppedImage)
            presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - UIImage Extension for Orientation Fix
extension UIImage {
    func fixedOrientation() -> UIImage {
        if imageOrientation == .up {
            return self
        }
        
        var transform = CGAffineTransform.identity
        
        switch imageOrientation {
        case .down, .downMirrored:
            transform = transform.translatedBy(x: size.width, y: size.height)
            transform = transform.rotated(by: .pi)
        case .left, .leftMirrored:
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.rotated(by: .pi / 2)
        case .right, .rightMirrored:
            transform = transform.translatedBy(x: 0, y: size.height)
            transform = transform.rotated(by: -.pi / 2)
        default:
            break
        }
        
        switch imageOrientation {
        case .upMirrored, .downMirrored:
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        case .leftMirrored, .rightMirrored:
            transform = transform.translatedBy(x: size.height, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        default:
            break
        }
        
        guard let cgImage = cgImage,
              let colorSpace = cgImage.colorSpace,
              let ctx = CGContext(
                data: nil,
                width: Int(size.width),
                height: Int(size.height),
                bitsPerComponent: cgImage.bitsPerComponent,
                bytesPerRow: 0,
                space: colorSpace,
                bitmapInfo: cgImage.bitmapInfo.rawValue
              ) else {
            return self
        }
        
        ctx.concatenate(transform)
        
        switch imageOrientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.height, height: size.width))
        default:
            ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        }
        
        guard let newCGImage = ctx.makeImage() else {
            return self
        }
        
        return UIImage(cgImage: newCGImage)
    }
}

// MARK: - Crop Overlay
struct CropOverlay: Shape {
    let cropRect: CGRect
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addRect(rect)
        path.addRect(cropRect)
        return path
    }
}

// MARK: - Corner Handle
struct CornerHandle: View {
    var body: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(Color.white.opacity(0.3))
                .frame(width: 32, height: 32)
                .blur(radius: 2)
            
            // Main handle
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.white, Color.white.opacity(0.9)],
                        center: .center,
                        startRadius: 0,
                        endRadius: 12
                    )
                )
                .frame(width: 24, height: 24)
                .shadow(color: .black.opacity(0.4), radius: 3, x: 0, y: 2)
            
            // Inner accent
            Circle()
                .fill(Color.blue.opacity(0.6))
                .frame(width: 8, height: 8)
        }
        .frame(width: 48, height: 48) // Larger hit area for easier interaction
        .contentShape(Circle())
    }
}

#Preview {
    ImageEditorView(originalImage: UIImage(), conversionType: .cameraToPdf)
}
