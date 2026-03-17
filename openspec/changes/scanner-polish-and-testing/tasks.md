## 1. Accessibility - VoiceOver Labels

- [x] 1.1 Add accessibility labels to CameraViewController controls (captureButton: "Take Photo", flashButton: "Flash On"/"Flash Off", cancelButton: "Cancel")
- [x] 1.2 Add accessibility labels to CropViewController controls (resetButton: "Reset Crop", doneButton: "Done", cancelButton: "Cancel")
- [x] 1.3 Add accessibility labels to CornerHandleView with position names ("Top Left Corner", "Top Right Corner", "Bottom Right Corner", "Bottom Left Corner")
- [x] 1.4 Add accessibility labels to ColorModeViewController controls (confirmButton: "Confirm", recropButton: "Re-crop", segmented control segments)
- [x] 1.5 Add accessibility labels to DocumentLibraryViewController controls (scanButton: "Scan Document", sortButton: "Sort Documents") and document cells (filename, date, page count, file size)
- [x] 1.6 Add accessibility labels to SessionReviewViewController controls (addPageButton: "Add Page", savePDFButton: "Save as PDF") and page thumbnail cells
- [x] 1.7 Add accessibility labels to PDFPreviewViewController controls (shareButton: "Share", moreButton: "More Options")

## 2. Accessibility - VoiceOver Announcements and Hints

- [x] 2.1 Post VoiceOver announcement "Photo captured" in CameraViewController after successful photo capture
- [x] 2.2 Post VoiceOver announcement "Document edges detected" or "No document edges found, showing full image" in CropViewController after edge detection completes
- [x] 2.3 Post VoiceOver announcement "Document saved as PDF" in AppCoordinator after successful PDF save
- [x] 2.4 Add accessibility hint "Drag to adjust crop corner" to each CornerHandleView
- [x] 2.5 Add accessibility hint "Double tap to edit. Use drag to reorder." to PageThumbnailCell in SessionReviewViewController

## 3. Accessibility - Dynamic Type and Contrast

- [x] 3.1 Update all UILabel and UIButton fonts to use UIFont.preferredFont(forTextStyle:) with adjustsFontForContentSizeCategory = true in CameraViewController
- [x] 3.2 Update fonts in CropViewController and CropOverlayView for Dynamic Type support
- [x] 3.3 Update fonts in ColorModeViewController for Dynamic Type support
- [x] 3.4 Update fonts in DocumentLibraryViewController and DocumentCell for Dynamic Type support
- [x] 3.5 Update fonts in SessionReviewViewController and PageThumbnailCell for Dynamic Type support
- [x] 3.6 Update fonts in PDFPreviewViewController for Dynamic Type support
- [x] 3.7 Audit all text/background color combinations and ensure WCAG AA 4.5:1 contrast ratio
- [x] 3.8 Verify all buttons have minimum 44x44pt touch targets; add contentEdgeInsets where needed

## 4. Accessibility - Identifiers for UI Testing

- [x] 4.1 Add accessibilityIdentifier to CameraViewController controls (captureButton, flashButton, cameraCancelButton)
- [x] 4.2 Add accessibilityIdentifier to CropViewController controls (resetButton, doneButton, cancelButton, cornerHandles)
- [x] 4.3 Add accessibilityIdentifier to ColorModeViewController controls (segmentedControl, confirmButton, recropButton)
- [x] 4.4 Add accessibilityIdentifier to DocumentLibraryViewController controls (documentList, scanButton, sortButton)
- [x] 4.5 Add accessibilityIdentifier to SessionReviewViewController controls (collectionView, addPageButton, savePDFButton)
- [x] 4.6 Add accessibilityIdentifier to PDFPreviewViewController controls (pdfView, shareButton, moreButton)

## 5. Error Resilience - Corrupt Files and Permissions

- [x] 5.1 Add logging in DocumentStorageService.createMetadata(for:) when a PDF cannot be read (os_log or print for now)
- [x] 5.2 Handle corrupt PDF in PDFPreviewViewController.loadPDF() - show alert with delete option if PDFDocument(url:) returns nil
- [x] 5.3 Add file permission error handling in DocumentStorageService.savePDF - catch permission errors distinctly and surface via StorageError.permissionDenied
- [x] 5.4 Add file permission error handling in DocumentStorageService.deletePDF - surface permission errors to the UI
- [x] 5.5 Show user-facing alert in AppCoordinator/SessionReviewViewController when save fails with permission error

## 6. Error Resilience - Session Interruption and Recovery

- [x] 6.1 Create SessionRecoveryService with methods: saveRecoveryData(), loadRecoveryData(), clearRecoveryData()
- [x] 6.2 Implement saveRecoveryData() - write page images to Caches/SessionRecovery/ and save metadata (page count, color modes, timestamps) to UserDefaults
- [x] 6.3 Implement loadRecoveryData() - read metadata from UserDefaults, load images from Caches/SessionRecovery/, reconstruct ScannedPage array
- [x] 6.4 Implement clearRecoveryData() - remove UserDefaults key and delete Caches/SessionRecovery/ directory
- [x] 6.5 Add applicationDidEnterBackground handler in AppDelegate to call saveRecoveryData() when a session has pages
- [x] 6.6 Add recovery check in AppCoordinator.start() - if recovery data exists, show "Recover session?" alert before displaying library
- [x] 6.7 Wire "Recover" action to load recovery data into ScanSessionManager and navigate to SessionReviewViewController
- [x] 6.8 Wire "Discard" action to call clearRecoveryData() and proceed to library

## 7. Performance - Thumbnail Generation and Caching

- [x] 7.1 Create ThumbnailService with NSCache-backed thumbnail generation (input: UIImage + target CGSize, output: UIImage)
- [x] 7.2 Add generateThumbnail(for:targetSize:completion:) method that runs downsampling on background queue
- [x] 7.3 Update PageThumbnailCell to use ThumbnailService instead of displaying full-resolution croppedImage
- [x] 7.4 Add placeholder image display in PageThumbnailCell while thumbnail is loading
- [x] 7.5 Update DocumentCell to lazy-load PDF first-page thumbnail using ThumbnailService
- [x] 7.6 Add placeholder image display in DocumentCell while thumbnail is loading
- [x] 7.7 Cancel stale thumbnail loads in prepareForReuse() for both PageThumbnailCell and DocumentCell

## 8. UI Polish - Haptic Feedback

- [x] 8.1 Add UIImpactFeedbackGenerator (medium) on photo capture in CameraViewController.capturePhoto()
- [x] 8.2 Add UIImpactFeedbackGenerator (light) on corner drag begin in CropOverlayView.handlePan() .began case
- [x] 8.3 Add UINotificationFeedbackGenerator (warning) on page delete in SessionReviewViewController.deletePage()

## 9. UI Polish - Minor Feature Gaps

- [x] 9.1 Add perspective grid overlay to CropOverlayView - draw 3x3 grid within quadrilateral using CAShapeLayer
- [x] 9.2 Add grid toggle button to CropViewController toolbar
- [x] 9.3 Update grid lines in real-time when corner handles are dragged
- [x] 9.4 Add edit mode to DocumentLibraryViewController - toggle button, selection checkboxes, "Delete Selected" button
- [x] 9.5 Implement bulk delete with confirmation alert in DocumentLibraryViewController
- [x] 9.6 Add real-time filename validation preview to save PDF alert in SessionReviewViewController - show sanitized name below text field
- [x] 9.7 Add PDF generation progress view (UIProgressView) to SessionReviewViewController during save

## 10. Code Quality

- [x] 10.1 Remove all debug print statements from production code across all files
- [x] 10.2 Audit and eliminate remaining force-unwraps (!) - replace with guard-let or optional chaining
- [x] 10.3 Resolve all TODO and FIXME comments in codebase
- [x] 10.4 Remove unused SwiftUI wrapper files (CameraView.swift, CropView.swift, ColorModeView.swift) since app now uses UIKit coordinator
- [x] 10.5 Remove empty Utilities/ and Views/ directories at DocumentScanner/DocumentScanner/ level
- [ ] 10.6 Run SwiftLint once and fix reported warnings (install via brew if needed, do not add as build phase)

## 11. Unit Tests - Services

- [x] 11.1 Create DocumentScannerTests target and test file structure
- [x] 11.2 Write unit tests for EdgeDetectionService - test fallback quadrilateral, test with nil CGImage
- [x] 11.3 Write unit tests for ImageProcessingService - test applyColorMode for each ColorMode, test cropAndCorrect with known corners
- [x] 11.4 Write unit tests for PDFGenerationService - test createPDF with 1 image, test with empty array, test metadata is set
- [x] 11.5 Write unit tests for DocumentStorageService - test savePDF/listDocuments/deletePDF/renamePDF round-trip, test filename sanitization, test duplicate handling
- [x] 11.6 Write unit tests for filename sanitization - test invalid characters, empty string, string that is only extension
- [x] 11.7 Write unit tests for ScanSession model - test addPage, removePage, movePage, updatePageNumbers

## 12. UI Tests - Critical Flows

- [x] 12.1 Create DocumentScannerUITests target
- [x] 12.2 Write UI test for document library flow - launch, verify empty state, verify table loads after documents exist
- [x] 12.3 Write UI test for PDF preview and share - open document, verify PDFView loads, tap share, verify activity controller appears
- [x] 12.4 Write UI test for delete flow - swipe to delete, confirm, verify document removed from list
- [x] 12.5 Write UI test for sort toggle - tap sort, select option, verify order changes

## 13. Release Preparation

- [x] 13.1 Verify Info.plist contains NSCameraUsageDescription and NSPhotoLibraryAddUsageDescription with descriptive strings
- [x] 13.2 Set CFBundleShortVersionString to "1.0.0" and CFBundleVersion to "1"
- [ ] 13.3 Verify app builds successfully with Release configuration
- [x] 13.4 Create placeholder app icon in asset catalog (SF Symbol-based or simple design)
