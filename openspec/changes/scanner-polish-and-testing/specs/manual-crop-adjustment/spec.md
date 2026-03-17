## ADDED Requirements

### Requirement: Perspective grid overlay
The system SHALL provide an optional perspective grid overlay on the crop view to help the user align the document edges.

#### Scenario: Grid toggle
- **WHEN** the user taps a grid toggle button on the crop screen
- **THEN** the system SHALL show or hide a 3x3 grid drawn within the crop quadrilateral

#### Scenario: Grid updates with corner movement
- **WHEN** the user drags a corner handle while the grid is visible
- **THEN** the grid SHALL update in real-time to match the current quadrilateral shape

### Requirement: Haptic feedback on corner drag
The system SHALL provide light haptic feedback when the user begins dragging a crop corner handle.

#### Scenario: Light impact on drag start
- **WHEN** the user starts dragging a corner handle
- **THEN** the system SHALL trigger a UIImpactFeedbackGenerator with light style
