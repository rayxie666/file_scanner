## Context

This design document outlines the architecture for a native iOS document scanner application. The app must provide a streamlined workflow for capturing physical documents via camera, processing them with automatic edge detection, allowing manual adjustments, applying color filters, and exporting as PDF files.

**Current State**: Starting from scratch - no existing codebase.

**Constraints**:
- Target iOS 14.0+ for broad device compatibility
- Fully offline - no backend services or network dependencies
- Must work on all iPhone models with camera (no iPad-specific considerations initially)
- Camera and photo library permissions required
- Storage limited to device capacity

**Stakeholders**: End users who need to digitize documents without third-party cloud services.

## Goals / Non-Goals

**Goals:**
- Intuitive single-flow document scanning experience
- High-quality edge detection with manual override capability
- Professional document appearance through color mode processing
- Multi-page document support with PDF output
- Native iOS sharing integration
- Offline-first architecture with local storage

**Non-Goals:**
- Cloud storage or sync functionality
- OCR (text recognition) capabilities
- Document editing beyond cropping and color modes
- iPad-optimized UI (phone-first, iPad compatibility via scaled UI)
- Advanced image editing (rotation, brightness, contrast adjustments)
- Batch processing or automation features

## Decisions

### 1. Application Architecture: MVVM Pattern

**Decision**: Use Model-View-ViewModel (MVVM) architecture with Combine for reactive bindings.

**Rationale**:
- Clear separation of concerns between UI, business logic, and data
- Testability - ViewModels can be unit tested without UI dependencies
- Combine provides reactive data flow for camera preview and processing states
- Scales well for future features

**Alternatives Considered**:
- **MVC**: Simpler but leads to massive view controllers; harder to test
- **SwiftUI + ObservableObject**: Considered but requires iOS 14+ and custom camera implementation is more complex in SwiftUI
- **VIPER**: Over-engineered for this scope; adds unnecessary complexity

### 2. UI Framework: UIKit with SwiftUI for Simple Views

**Decision**: Primary UI in UIKit, with SwiftUI for settings and simple screens.

**Rationale**:
- AVFoundation camera preview integrates naturally with UIKit (AVCaptureVideoPreviewLayer)
- Fine-grained control over custom cropping UI (draggable corner handles)
- UIKit provides better performance for real-time camera preview
- SwiftUI for settings screens reduces boilerplate

**Alternatives Considered**:
- **Pure SwiftUI**: Camera preview requires UIViewRepresentable wrapper; custom gesture handling more complex
- **Pure UIKit**: Viable but misses SwiftUI's declarative benefits for simple screens

### 3. Edge Detection: Vision Framework's VNDetectRectanglesRequest

**Decision**: Use Vision framework's `VNDetectRectanglesRequest` for automatic edge detection.

**Rationale**:
- Built-in, optimized, no third-party dependencies
- Handles perspective distortion well
- Returns normalized coordinates that map directly to image space
- Runs efficiently on device

**Processing Pipeline**:
1. Capture image from AVFoundation → `CVPixelBuffer`
2. Create `VNImageRequestHandler` with pixel buffer
3. Execute `VNDetectRectanglesRequest` with parameters:
   - `minimumConfidence = 0.6` (tunable based on testing)
   - `minimumAspectRatio = 0.3` (allow narrow receipts)
   - `maximumObservations = 1` (return best match only)
4. Extract corner points from `VNRectangleObservation`
5. Fall back to full image bounds if no rectangle detected

**Alternatives Considered**:
- **OpenCV**: More powerful but adds 50MB+ to app size, overkill for this use case
- **Core Image**: Lower-level, requires more custom implementation
- **Third-party ML models**: Unnecessary complexity, Vision framework sufficient

### 4. Manual Crop UI: Custom UIView with Pan Gesture Recognizers

**Decision**: Implement custom cropping overlay with four draggable corner handles.

**Components**:
- Transparent overlay view with shaded mask outside crop region
- Four circular handle views at corners (20pt touch target minimum)
- `UIPanGestureRecognizer` on each handle
- Quadrilateral path drawn between handles (CAShapeLayer)
- Bounds constraint to prevent handles leaving image bounds
- Perspective grid overlay for visual guidance (optional, toggleable)

**Rationale**:
- Native iOS feel with standard gesture patterns
- No third-party dependencies
- Full control over UX (handle size, colors, feedback)

**Alternatives Considered**:
- **Third-party crop libraries** (TOCropViewController): Limited to rectangular crops, not quadrilateral perspective correction

### 5. Image Processing Pipeline: Core Image + vImage

**Decision**: Use Core Image for color mode transformations, vImage for perspective correction.

**Color Mode Implementations**:
- **Original Color**: No processing, use captured image as-is
- **Grayscale**: `CIColorControls` filter with saturation = 0
- **Black & White**: Apply adaptive threshold using `CIColorThreshold` or custom kernel
  - Analyze histogram to determine threshold value per image
  - Ensures text is crisp against white background

**Perspective Correction**:
- Use `vImagePerspectiveWarp_ARGB8888` to transform quadrilateral to rectangle
- Preserves image quality better than affine transforms
- Destination size calculated to maintain aspect ratio

**Pipeline Order**:
1. Capture → `CIImage`
2. Perspective warp using corner points → `CIImage`
3. Apply color mode filter → `CIImage`
4. Render to `UIImage` for preview/storage

**Rationale**:
- Core Image hardware-accelerated on iOS devices
- vImage optimized for geometric transforms
- Both Apple frameworks, well-supported

**Alternatives Considered**:
- **Manual pixel manipulation**: Too slow for real-time preview
- **GPUImage**: Deprecated, no longer maintained

### 6. PDF Generation: PDFKit

**Decision**: Use `PDFKit` to generate multi-page PDFs.

**Implementation**:
```
PDFDocument()
for each processed image:
  - Create PDFPage(image: processedImage)
  - Insert page into document
Write document.dataRepresentation() to file
```

**Page Size**: Use processed image dimensions (preserve aspect ratio), scale to fit standard document sizes (A4/Letter) if needed.

**Rationale**:
- Native framework, no dependencies
- Simple API for multi-page documents
- Produces standard-compliant PDFs

**Alternatives Considered**:
- **Core Graphics PDF context**: Lower-level, more boilerplate
- **Third-party libraries**: Unnecessary for straightforward PDF generation

### 7. Document Storage: FileManager with Documents Directory

**Decision**: Store PDFs in app's Documents directory with user-facing filenames.

**File Structure**:
```
Documents/
  ScannedDocuments/
    Document_2024-01-15_143022.pdf
    Receipt_2024-01-15_150330.pdf
```

**Naming Convention**:
- Default: `Document_<timestamp>.pdf`
- User-editable filename option before saving
- Sanitize filenames (remove invalid characters)

**Metadata**:
- Store JSON metadata alongside PDFs for scan details (optional future enhancement)

**Rationale**:
- Documents directory is backed up by iCloud/iTunes
- Accessible via Files app
- Supports "Open In" and AirDrop

**Alternatives Considered**:
- **Caches directory**: Not backed up, could be purged by system
- **Application Support**: Hidden from user in Files app
- **Core Data**: Overkill for simple file management

### 8. Document Sharing: UIActivityViewController

**Decision**: Use `UIActivityViewController` with PDF file URL.

**Supported Activities**:
- AirDrop
- Save to Files
- Open In (compatible apps)
- Email/Messages (attach PDF)
- Print
- Copy

**Implementation**:
```swift
let activityVC = UIActivityViewController(
    activityItems: [pdfURL],
    applicationActivities: nil
)
present(activityVC, animated: true)
```

**Rationale**:
- Standard iOS sharing pattern
- System handles all available sharing options
- No custom integration needed

**Alternatives Considered**:
- **Custom sharing UI**: Duplicates system functionality
- **Direct AirDrop API**: More complex, no benefit over activity view

### 9. Multi-Page Workflow: Session-Based Scanning

**Decision**: Implement scanning session model where user can add multiple pages before finalizing PDF.

**User Flow**:
1. Tap "Scan Document" → Start session
2. Capture page → Preview → Approve/Retake
3. Tap "Add Another Page" or "Done"
4. If "Add Another Page" → Loop to step 2
5. If "Done" → Show all pages in grid view
6. User can reorder, delete, or rescan pages
7. Tap "Save as PDF" → Choose filename → Generate PDF

**Data Model**:
```swift
class ScanSession {
    var pages: [ScannedPage]
    var dateCreated: Date
}

struct ScannedPage {
    let originalImage: UIImage
    let croppedImage: UIImage
    let colorMode: ColorMode
    var pageNumber: Int
}
```

**Rationale**:
- Matches common document scanning mental model
- Allows corrections before finalizing
- Supports multi-page documents naturally

**Alternatives Considered**:
- **Single-page only**: Simpler but less useful for multi-page documents
- **Auto-save after each capture**: No way to discard failed scans

### 10. Permissions Handling: On-Demand Request with Explanations

**Decision**: Request camera permission when user first taps "Scan Document", with clear usage description.

**Info.plist Keys**:
- `NSCameraUsageDescription`: "Camera access is required to scan documents."
- `NSPhotoLibraryAddUsageDescription`: "Save processed document images." (if adding photo library save feature)

**Flow**:
- Check permission status before showing camera
- If denied → Show alert with instructions to enable in Settings
- If restricted → Show alert explaining limitation

**Rationale**:
- Just-in-time permission requests improve approval rates
- Contextual explanations reduce confusion
- Graceful degradation when permissions denied

## Risks / Trade-offs

### Risk: Edge Detection Accuracy on Complex Backgrounds
**Impact**: Vision framework may fail to detect document edges on patterned surfaces or in poor lighting.

**Mitigation**:
- Always allow manual adjustment as fallback
- Provide visual feedback when automatic detection succeeds/fails
- Consider adding guidelines/tips for best capture conditions
- Test extensively with various document types and backgrounds

### Risk: Image Processing Performance on Older Devices
**Impact**: Perspective correction and color mode processing may be slow on iPhone 8 and earlier.

**Mitigation**:
- Process images asynchronously on background queue
- Show loading indicator during processing
- Test on oldest supported device (iPhone 8 running iOS 14)
- Consider reducing image resolution for preview (full resolution for PDF)

### Trade-off: UIKit vs Pure SwiftUI
**Impact**: Mixed framework approach adds complexity, requires bridging between UIKit and SwiftUI.

**Justification**: UIKit's camera integration and custom gesture handling are more mature. The complexity is isolated to view layer, business logic remains framework-agnostic.

### Risk: PDF File Size with High-Resolution Images
**Impact**: Multi-page PDFs with full-resolution photos can be large (10MB+ for 10 pages).

**Mitigation**:
- Compress images before PDF generation (JPEG compression, quality 0.8)
- Optionally downsample images to 300 DPI (sufficient for document scanning)
- Show file size estimate before saving
- Consider future enhancement: quality settings

### Trade-off: Local Storage Only (No Cloud Sync)
**Impact**: Users can lose documents if they don't manually back up or share them.

**Justification**: Aligns with privacy-first approach (no network requirement). Users can use iCloud backup or share via AirDrop/Files app. Future enhancement could add optional iCloud Drive integration.

### Risk: Quadrilateral Corner Selection UX Complexity
**Impact**: Users may find manual corner adjustment difficult, especially on small screens.

**Mitigation**:
- Large touch targets (20pt minimum) for corner handles
- Visual feedback (handles highlight on touch)
- Zoom capability for precise adjustment
- Default to automatic detection (manual adjustment is optional refinement)
- User testing to validate UX

## Open Questions

1. **Should we support document templates** (e.g., business card, receipt, A4)? Could improve edge detection accuracy.

2. **Image resolution for PDF generation**: Should we downsample to 300 DPI or preserve original camera resolution? Trade-off between file size and quality.

3. **Undo/redo for multi-page sessions**: Is it necessary for v1, or can we rely on delete + rescan?

4. **Accessibility support**: What VoiceOver announcements and gestures should we support for camera and crop adjustment?

5. **Localization**: Which languages should be supported in v1? Does this affect OCR roadmap?
