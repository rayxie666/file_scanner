## ADDED Requirements

### Requirement: Visual progress indicator for PDF generation
The system SHALL display a progress view showing page-by-page progress during multi-page PDF generation.

#### Scenario: Progress bar during generation
- **WHEN** the user taps "Save as PDF" and PDF generation begins
- **THEN** the system SHALL display a progress bar or indicator showing "Processing page X of Y"

#### Scenario: Progress completes
- **WHEN** PDF generation finishes successfully
- **THEN** the progress view SHALL dismiss and the user SHALL be navigated to the document library

#### Scenario: Generation failure with progress
- **WHEN** PDF generation fails during processing
- **THEN** the progress view SHALL dismiss and an error alert SHALL appear with the failure reason

### Requirement: Haptic feedback on page delete
The system SHALL provide a warning-style haptic notification when a page is deleted from the session.

#### Scenario: Warning haptic on delete
- **WHEN** the user deletes a page from the session review
- **THEN** the system SHALL trigger a UINotificationFeedbackGenerator with warning type
