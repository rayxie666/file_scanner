## Context

The DocumentScanner app currently supports a single document input method: camera capture via `CameraViewController`. The flow is:
1. User taps scan FAB → `startScanningFlow()` → Camera
2. Camera captures image → Crop → ColorMode → SessionReview
3. Session saved as PDF to library

This change adds a parallel entry point for file uploads (photo library + document picker) that feeds into the same crop/color mode/review pipeline.

**Current architecture:**
- `AppCoordinator` manages all navigation via delegate protocols
- Modal presentation used for scanning flow (camera → crop → colorMode)
- Push navigation for library → session review → PDF preview
- `ScanSessionManager` accumulates pages during a session
- `ImageProcessingService` handles perspective correction and color modes (works with any `UIImage`)

## Goals / Non-Goals

**Goals:**
- Add file upload entry point parallel to camera scanning
- Support PHPickerViewController for photo library access
- Support UIDocumentPickerViewController for files (images + PDFs)
- Integrate uploaded images into existing crop → color mode → session review flow
- Handle PDF imports by extracting pages as images
- Maintain consistent UX with camera scanning flow

**Non-Goals:**
- Cloud storage integration (iCloud Drive access comes free via document picker)
- Batch upload UI (single selection for MVP, multi-select can come later)
- Advanced PDF manipulation (merging, splitting existing PDFs)
- Image editing beyond existing crop/color modes

## Decisions

### 1. UI Entry Point: Second FAB Button

**Decision:** Add an upload FAB button to the left of the existing scan FAB in `DocumentLibraryViewController`.

**Rationale:**
- Maintains visual consistency with existing camera FAB
- Clear separation of actions (camera vs upload)
- Follows iOS design patterns for primary actions
- Alternative considered: Single FAB with action sheet for "Scan" vs "Upload" - rejected because it adds an extra tap for the common scanning case

### 2. File Source Selection: Action Sheet

**Decision:** Present an action sheet with options: "Photo Library" and "Choose File" when upload FAB is tapped.

**Rationale:**
- Familiar iOS pattern for source selection
- Allows future extension (e.g., "From URL")
- Alternative considered: Segmented control in a bottom sheet - rejected as overly complex for two options

### 3. Photo Picker: PHPickerViewController

**Decision:** Use `PHPickerViewController` (iOS 14+) for photo library access.

**Rationale:**
- Modern replacement for `UIImagePickerController`
- No permission prompt required for limited access (privacy-first design)
- Built-in multi-select support for future enhancement
- Alternative considered: `UIImagePickerController` - rejected as deprecated approach

### 4. Document Picker: UIDocumentPickerViewController

**Decision:** Use `UIDocumentPickerViewController` in import mode for file selection.

**Rationale:**
- Native iOS file picker with iCloud/local file access
- Supports content types filtering (images + PDFs)
- Alternative considered: Custom file browser - rejected as unnecessary complexity

### 5. PDF Page Extraction

**Decision:** Use PDFKit's `PDFDocument` and `PDFPage.thumbnail(of:for:)` to render PDF pages as images for processing.

**Rationale:**
- Native iOS framework, no external dependencies
- Consistent rendering quality
- Alternative considered: Core Graphics PDF rendering - PDFKit is higher-level and sufficient

### 6. Flow Integration: Direct to Crop (Skip Camera)

**Decision:** Uploaded images bypass the camera and go directly to `CropViewController`, then continue the normal flow.

**Rationale:**
- Camera is irrelevant for already-captured images
- Reuses 100% of existing crop → colorMode → sessionReview code
- `AppCoordinator` already has `showCrop(with:)` method

### 7. Multi-Page PDF Import

**Decision:** When importing a PDF, extract all pages as images and add each to the session sequentially without individual crop/color selection. Use original color mode and skip cropping for PDF pages.

**Rationale:**
- PDF pages are already properly framed/cropped
- Cropping each page individually would be tedious for multi-page docs
- User can delete unwanted pages in session review
- Alternative considered: Per-page crop/color flow - rejected for UX reasons

### 8. New Coordinator Methods

**Decision:** Add the following to `AppCoordinator`:
- `startUploadFlow()` - shows file source action sheet
- `showPhotoPicker()` - presents PHPickerViewController
- `showDocumentPicker()` - presents UIDocumentPickerViewController
- Extend `DocumentLibraryViewControllerDelegate` with `documentLibraryDidRequestUpload(_:)`

**Rationale:**
- Follows existing coordinator pattern
- Clean separation of concerns
- Delegate extension keeps library view controller decoupled

## Risks / Trade-offs

**Risk:** Large PDF files may cause memory pressure when extracting all pages as images.
→ **Mitigation:** Process pages one at a time, release each after adding to session. Consider page count limit warning for PDFs > 20 pages.

**Risk:** PHPicker doesn't provide direct UIImage access for some asset types (HEIC, Live Photos).
→ **Mitigation:** Use `loadObject(ofClass: UIImage.self)` with proper async handling. PHPicker handles format conversion automatically.

**Risk:** Uploaded images may be very large (high-res photos from external sources).
→ **Mitigation:** Existing `ImageProcessingService` already handles large images. Consider adding max dimension scaling if performance issues arise.

**Risk:** Permission denial for photo library access.
→ **Mitigation:** PHPickerViewController doesn't require permission for selection. Only add `NSPhotoLibraryUsageDescription` for legacy compatibility. UIDocumentPickerViewController also doesn't require special permissions.

**Trade-off:** PDF pages skip crop/color mode flow.
→ **Accepted:** Better UX for multi-page imports. Users who need to adjust can delete and re-add pages individually.
