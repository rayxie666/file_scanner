## MODIFIED Requirements

### Requirement: Crop corner handles visible and draggable
The system SHALL display four visible corner handles at each corner of the crop region with minimum touch target size. Corner handles SHALL use the Snapchat-style theme (white fill with systemGreen highlight) and notify a delegate on drag state changes for loupe integration.

#### Scenario: Corner handles displayed
- **WHEN** crop adjustment screen is shown
- **THEN** system displays four circular handles at crop region corners
- **THEN** each handle has minimum 20pt touch target for accessibility

#### Scenario: Visual feedback on handle interaction
- **WHEN** user touches a corner handle
- **THEN** handle enlarges (1.3x scale) and changes accent color to systemGreen
- **THEN** handle returns to normal state when released

#### Scenario: Delegate notified on drag state changes
- **WHEN** user begins, moves, or ends dragging a corner handle
- **THEN** the overlay notifies its delegate with the corner index, normalized position, and gesture state
- **THEN** the delegate can use this information to show or update external views (e.g. magnification loupe)

### Requirement: User can confirm or cancel crop adjustments
The system SHALL provide clear actions to confirm or cancel crop adjustments, styled as Snapchat-style pill buttons.

#### Scenario: User confirms crop
- **WHEN** user taps the "Done" pill button
- **THEN** system applies crop region and proceeds to color mode selection

#### Scenario: User cancels crop adjustment
- **WHEN** user taps the "Cancel" pill button
- **THEN** system discards current capture and returns to camera preview
- **THEN** no image is saved to scanning session

### Requirement: Crop screen uses dark full-bleed layout with floating controls
The system SHALL display the crop adjustment screen with a black background, full-bleed image, and floating frosted-glass toolbar controls instead of standard navigation bar buttons.

#### Scenario: Crop screen styled with theme
- **WHEN** the crop adjustment screen is displayed
- **THEN** background is solid black
- **THEN** grid and reset buttons appear as frosted-glass pills floating over the image
- **THEN** the "Done" button is a solid green pill at the bottom center
- **THEN** no navigation bar is visible
