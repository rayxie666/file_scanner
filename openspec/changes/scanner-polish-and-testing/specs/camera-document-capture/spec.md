## ADDED Requirements

### Requirement: Haptic feedback on photo capture
The system SHALL provide haptic feedback when a photo is captured to confirm the action physically.

#### Scenario: Medium impact on capture
- **WHEN** the user taps the capture button and a photo is taken
- **THEN** the system SHALL trigger a UIImpactFeedbackGenerator with medium style
