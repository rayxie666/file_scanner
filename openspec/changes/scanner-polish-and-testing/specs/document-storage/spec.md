## ADDED Requirements

### Requirement: Bulk deletion in document library
The system SHALL support selecting and deleting multiple documents at once via an edit mode.

#### Scenario: Enter edit mode
- **WHEN** the user activates edit mode in the document library
- **THEN** the table view SHALL show selection checkboxes and a "Delete Selected" button

#### Scenario: Bulk delete with confirmation
- **WHEN** the user selects multiple documents and taps "Delete Selected"
- **THEN** the system SHALL show a confirmation alert stating the number of documents to delete, and delete all selected documents upon confirmation

#### Scenario: Exit edit mode
- **WHEN** the user taps "Done" in edit mode
- **THEN** the table view SHALL return to normal display mode with selections cleared

### Requirement: Real-time filename validation
The system SHALL validate filenames in real-time as the user types, showing the sanitized result.

#### Scenario: Invalid characters removed
- **WHEN** the user types a filename containing characters like `/`, `\`, `:`, `?`, `*`, `|`, `"`, `<`, `>`
- **THEN** the system SHALL show the sanitized filename below the input field with invalid characters replaced by underscores

#### Scenario: Empty filename fallback
- **WHEN** the user clears the filename field completely
- **THEN** the system SHALL display the default filename ("Document_YYYY-MM-DD_HHMMSS") as the preview and use it if the user taps Save
