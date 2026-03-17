## ADDED Requirements

### Requirement: PDFs stored in app Documents directory
The system SHALL save generated PDF files to the app's Documents directory for user access and backup.

#### Scenario: PDF saved to Documents
- **WHEN** PDF generation completes successfully
- **THEN** PDF file is saved to Documents/ScannedDocuments/ directory
- **THEN** file is accessible via iOS Files app

#### Scenario: Documents directory created on first save
- **WHEN** user saves first PDF
- **THEN** system creates ScannedDocuments subdirectory if not exists
- **THEN** subsequent PDFs are saved to same location

### Requirement: PDF filenames unique and descriptive
The system SHALL ensure saved PDF filenames are unique and include timestamp to prevent overwrites.

#### Scenario: User saves PDF with custom name
- **WHEN** user provides custom filename "Receipt"
- **THEN** system saves as "Receipt.pdf" if no file exists with that name

#### Scenario: Duplicate filename handling
- **WHEN** filename already exists in Documents
- **THEN** system appends incrementing number: "Receipt (1).pdf", "Receipt (2).pdf"
- **THEN** user is notified of renamed file

#### Scenario: Default filename with timestamp
- **WHEN** user accepts default filename
- **THEN** system saves as "Document_2024-01-15_143022.pdf" format
- **THEN** timestamp ensures uniqueness

### Requirement: User can view list of saved PDFs
The system SHALL provide interface to browse and manage saved PDF documents.

#### Scenario: User opens document library
- **WHEN** user navigates to "My Documents" screen
- **THEN** system displays list of all saved PDFs
- **THEN** list shows filename, creation date, file size, and page count

#### Scenario: Documents sorted by date
- **WHEN** document library is displayed
- **THEN** PDFs are sorted by creation date (newest first)
- **THEN** user can change sort order to alphabetical

### Requirement: User can delete saved PDFs
The system SHALL allow users to delete PDF documents they no longer need.

#### Scenario: User deletes single PDF
- **WHEN** user swipes left on PDF in document library
- **THEN** system displays delete button
- **THEN** tapping delete removes PDF from storage after confirmation

#### Scenario: Delete confirmation prevents accidental removal
- **WHEN** user taps delete on PDF
- **THEN** system displays confirmation alert "Delete [filename]?"
- **THEN** PDF is only deleted if user confirms

#### Scenario: Bulk delete multiple PDFs
- **WHEN** user enters edit mode and selects multiple PDFs
- **THEN** user can tap "Delete" to remove all selected PDFs
- **THEN** system confirms bulk deletion before removing files

### Requirement: Storage displays available space
The system SHALL show available storage space to help users manage documents.

#### Scenario: Storage indicator shown
- **WHEN** user is in document library
- **THEN** system displays storage usage: "X MB used, Y MB available"

#### Scenario: Low storage warning
- **WHEN** device storage is below 100 MB
- **THEN** system displays warning "Low storage space. Consider deleting old documents."

### Requirement: PDFs backed up via iCloud
The system SHALL ensure PDF files in Documents directory are included in iCloud and iTunes backups.

#### Scenario: iCloud backup enabled
- **WHEN** user has iCloud backup enabled for app
- **THEN** saved PDFs are included in backup
- **THEN** PDFs restore when app is reinstalled

### Requirement: User can preview PDF before sharing
The system SHALL allow users to view PDF contents from document library.

#### Scenario: User taps PDF in library
- **WHEN** user taps on a PDF in document library
- **THEN** system opens PDF in preview screen
- **THEN** user can scroll through all pages

#### Scenario: Preview shows PDF metadata
- **WHEN** PDF preview is open
- **THEN** system displays filename, creation date, and page count
- **THEN** user can access share and delete options from preview

### Requirement: Document storage handles file system errors
The system SHALL handle storage errors gracefully and preserve data integrity.

#### Scenario: Insufficient storage during save
- **WHEN** device runs out of storage during PDF save
- **THEN** system displays error "Not enough storage space"
- **THEN** partially written file is removed to avoid corruption

#### Scenario: File write permissions denied
- **WHEN** app lacks write permission to Documents directory
- **THEN** system displays error and requests necessary permissions
- **THEN** save operation retries after permissions granted

### Requirement: User can rename saved PDFs
The system SHALL allow users to rename PDF files after saving.

#### Scenario: User renames PDF
- **WHEN** user taps "Rename" on PDF in document library
- **THEN** system displays filename input with current name
- **THEN** renaming PDF updates filename on disk

#### Scenario: Invalid rename prevented
- **WHEN** user attempts to rename PDF with invalid characters
- **THEN** system sanitizes filename and shows corrected version
- **THEN** user confirms before rename is applied
