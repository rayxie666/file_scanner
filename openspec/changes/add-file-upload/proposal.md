## Why

Users currently can only add documents by taking photos with the camera. This limits usability when users already have document images saved in their photo library or have received document files (images/PDFs) from other sources. Adding file upload capability will provide a more complete document management experience and reduce friction for users who don't need to capture new photos.

## What Changes

- Add a new upload button (FAB) next to the existing camera button in the DocumentLibraryViewController
- Implement a file picker that supports:
  - Photo library selection (images from album)
  - Document picker for local files (images and PDFs)
- Integrate uploaded images into the existing crop → color mode → session review flow
- Handle PDF imports by extracting pages or adding directly to the library

## Capabilities

### New Capabilities
- `file-upload`: Handles file selection from photo library and local documents, supporting image files (JPEG, PNG, HEIC) and PDF files, with integration into the existing document processing pipeline

### Modified Capabilities
<!-- No existing spec requirements are changing - we're adding a new entry point to the existing flow -->

## Impact

- **UI Changes**: `DocumentLibraryViewController` - add upload FAB button alongside camera FAB
- **New View Controller**: File source selection (album vs files) and picker presentation
- **AppCoordinator**: New flow method `startUploadFlow()` to handle uploaded files
- **Services**: May need to extend `ImageProcessingService` for handling different image formats
- **Permissions**: Photo library access permission (`NSPhotoLibraryUsageDescription` in Info.plist)
- **Dependencies**: Uses native iOS frameworks (PhotosUI for PHPickerViewController, UIKit for UIDocumentPickerViewController)
