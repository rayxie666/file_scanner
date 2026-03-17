## 1. UI Setup

- [x] 1.1 Add upload FAB button to DocumentLibraryViewController alongside existing camera FAB
- [x] 1.2 Style upload FAB to match camera FAB visual design (size, shadow, colors)
- [x] 1.3 Position upload FAB to the left of camera FAB with appropriate spacing
- [x] 1.4 Add upload button tap handler that calls delegate method

## 2. Coordinator & Delegate Setup

- [x] 2.1 Add `documentLibraryDidRequestUpload(_:)` method to DocumentLibraryViewControllerDelegate protocol
- [x] 2.2 Implement delegate method in AppCoordinator to call `startUploadFlow()`
- [x] 2.3 Add `startUploadFlow()` method to AppCoordinator that presents source selection action sheet
- [x] 2.4 Add `showPhotoPicker()` method to AppCoordinator
- [x] 2.5 Add `showDocumentPicker()` method to AppCoordinator

## 3. Photo Picker Implementation

- [x] 3.1 Configure PHPickerViewController with image filter and multi-selection enabled
- [x] 3.2 Implement PHPickerViewControllerDelegate in AppCoordinator
- [x] 3.3 Handle image loading from PHPickerResult using loadObject(ofClass: UIImage.self)
- [x] 3.4 Handle picker cancellation (user dismisses without selection)
- [x] 3.5 Store selected images and navigate to crop flow for first image

## 4. Document Picker Implementation

- [x] 4.1 Configure UIDocumentPickerViewController in import mode with supported UTTypes (JPEG, PNG, HEIC, PDF)
- [x] 4.2 Implement UIDocumentPickerDelegate in AppCoordinator
- [x] 4.3 Handle file URL access with security-scoped resource access
- [x] 4.4 Detect file type from URL and route to appropriate handler (image vs PDF)
- [x] 4.5 Handle picker cancellation (user dismisses without selection)

## 5. PDF Processing

- [x] 5.1 Create PDFImportService (or extend existing service) for PDF page extraction
- [x] 5.2 Implement page extraction using PDFKit's PDFDocument and PDFPage.thumbnail(of:for:)
- [x] 5.3 Handle single-page PDF: extract page and route to crop flow
- [x] 5.4 Handle multi-page PDF: extract all pages and create session directly
- [x] 5.5 Add memory management for large PDFs (process pages sequentially, release after use)

## 6. Flow Integration

- [x] 6.1 Route uploaded single images to existing CropViewController via showCrop(with:)
- [x] 6.2 Handle multi-image uploads: queue images and process sequentially through crop/color flow
- [x] 6.3 For multi-page PDFs: add all pages to ScanSessionManager and navigate to SessionReviewViewController
- [x] 6.4 Ensure uploaded images flow through color mode selection after crop

## 7. Error Handling

- [x] 7.1 Add error alert for unsupported file types
- [x] 7.2 Add error alert for file read/processing failures
- [x] 7.3 Add error alert for PDF extraction failures
- [x] 7.4 Handle photo library permission denied case with Settings redirect option

## 8. Configuration

- [x] 8.1 Add NSPhotoLibraryUsageDescription to Info.plist with appropriate description
- [x] 8.2 Verify UTType imports are available (UniformTypeIdentifiers framework)
