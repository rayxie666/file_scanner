## ADDED Requirements

### Requirement: System generates PDF from scanned pages
The system SHALL generate a PDF document containing all pages from the scanning session.

#### Scenario: User completes multi-page scan
- **WHEN** user finishes scanning multiple pages and taps "Save as PDF"
- **THEN** system generates PDF with all pages in sequence
- **THEN** PDF is saved to local storage

#### Scenario: Single-page PDF generation
- **WHEN** user scans single page and taps "Save as PDF"
- **THEN** system generates PDF containing one page
- **THEN** PDF is saved to local storage

### Requirement: PDF pages maintain scan order
The system SHALL generate PDF pages in the order they were scanned, with option to reorder before generation.

#### Scenario: Pages added in sequence
- **WHEN** user scans pages 1, 2, 3 in order
- **THEN** generated PDF contains pages in same sequence

#### Scenario: User reorders pages before PDF generation
- **WHEN** user rearranges page order in session review screen
- **THEN** generated PDF reflects new page order

### Requirement: PDF page size matches document dimensions
The system SHALL set PDF page dimensions based on processed document image dimensions.

#### Scenario: Standard document size
- **WHEN** scanned document is letter or A4 size
- **THEN** PDF page dimensions match standard size (8.5x11" or A4)

#### Scenario: Custom document size
- **WHEN** scanned document has non-standard dimensions
- **THEN** PDF page size matches actual document aspect ratio
- **THEN** page size scales appropriately for PDF standard

### Requirement: PDF embeds high-quality images
The system SHALL embed processed document images in PDF at sufficient resolution for printing and readability.

#### Scenario: Image quality in PDF
- **WHEN** PDF is generated
- **THEN** embedded images have minimum 300 DPI resolution
- **THEN** text and details remain sharp when viewed or printed

#### Scenario: File size optimization
- **WHEN** PDF is generated with multiple pages
- **THEN** system compresses images using JPEG quality 0.8 to balance size and quality
- **THEN** total PDF file size is reasonable (approximately 200-500KB per page)

### Requirement: User can set PDF filename
The system SHALL allow users to specify custom filename for generated PDF.

#### Scenario: User sets custom filename
- **WHEN** user taps "Save as PDF" button
- **THEN** system displays filename input dialog
- **THEN** user can enter custom filename

#### Scenario: Default filename provided
- **WHEN** filename dialog appears
- **THEN** system suggests default filename "Document_YYYY-MM-DD_HHMMSS.pdf"
- **THEN** user can accept default or enter custom name

#### Scenario: Invalid filename characters sanitized
- **WHEN** user enters filename with invalid characters (/, :, etc.)
- **THEN** system removes or replaces invalid characters
- **THEN** system displays sanitized filename for confirmation

### Requirement: PDF generation shows progress indicator
The system SHALL display progress feedback during PDF generation for multi-page documents.

#### Scenario: Generating multi-page PDF
- **WHEN** system is generating PDF with more than 3 pages
- **THEN** progress indicator shows "Generating PDF... Page X of Y"

#### Scenario: PDF generation completes
- **WHEN** PDF generation finishes successfully
- **THEN** system dismisses progress indicator
- **THEN** system shows success message with PDF location

### Requirement: PDF generation handles errors gracefully
The system SHALL handle errors during PDF generation and notify user with recovery options.

#### Scenario: PDF generation fails due to storage
- **WHEN** device storage is full during PDF generation
- **THEN** system displays error "Not enough storage to save PDF"
- **THEN** user can free space and retry

#### Scenario: PDF generation fails due to processing error
- **WHEN** image processing fails during PDF generation
- **THEN** system displays error message identifying problematic page
- **THEN** user can remove page and retry

### Requirement: Generated PDF is standard-compliant
The system SHALL generate PDFs that conform to PDF standard and open in common PDF readers.

#### Scenario: PDF opens in iOS Files app
- **WHEN** user opens generated PDF in Files app
- **THEN** PDF displays correctly with all pages

#### Scenario: PDF opens in third-party readers
- **WHEN** user opens PDF in Adobe Reader, Preview, or other PDF apps
- **THEN** all pages display correctly with proper formatting

### Requirement: PDF metadata includes creation date
The system SHALL embed metadata in generated PDF including creation date and application identifier.

#### Scenario: PDF metadata populated
- **WHEN** PDF is generated
- **THEN** PDF metadata includes creation timestamp
- **THEN** PDF metadata includes creator field "iOS Document Scanner"
