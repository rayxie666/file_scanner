## ADDED Requirements

### Requirement: VoiceOver labels for all interactive controls
The system SHALL provide accessibility labels for every button, control, and interactive element across all view controllers.

#### Scenario: Camera screen VoiceOver labels
- **WHEN** VoiceOver is enabled on the camera screen
- **THEN** the capture button SHALL announce "Take Photo", the flash button SHALL announce "Flash On" or "Flash Off" based on state, and the cancel button SHALL announce "Cancel"

#### Scenario: Crop screen VoiceOver labels
- **WHEN** VoiceOver is enabled on the crop screen
- **THEN** each corner handle SHALL announce its position ("Top Left Corner", "Top Right Corner", "Bottom Right Corner", "Bottom Left Corner"), the reset button SHALL announce "Reset Crop", done SHALL announce "Done", and cancel SHALL announce "Cancel"

#### Scenario: Color mode screen VoiceOver labels
- **WHEN** VoiceOver is enabled on the color mode screen
- **THEN** each color mode option SHALL announce its name ("Original Color", "Grayscale", "Black and White"), the confirm button SHALL announce "Confirm", and the re-crop button SHALL announce "Re-crop"

#### Scenario: Document library VoiceOver labels
- **WHEN** VoiceOver is enabled on the document library screen
- **THEN** each document cell SHALL announce the filename, date, page count, and file size. The scan button SHALL announce "Scan Document" and the sort button SHALL announce "Sort Documents"

### Requirement: VoiceOver announcements for state changes
The system SHALL post VoiceOver announcements when significant state changes occur during the scanning workflow.

#### Scenario: Photo captured announcement
- **WHEN** a photo is captured successfully
- **THEN** the system SHALL post a VoiceOver announcement "Photo captured"

#### Scenario: Edge detection result announcement
- **WHEN** edge detection completes on the crop screen
- **THEN** the system SHALL post a VoiceOver announcement "Document edges detected" or "No document edges found, showing full image"

#### Scenario: PDF saved announcement
- **WHEN** a PDF is saved successfully
- **THEN** the system SHALL post a VoiceOver announcement "Document saved as PDF"

### Requirement: VoiceOver hints for gesture-based interactions
The system SHALL provide accessibility hints for controls that use non-standard gestures.

#### Scenario: Corner handle drag hint
- **WHEN** VoiceOver focuses on a corner handle
- **THEN** the handle SHALL have an accessibility hint "Drag to adjust crop corner"

#### Scenario: Page thumbnail reorder hint
- **WHEN** VoiceOver focuses on a page thumbnail in session review
- **THEN** the cell SHALL have an accessibility hint "Double tap to edit. Use drag to reorder."

### Requirement: Dynamic Type support
The system SHALL support Dynamic Type for all text elements, scaling font sizes based on the user's accessibility text size preference.

#### Scenario: Labels scale with Dynamic Type
- **WHEN** the user has set a larger accessibility text size in Settings
- **THEN** all labels, buttons, and text elements SHALL scale accordingly using the system's preferred font metrics

#### Scenario: Layout remains functional at largest size
- **WHEN** the user has set the largest accessibility text size (AX5)
- **THEN** all screens SHALL remain scrollable and all interactive elements SHALL remain tappable without overlap

### Requirement: WCAG AA color contrast compliance
The system SHALL ensure all text and interactive elements meet WCAG AA minimum contrast ratios (4.5:1 for normal text, 3:1 for large text).

#### Scenario: Button text contrast
- **WHEN** the app is displayed on screen
- **THEN** all button text SHALL have a contrast ratio of at least 4.5:1 against its background

#### Scenario: Label contrast on dark backgrounds
- **WHEN** text labels are displayed on the camera, crop, or color mode screens (dark backgrounds)
- **THEN** the text SHALL be white or light-colored with a contrast ratio of at least 4.5:1

### Requirement: Minimum touch target sizes
The system SHALL ensure all interactive elements have a minimum touch target size of 44x44 points.

#### Scenario: Corner handles meet minimum size
- **WHEN** corner handles are displayed on the crop screen
- **THEN** each handle SHALL have a touch target of at least 44x44 points

#### Scenario: Buttons meet minimum size
- **WHEN** buttons are displayed on any screen
- **THEN** each button SHALL have a tappable area of at least 44x44 points

### Requirement: Accessibility identifiers for UI testing
The system SHALL assign unique accessibility identifiers to all key UI elements for automated UI testing.

#### Scenario: Camera screen identifiers
- **WHEN** the camera screen is displayed
- **THEN** the capture button SHALL have identifier "captureButton", flash button "flashButton", cancel button "cameraCancelButton"

#### Scenario: Library screen identifiers
- **WHEN** the document library is displayed
- **THEN** the table view SHALL have identifier "documentList", scan button "scanButton", sort button "sortButton"
