## ADDED Requirements

### Requirement: Corrupt PDF handling in document library
The system SHALL gracefully handle corrupt or unreadable PDF files in the ScannedDocuments directory without crashing or blocking the library view.

#### Scenario: Corrupt PDF skipped in listing
- **WHEN** the document library loads and a PDF file cannot be read by PDFKit
- **THEN** the system SHALL skip that file, log a warning, and display all other valid documents normally

#### Scenario: Corrupt PDF selected for preview
- **WHEN** the user taps a document entry that references a file that has become corrupt since listing
- **THEN** the system SHALL show an alert "Unable to open this document. The file may be damaged." with an option to delete it

### Requirement: File system permission error handling
The system SHALL handle file system permission errors when reading, writing, or deleting documents.

#### Scenario: Write permission denied
- **WHEN** the system cannot write a PDF to the ScannedDocuments directory due to a permission error
- **THEN** the system SHALL show an alert "Unable to save document. Please check your device storage settings." and NOT crash

#### Scenario: Delete permission denied
- **WHEN** the system cannot delete a PDF due to a permission error
- **THEN** the system SHALL show an alert "Unable to delete document" and leave the file in the library

### Requirement: Session interruption handling
The system SHALL preserve the current scanning session when the app is interrupted by a phone call, notification, or backgrounding.

#### Scenario: App enters background during scanning
- **WHEN** the app enters the background while a scanning session has one or more pages
- **THEN** the system SHALL save session state (page count, image references) to enable recovery

#### Scenario: App returns from background
- **WHEN** the app returns to the foreground after being backgrounded during a session
- **THEN** the scanning session SHALL remain intact with all previously captured pages

### Requirement: Crash recovery for unsaved sessions
The system SHALL offer to recover unsaved scanning sessions after an unexpected termination.

#### Scenario: Recovery data exists on launch
- **WHEN** the app launches and recovery data from a previous unsaved session exists
- **THEN** the system SHALL show an alert "You have an unsaved scanning session. Would you like to recover it?" with "Recover" and "Discard" options

#### Scenario: Recovery data is discarded
- **WHEN** the user selects "Discard" on the recovery prompt
- **THEN** the system SHALL delete the recovery data and cached images, and proceed to the document library

#### Scenario: No recovery data on launch
- **WHEN** the app launches and no recovery data exists
- **THEN** the system SHALL proceed directly to the document library without any prompt
