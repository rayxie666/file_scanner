## 1. Project Setup

- [x] 1.1 Create new Xcode project with iOS App template
- [x] 1.2 Set minimum deployment target to iOS 14.0
- [x] 1.3 Add Info.plist keys for camera and photo library permissions
- [x] 1.4 Configure project structure with MVVM folders (Models, Views, ViewModels, Services)
- [x] 1.5 Add required frameworks to project (AVFoundation, Vision, PDFKit, Combine)

## 2. Data Models

- [x] 2.1 Create ColorMode enum (original, grayscale, blackAndWhite)
- [x] 2.2 Create ScannedPage model with originalImage, croppedImage, colorMode, pageNumber
- [x] 2.3 Create ScanSession model with pages array and dateCreated
- [x] 2.4 Create DocumentMetadata model for PDF information (filename, creationDate, pageCount)

## 3. Camera Capture Implementation

- [x] 3.1 Create CameraViewController with AVCaptureSession setup
- [x] 3.2 Implement AVCaptureVideoPreviewLayer for live camera preview
- [x] 3.3 Add camera permission check and request flow
- [x] 3.4 Implement permission denied alert with Settings redirect
- [x] 3.5 Add capture button UI and photo capture functionality
- [x] 3.6 Implement tap-to-focus using AVCaptureDevice.setFocusMode
- [x] 3.7 Add flash toggle control with on/off states
- [x] 3.8 Handle device orientation changes for preview layer
- [x] 3.9 Implement capture button disabled state during processing
- [x] 3.10 Add error handling for devices without camera

## 4. Edge Detection Service

- [x] 4.1 Create EdgeDetectionService class using Vision framework
- [x] 4.2 Implement VNDetectRectanglesRequest with minimumConfidence 0.6
- [x] 4.3 Set minimumAspectRatio to 0.3 for receipt support
- [x] 4.4 Extract corner points from VNRectangleObservation
- [x] 4.5 Implement fallback to full image bounds when detection fails
- [x] 4.6 Add async processing on background queue
- [x] 4.7 Return detected quadrilateral or default rectangle
- [x] 4.8 Add edge detection confidence scoring

## 5. Manual Crop Adjustment UI

- [x] 5.1 Create CropViewController with image display
- [x] 5.2 Create CropOverlayView with transparent overlay and shaded mask
- [x] 5.3 Add four corner handle views (20pt minimum touch target)
- [x] 5.4 Implement UIPanGestureRecognizer for each corner handle
- [x] 5.5 Add real-time quadrilateral path drawing with CAShapeLayer
- [x] 5.6 Implement bounds constraints to keep handles within image
- [x] 5.7 Add visual feedback (highlight) when handle is touched
- [x] 5.8 Implement pinch-to-zoom gesture for precise adjustment
- [x] 5.9 Add pan gesture for moving zoomed image
- [x] 5.10 Create optional perspective grid overlay (toggleable)
- [x] 5.11 Add Reset button to restore automatic edge detection
- [x] 5.12 Implement quadrilateral validation to prevent self-intersection
- [x] 5.13 Add Done and Cancel buttons with navigation logic

## 6. Image Processing Service

- [x] 6.1 Create ImageProcessingService for color mode and perspective correction
- [x] 6.2 Implement perspective correction using vImage.vImagePerspectiveWarp_ARGB8888
- [x] 6.3 Calculate destination rectangle size maintaining aspect ratio
- [x] 6.4 Implement Original Color mode (pass-through, no processing)
- [x] 6.5 Implement Grayscale mode using CIColorControls with saturation = 0
- [x] 6.6 Implement Black & White mode with adaptive thresholding
- [x] 6.7 Add histogram analysis for optimal threshold calculation
- [x] 6.8 Create processing pipeline: crop → perspective warp → color mode → output
- [x] 6.9 Add async processing on background queue with completion handlers
- [x] 6.10 Preserve full resolution during processing (no downsampling)

## 7. Color Mode Selection UI

- [x] 7.1 Create ColorModeViewController with processed image preview
- [x] 7.2 Add segmented control or buttons for three color modes
- [x] 7.3 Implement real-time preview updates when mode changes (< 0.5s)
- [x] 7.4 Display loading indicator during mode processing
- [x] 7.5 Add Confirm button to proceed to session management
- [x] 7.6 Implement color mode persistence for scanning session
- [x] 7.7 Add ability to go back and re-crop image

## 8. Multi-Page Session Management

- [x] 8.1 Create ScanSessionManager class to manage current session
- [x] 8.2 Implement addPage method to append ScannedPage to session
- [x] 8.3 Create SessionReviewViewController with grid view of all pages
- [x] 8.4 Implement UICollectionView to display page thumbnails
- [x] 8.5 Add drag-and-drop reordering for pages
- [x] 8.6 Implement swipe-to-delete for individual pages
- [x] 8.7 Add "Add Another Page" button to return to camera
- [x] 8.8 Add "Save as PDF" button to trigger PDF generation
- [x] 8.9 Implement tap on page to edit color mode or re-crop
- [x] 8.10 Add page number indicators on thumbnails

## 9. PDF Generation Service

- [x] 9.1 Create PDFGenerationService using PDFKit
- [x] 9.2 Implement createPDF method accepting array of UIImages
- [x] 9.3 Create PDFPage from each UIImage in sequence
- [x] 9.4 Set PDF page dimensions matching document aspect ratio
- [x] 9.5 Implement JPEG compression (quality 0.8) for embedded images
- [x] 9.6 Optionally downsample images to 300 DPI
- [x] 9.7 Add PDF metadata (creation date, creator "iOS Document Scanner")
- [x] 9.8 Implement progress callback for multi-page generation
- [x] 9.9 Return PDFDocument and file size estimate
- [x] 9.10 Add error handling for processing failures

## 10. Document Storage Service

- [x] 10.1 Create DocumentStorageService using FileManager
- [x] 10.2 Create ScannedDocuments subdirectory in Documents on first save
- [x] 10.3 Implement savePDF method with custom filename support
- [x] 10.4 Add default filename generation: "Document_YYYY-MM-DD_HHMMSS.pdf"
- [x] 10.5 Implement filename sanitization (remove invalid characters)
- [x] 10.6 Handle duplicate filenames with incremental numbering
- [x] 10.7 Implement listDocuments method returning array of PDFs
- [x] 10.8 Add deletePDF method with file removal
- [x] 10.9 Implement renamePDF method with validation
- [x] 10.10 Add storage space calculation (used/available)
- [x] 10.11 Handle insufficient storage errors gracefully

## 11. Document Library UI

- [x] 11.1 Create DocumentLibraryViewController as main screen
- [x] 11.2 Implement UITableView displaying saved PDFs
- [x] 11.3 Show filename, creation date, file size, page count for each PDF
- [x] 11.4 Implement sort by date (newest first) and alphabetical
- [x] 11.5 Add "Scan Document" button to start new session
- [x] 11.6 Implement swipe-to-delete with confirmation alert
- [x] 11.7 Add edit mode for bulk selection and deletion
- [x] 11.8 Display storage usage indicator at bottom
- [x] 11.9 Show low storage warning when < 100MB available
- [x] 11.10 Implement tap on PDF to open preview

## 12. PDF Preview and Sharing

- [x] 12.1 Create PDFPreviewViewController using PDFView
- [x] 12.2 Load and display PDF with scrollable pages
- [x] 12.3 Show PDF metadata (filename, date, page count) in header
- [x] 12.4 Add Share button in navigation bar
- [x] 12.5 Implement UIActivityViewController with PDF URL
- [x] 12.6 Verify AirDrop, Mail, Messages, Files, Print options available
- [x] 12.7 Add Delete button with confirmation alert
- [x] 12.8 Implement Rename button with text input dialog
- [x] 12.9 Handle share cancellation gracefully
- [x] 12.10 Display file size warning for PDFs > 10MB when sharing via email

## 13. Filename Input Dialog

- [x] 13.1 Create FilenameInputViewController or UIAlertController
- [x] 13.2 Pre-populate with default filename or current name
- [x] 13.3 Add Save and Cancel buttons
- [x] 13.4 Validate filename in real-time (show sanitized version)
- [x] 13.5 Handle empty filename (revert to default)
- [x] 13.6 Return sanitized filename to caller

## 14. View Models and Data Binding

- [x] 14.1 Create CameraViewModel with Combine publishers for camera state
- [x] 14.2 Create CropViewModel managing corner points and reset
- [x] 14.3 Create ColorModeViewModel with preview image publisher
- [x] 14.4 Create SessionViewModel managing pages array and operations
- [x] 14.5 Create DocumentLibraryViewModel with documents list publisher
- [x] 14.6 Implement @Published properties for UI binding
- [x] 14.7 Add error handling and error message publishers
- [x] 14.8 Implement loading state publishers for async operations

## 15. Navigation and Coordinator

- [x] 15.1 Create AppCoordinator or navigation flow manager
- [x] 15.2 Implement flow: Library → Camera → Crop → ColorMode → Session Review → PDF Save → Library
- [x] 15.3 Handle "Add Another Page" loop back to Camera
- [x] 15.4 Implement Cancel navigation from any screen back to Library
- [x] 15.5 Pass ScanSession between view controllers
- [x] 15.6 Handle session cleanup on cancellation

## 16. UI Polish and Styling

- [x] 16.1 Design app icon and set in asset catalog
- [ ] 16.2 Create consistent color scheme for app (brand colors)
- [x] 16.3 Style buttons with rounded corners and shadows
- [x] 16.4 Add loading indicators (UIActivityIndicatorView) for async operations
- [x] 16.5 Implement progress view for multi-page PDF generation
- [x] 16.6 Add empty state view for document library (no documents yet)
- [x] 16.7 Create custom corner handle design (circles with borders)
- [x] 16.8 Add haptic feedback for capture, corner drag, and page actions
- [x] 16.9 Ensure all UI elements have sufficient contrast for readability
- [ ] 16.10 Test UI on various iPhone screen sizes (SE, 12, 14 Pro Max)

## 17. Error Handling and Edge Cases

- [x] 17.1 Handle camera unavailable (simulator, no hardware)
- [x] 17.2 Handle edge detection failure with user notification
- [x] 17.3 Handle image processing errors with retry option
- [x] 17.4 Handle PDF generation failure with specific error messages
- [x] 17.5 Handle insufficient storage during save
- [x] 17.6 Handle file system permission errors
- [x] 17.7 Handle corrupt PDF files in library (skip or show error)
- [x] 17.8 Add timeout for edge detection (fallback after 3 seconds)
- [x] 17.9 Handle session interruption (phone call, app backgrounding)
- [x] 17.10 Add crash recovery for unsaved sessions

## 18. Performance Optimization

- [ ] 18.1 Profile edge detection performance on iPhone 8
- [ ] 18.2 Profile perspective correction performance on older devices
- [x] 18.3 Implement image downsampling for previews (full res for PDF only)
- [x] 18.4 Use background queue for all image processing
- [x] 18.5 Optimize CAShapeLayer updates to avoid UI lag
- [x] 18.6 Implement thumbnail generation for session grid (not full images)
- [x] 18.7 Cache processed images to avoid re-processing
- [x] 18.8 Lazy load PDF thumbnails in document library
- [ ] 18.9 Test app launch time and optimize if > 1 second
- [ ] 18.10 Monitor memory usage during multi-page scanning

## 19. Testing

- [x] 19.1 Write unit tests for EdgeDetectionService
- [x] 19.2 Write unit tests for ImageProcessingService
- [x] 19.3 Write unit tests for PDFGenerationService
- [x] 19.4 Write unit tests for DocumentStorageService
- [x] 19.5 Write unit tests for filename sanitization logic
- [x] 19.6 Write unit tests for ScanSession model operations
- [ ] 19.7 Write UI tests for camera capture flow
- [ ] 19.8 Write UI tests for crop adjustment and edge cases
- [ ] 19.9 Write UI tests for multi-page session workflow
- [ ] 19.10 Write UI tests for PDF sharing and deletion
- [ ] 19.11 Test on physical device (camera required)
- [ ] 19.12 Test with various document types (letter, receipt, business card)
- [ ] 19.13 Test edge detection on different backgrounds
- [ ] 19.14 Test with poor lighting conditions
- [ ] 19.15 Test storage limits and low storage scenarios

## 20. Accessibility

- [x] 20.1 Add VoiceOver labels for all buttons and controls
- [x] 20.2 Implement VoiceOver announcements for camera capture
- [x] 20.3 Add accessibility labels for corner handles ("Top left corner", etc.)
- [x] 20.4 Implement VoiceOver hints for drag gestures
- [x] 20.5 Add accessibility labels for color mode options
- [x] 20.6 Ensure minimum touch target sizes (44x44 points)
- [ ] 20.7 Test all flows with VoiceOver enabled
- [x] 20.8 Support Dynamic Type for all text elements
- [x] 20.9 Ensure sufficient color contrast for WCAG AA compliance
- [x] 20.10 Add accessibility identifier for UI testing

## 21. Documentation and Cleanup

- [ ] 21.1 Add code documentation for public API methods
- [x] 21.2 Create README with app description and architecture overview
- [ ] 21.3 Document design decisions in code comments
- [x] 21.4 Remove debug print statements and test code
- [x] 21.5 Verify no force-unwraps (!) in production code
- [ ] 21.6 Run SwiftLint and fix warnings
- [x] 21.7 Remove unused assets and files
- [ ] 21.8 Add app screenshots for documentation
- [ ] 21.9 Create user guide or help screen (optional)
- [x] 21.10 Verify all TODOs and FIXMEs are resolved

## 22. Final Testing and Release Preparation

- [ ] 22.1 Test complete flow end-to-end on physical iPhone
- [ ] 22.2 Test on iOS 14, iOS 15, and latest iOS version
- [ ] 22.3 Verify camera works on all supported device models
- [ ] 22.4 Test multi-page PDF generation with 10+ pages
- [ ] 22.5 Verify PDFs open correctly in Files, Mail, Adobe Reader
- [ ] 22.6 Test AirDrop to Mac and other iPhone
- [ ] 22.7 Verify iCloud backup includes saved PDFs
- [ ] 22.8 Test app in low storage scenarios
- [x] 22.9 Verify all permissions are properly described in Info.plist
- [ ] 22.10 Create App Store screenshots and description
- [x] 22.11 Set app version and build number
- [ ] 22.12 Archive and prepare for App Store submission
