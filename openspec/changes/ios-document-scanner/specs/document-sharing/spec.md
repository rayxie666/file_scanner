## ADDED Requirements

### Requirement: User can share PDF via system share sheet
The system SHALL provide native iOS sharing options for generated PDF documents using UIActivityViewController.

#### Scenario: User taps share button
- **WHEN** user taps share icon on PDF in document library or preview
- **THEN** system displays iOS share sheet with PDF as attachment
- **THEN** all compatible sharing options are available

#### Scenario: Share sheet shows PDF preview
- **WHEN** share sheet appears
- **THEN** PDF thumbnail and filename are displayed in share preview
- **THEN** recipient apps show PDF icon and file size

### Requirement: PDF shareable via AirDrop
The system SHALL support AirDrop sharing for PDFs to nearby Apple devices.

#### Scenario: User shares via AirDrop
- **WHEN** user selects AirDrop from share sheet
- **THEN** system displays nearby AirDrop-enabled devices
- **THEN** tapping device sends PDF via AirDrop

#### Scenario: AirDrop transfer confirmation
- **WHEN** AirDrop transfer completes
- **THEN** system shows success notification
- **THEN** original PDF remains in app storage

#### Scenario: AirDrop unavailable
- **WHEN** AirDrop is disabled on device
- **THEN** AirDrop option is grayed out in share sheet
- **THEN** other sharing options remain available

### Requirement: PDF shareable via Open In functionality
The system SHALL support "Open In" to send PDF to compatible third-party apps.

#### Scenario: User selects Open In app
- **WHEN** user taps compatible app in share sheet (e.g., Adobe Reader, Dropbox)
- **THEN** PDF opens in selected app
- **THEN** PDF is copied to destination app

#### Scenario: No compatible apps installed
- **WHEN** no PDF-compatible apps are installed
- **THEN** share sheet shows only system options (Mail, Messages, Files)
- **THEN** user is not shown empty "Open In" section

### Requirement: PDF shareable via email
The system SHALL support sharing PDFs as email attachments via Mail app.

#### Scenario: User shares via Mail
- **WHEN** user selects Mail from share sheet
- **THEN** system opens Mail compose screen with PDF attached
- **THEN** PDF filename appears as attachment name

#### Scenario: Large PDF email warning
- **WHEN** PDF file size exceeds 10 MB and user selects Mail
- **THEN** system displays warning "PDF is large (X MB). Consider using AirDrop or Files."
- **THEN** user can proceed or choose alternative sharing method

### Requirement: PDF shareable via messaging apps
The system SHALL support sharing PDFs through Messages and other messaging apps.

#### Scenario: User shares via Messages
- **WHEN** user selects Messages from share sheet
- **THEN** system opens Messages compose with PDF attached
- **THEN** user can select recipient and send PDF

#### Scenario: Third-party messaging apps
- **WHEN** WhatsApp, Slack, or similar apps are installed
- **THEN** these apps appear in share sheet as sharing options
- **THEN** tapping app opens it with PDF ready to share

### Requirement: PDF saveable to Files app
The system SHALL support saving PDFs to other locations via Files app integration.

#### Scenario: User selects Save to Files
- **WHEN** user selects "Save to Files" from share sheet
- **THEN** system displays Files app location picker
- **THEN** user can choose destination folder (iCloud Drive, On My iPhone, etc.)

#### Scenario: Files app save confirmation
- **WHEN** user confirms Files app destination
- **THEN** PDF is copied to selected location
- **THEN** original remains in app Documents directory

### Requirement: Share sheet displays print option
The system SHALL provide print option for PDF documents via AirPrint.

#### Scenario: User selects Print
- **WHEN** user taps Print from share sheet
- **THEN** system displays print dialog with AirPrint printer options
- **THEN** user can select printer and number of copies

#### Scenario: No AirPrint printers available
- **WHEN** no AirPrint printers are detected
- **THEN** print dialog shows "No AirPrint Printers Found"
- **THEN** user can cancel and use alternative sharing method

### Requirement: User can copy PDF to clipboard
The system SHALL support copying PDF to clipboard for pasting in other apps.

#### Scenario: User selects Copy
- **WHEN** user taps "Copy" from share sheet
- **THEN** PDF is copied to system clipboard
- **THEN** user can paste PDF into compatible apps

### Requirement: Sharing preserves PDF metadata
The system SHALL ensure shared PDFs retain metadata including filename and creation date.

#### Scenario: Shared PDF includes metadata
- **WHEN** PDF is shared via any method
- **THEN** recipient receives file with original filename
- **THEN** PDF metadata (creation date, creator) is preserved

### Requirement: Share actions tracked for user convenience
The system SHALL remember recently used sharing methods for quick access.

#### Scenario: Recent share methods prioritized
- **WHEN** user frequently shares via specific app (e.g., Dropbox)
- **THEN** iOS share sheet shows frequently used apps at top
- **THEN** user can quickly access preferred sharing method

### Requirement: Sharing handles errors gracefully
The system SHALL notify user if sharing fails and provide recovery options.

#### Scenario: Share fails due to network error
- **WHEN** sharing via cloud service fails due to no internet
- **THEN** system displays error "Sharing failed. Check internet connection."
- **THEN** user can retry or choose offline sharing method (AirDrop, Files)

#### Scenario: Share cancelled by user
- **WHEN** user cancels share sheet or AirDrop transfer
- **THEN** system dismisses share interface
- **THEN** PDF remains available in app for future sharing
