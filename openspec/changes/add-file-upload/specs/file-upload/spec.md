## ADDED Requirements

### Requirement: User can access file upload from document library
The system SHALL provide a file upload button in the DocumentLibraryViewController that allows users to import documents from external sources.

#### Scenario: Upload button displayed alongside camera button
- **WHEN** user views the document library screen
- **THEN** system displays an upload FAB button next to the camera FAB button

#### Scenario: Tapping upload button presents source selection
- **WHEN** user taps the upload button
- **THEN** system presents options to select files from photo library or document picker

### Requirement: User can upload images from photo library
The system SHALL allow users to select one or more images from their device photo library for import into the document scanner.

#### Scenario: Selecting images from photo library
- **WHEN** user selects "Photo Library" as the upload source
- **THEN** system presents the PHPickerViewController configured for image selection
- **THEN** system allows multi-selection of images

#### Scenario: Successfully importing photo library images
- **WHEN** user selects one or more images and confirms selection
- **THEN** system receives the selected images
- **THEN** system navigates to the crop screen for the first image

#### Scenario: User cancels photo library selection
- **WHEN** user dismisses the photo picker without selecting images
- **THEN** system returns to the document library without changes

### Requirement: User can upload files from document picker
The system SHALL allow users to select document files (images and PDFs) from the iOS Files app and other document providers.

#### Scenario: Selecting files from document picker
- **WHEN** user selects "Files" as the upload source
- **THEN** system presents the UIDocumentPickerViewController
- **THEN** system filters for supported file types (JPEG, PNG, HEIC, PDF)

#### Scenario: Successfully importing a document file
- **WHEN** user selects a supported file and confirms
- **THEN** system imports the file for processing
- **THEN** system navigates to the appropriate processing flow

#### Scenario: User cancels document picker selection
- **WHEN** user dismisses the document picker without selecting a file
- **THEN** system returns to the document library without changes

### Requirement: System handles supported image formats
The system SHALL support importing images in JPEG, PNG, and HEIC formats from both photo library and document picker sources.

#### Scenario: Processing JPEG image
- **WHEN** user uploads a JPEG image file
- **THEN** system accepts the image for processing
- **THEN** system navigates to the crop screen

#### Scenario: Processing PNG image
- **WHEN** user uploads a PNG image file
- **THEN** system accepts the image for processing
- **THEN** system navigates to the crop screen

#### Scenario: Processing HEIC image
- **WHEN** user uploads a HEIC image file
- **THEN** system accepts the image for processing
- **THEN** system navigates to the crop screen

### Requirement: System handles PDF file imports
The system SHALL support importing PDF files and extracting their pages as document images.

#### Scenario: Importing single-page PDF
- **WHEN** user uploads a PDF with one page
- **THEN** system extracts the page as an image
- **THEN** system navigates to the crop screen with the extracted image

#### Scenario: Importing multi-page PDF
- **WHEN** user uploads a PDF with multiple pages
- **THEN** system extracts each page as a separate image
- **THEN** system creates a session with all extracted pages
- **THEN** system navigates to the session review flow

### Requirement: Uploaded files integrate with existing document flow
The system SHALL process uploaded files through the same crop, color mode, and session review pipeline as camera-captured documents.

#### Scenario: Uploaded image goes through crop flow
- **WHEN** user uploads an image (not from multi-page PDF)
- **THEN** system presents the crop screen for boundary adjustment
- **THEN** user can adjust crop boundaries before proceeding

#### Scenario: Processed uploaded image goes through color mode selection
- **WHEN** user completes cropping an uploaded image
- **THEN** system presents color mode selection (original, grayscale, black & white)
- **THEN** user can select preferred color treatment

#### Scenario: Multiple uploaded images create a session
- **WHEN** user uploads multiple images in a single selection
- **THEN** system processes each image through crop and color mode
- **THEN** system presents session review with all processed images

### Requirement: System requests photo library permission when needed
The system SHALL request photo library access permission when the user first attempts to upload from the photo library.

#### Scenario: First-time photo library access
- **WHEN** user selects photo library upload for the first time
- **THEN** system requests photo library permission if not already granted
- **THEN** system displays the permission purpose (NSPhotoLibraryUsageDescription)

#### Scenario: Photo library permission denied
- **WHEN** user denies photo library access permission
- **THEN** system displays an alert explaining that permission is required
- **THEN** system provides option to open Settings to grant permission

#### Scenario: Photo library permission previously granted
- **WHEN** user selects photo library upload with permission already granted
- **THEN** system immediately presents the photo picker

### Requirement: System handles upload errors gracefully
The system SHALL handle errors during file upload and provide appropriate user feedback.

#### Scenario: Unsupported file type selected
- **WHEN** user somehow selects an unsupported file type
- **THEN** system displays an error message indicating the file type is not supported
- **THEN** system allows user to try again with a different file

#### Scenario: File cannot be read or is corrupted
- **WHEN** system fails to read or process a selected file
- **THEN** system displays an error message indicating the file could not be processed
- **THEN** system allows user to try again with a different file

#### Scenario: PDF extraction fails
- **WHEN** system fails to extract pages from a PDF file
- **THEN** system displays an error message indicating the PDF could not be processed
- **THEN** system allows user to try again with a different file
