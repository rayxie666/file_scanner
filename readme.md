# iOS Document Scanner

A native iOS application for scanning physical documents using iPhone camera with automatic edge detection, manual adjustment, and PDF generation capabilities.

## Features

- **Camera Document Capture**: Live camera preview with tap-to-focus and flash control
- **Automatic Edge Detection**: Uses Vision framework to automatically detect document boundaries
- **Manual Crop Adjustment**: Draggable corner handles for precise crop adjustments
- **Color Modes**: Original color, grayscale, and black & white processing options
- **Multi-Page Scanning**: Scan multiple pages into a single PDF document
- **PDF Generation**: High-quality PDF output with compression
- **Local Storage**: Save PDFs to device with iCloud backup support
- **Document Sharing**: Share via AirDrop, Mail, Messages, Files app, and more

## Requirements

- iOS 14.0+
- Xcode 12.0+
- Swift 5.0+
- iPhone with camera

## Architecture

The app follows **MVVM (Model-View-ViewModel)** architecture pattern with Combine for reactive data binding.

### Project Structure

```
DocumentScanner/
├── Models/
│   ├── ColorMode.swift
│   ├── ScannedPage.swift
│   ├── ScanSession.swift
│   └── DocumentMetadata.swift
├── Views/
│   └── (View controllers to be implemented)
├── ViewModels/
│   ├── CameraViewModel.swift
│   ├── CropViewModel.swift
│   ├── ColorModeViewModel.swift
│   ├── SessionViewModel.swift
│   └── DocumentLibraryViewModel.swift
├── Services/
│   ├── EdgeDetectionService.swift
│   ├── ImageProcessingService.swift
│   ├── PDFGenerationService.swift
│   ├── DocumentStorageService.swift
│   └── ScanSessionManager.swift
└── Utilities/
```

## Key Components

### Services

#### EdgeDetectionService
Uses Vision framework's `VNDetectRectanglesRequest` to automatically detect document edges with:
- Minimum confidence threshold: 0.6
- Minimum aspect ratio: 0.3 (supports receipts)
- Fallback to full image bounds when detection fails
- 3-second timeout with automatic fallback

#### ImageProcessingService
Handles image processing with:
- Perspective correction using Core Image filters
- Color mode transformations (original, grayscale, black & white)
- Adaptive thresholding for B&W mode
- Async processing on background queue
- Full resolution preservation

#### PDFGenerationService
Generates multi-page PDFs with:
- PDFKit integration
- JPEG compression (quality 0.8)
- Optional 300 DPI downsampling
- Progress callbacks
- PDF metadata (creation date, creator)

#### DocumentStorageService
Manages PDF storage with:
- Documents/ScannedDocuments directory structure
- Filename sanitization and duplicate handling
- CRUD operations (create, read, update, delete)
- Storage space monitoring
- iCloud backup support

### ViewModels

All ViewModels use `@Published` properties for Combine-based reactive UI updates:

- **CameraViewModel**: Camera state, permissions, flash control
- **CropViewModel**: Quadrilateral points, corner dragging, reset functionality
- **ColorModeViewModel**: Color mode selection, real-time preview updates
- **SessionViewModel**: Page management, PDF generation coordination
- **DocumentLibraryViewModel**: Document list, sorting, storage info

## User Flow

1. **Document Library** → Main screen showing saved PDFs
2. **Camera Capture** → Live preview with tap-to-focus and capture button
3. **Edge Detection** → Automatic detection with visual overlay
4. **Crop Adjustment** → Manual corner adjustment with zoom support
5. **Color Mode Selection** → Choose original, grayscale, or B&W
6. **Session Review** → View all scanned pages, reorder, delete, or add more
7. **PDF Generation** → Enter filename and save as PDF
8. **Back to Library** → PDF appears in document list

## Setup Instructions

### 1. Create Xcode Project

1. Open Xcode
2. Create new project: File → New → Project
3. Select "iOS App" template
4. Product Name: DocumentScanner
5. Interface: UIKit (with Storyboard or Programmatic UI)
6. Language: Swift
7. Set Minimum Deployment Target: iOS 14.0

### 2. Import Source Files

1. Copy the `DocumentScanner` folder into your Xcode project
2. Drag and drop all Swift files into Xcode
3. Ensure files are added to the app target
4. Verify files are in appropriate groups (Models, Views, ViewModels, Services)

### 3. Configure Info.plist

Add required permission keys (see `DocumentScanner/Info.plist.template`):
- `NSCameraUsageDescription`: "Camera access is required to scan documents."
- Set `MinimumOSVersion` to 14.0

### 4. Add Frameworks

Ensure these frameworks are linked (they should be automatically available):
- AVFoundation
- Vision
- PDFKit
- Combine
- UIKit
- CoreImage
- Accelerate

### 5. Configure Build Settings

- Deployment Target: iOS 14.0
- Swift Language Version: Swift 5.0

## Implementation Status

### Completed ✅
- ✅ Project folder structure (Models, Views, ViewModels, Services, Utilities)
- ✅ Data models (ColorMode, ScannedPage, ScanSession, DocumentMetadata)
- ✅ Edge Detection Service (Vision framework integration)
- ✅ Image Processing Service (perspective correction, color modes)
- ✅ PDF Generation Service (PDFKit integration)
- ✅ Document Storage Service (file management)
- ✅ Scan Session Manager
- ✅ All ViewModels (Camera, Crop, ColorMode, Session, DocumentLibrary)
- ✅ Info.plist template with permissions
- ✅ README documentation

### Pending 🚧
- ⏳ View Controllers UI implementation
- ⏳ Camera capture UI with AVFoundation
- ⏳ Crop overlay UI with gesture recognizers
- ⏳ Session review collection view
- ⏳ Document library table view
- ⏳ PDF preview integration
- ⏳ Navigation coordinator
- ⏳ UI polish and styling
- ⏳ Error handling UI
- ⏳ Accessibility features
- ⏳ Testing (unit tests, UI tests)

## Dependencies

All dependencies are native iOS frameworks:
- **AVFoundation**: Camera capture and preview
- **Vision**: Edge detection
- **Core Image**: Image processing filters
- **Accelerate**: High-performance image operations
- **PDFKit**: PDF generation and viewing
- **Combine**: Reactive data binding
- **UIKit**: User interface

**No third-party dependencies required!**

## Testing

### Unit Tests
- EdgeDetectionService tests
- ImageProcessingService tests
- PDFGenerationService tests
- DocumentStorageService tests
- ViewModel tests

### UI Tests
- Camera capture flow
- Crop adjustment
- Multi-page session workflow
- PDF sharing

### Device Testing
- Test on physical iPhone (camera required)
- Test various document types (letter, receipt, business card)
- Test edge detection on different backgrounds
- Test performance on iPhone 8 and newer

## Performance Considerations

- All image processing runs on background queues
- Async/await patterns for non-blocking UI
- Image downsampling for previews (300 DPI for PDF)
- Thumbnail generation for session grid
- Lazy loading for document library
- CAShapeLayer optimization for crop overlay

## Storage

- PDFs stored in `Documents/ScannedDocuments/`
- Accessible via Files app
- Included in iCloud/iTunes backups
- Supports "Open In" and AirDrop

## Privacy

- Fully offline - no network requirements
- No analytics or tracking
- No cloud storage (optional iCloud Drive future enhancement)
- Camera permission requested on-demand
- All data stored locally on device

## Future Enhancements

- OCR (text recognition) capabilities
- iCloud Drive sync
- Document templates (business card, receipt, A4)
- Advanced image editing (rotation, brightness, contrast)
- Batch processing
- Document organization (folders, tags)
- Search functionality
- Apple Pencil markup support (iPad)

## Project Documentation

This project was generated using the OpenSpec workflow with comprehensive planning:

- **Proposal**: Defined why and what changes are needed
- **Design**: Technical architecture and implementation decisions
- **Specs**: 7 capabilities with 62 requirements and 127 testable scenarios
- **Tasks**: 205 implementation tasks organized in 22 groups

Documentation available in `openspec/changes/ios-document-scanner/`

## License

[Your License Here]

## Support

For issues or questions, please refer to the OpenSpec documentation in the `openspec/` directory.

---

**Generated with OpenSpec** - Artifact-driven development workflow
