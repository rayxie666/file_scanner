### Requirement: User can manually adjust crop corners
The system SHALL allow users to manually adjust the four corners of the crop region by dragging corner handles.

#### Scenario: User drags crop corner
- **WHEN** user taps and drags a corner handle
- **THEN** corner moves to follow user's finger position
- **THEN** crop region boundary updates in real-time

#### Scenario: Corner constrained to image bounds
- **WHEN** user drags corner handle outside image boundaries
- **THEN** corner position is constrained to remain within image bounds

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

### Requirement: Crop region displays quadrilateral overlay
The system SHALL display a quadrilateral overlay connecting the four corner points, showing the crop boundary.

#### Scenario: Quadrilateral overlay shown
- **WHEN** crop adjustment screen is active
- **THEN** system draws lines connecting four corner points
- **THEN** crop region inside boundary is highlighted or unshaded
- **THEN** area outside boundary is dimmed

### Requirement: User can reset crop to detected edges
The system SHALL allow users to reset crop region to automatically detected edges after manual adjustments.

#### Scenario: User resets crop region
- **WHEN** user taps "Reset" button after manual adjustments
- **THEN** corner positions reset to automatically detected edges
- **THEN** if no edges were detected, corners reset to full image bounds

### Requirement: Crop adjustment supports zoom for precision
The system SHALL allow users to zoom into image for precise corner positioning.

#### Scenario: User pinches to zoom
- **WHEN** user performs pinch gesture on crop adjustment screen
- **THEN** image zooms in/out while maintaining corner handle visibility
- **THEN** user can pan zoomed image to access different regions

#### Scenario: Zoom constrained to reasonable limits
- **WHEN** user zooms beyond maximum zoom level (e.g., 3x)
- **THEN** system stops zooming at maximum limit
- **THEN** minimum zoom shows entire image on screen

### Requirement: Crop region validates quadrilateral shape
The system SHALL ensure crop region maintains a valid quadrilateral shape during manual adjustment.

#### Scenario: User creates invalid self-intersecting shape
- **WHEN** user drags corners to create self-intersecting quadrilateral
- **THEN** system prevents invalid configuration
- **THEN** corners snap to nearest valid position

### Requirement: Visual grid overlay for alignment guidance
The system SHALL provide optional grid overlay to help users align crop region with document edges.

#### Scenario: User enables grid overlay
- **WHEN** user toggles grid option
- **THEN** system displays perspective grid lines over crop region
- **THEN** grid helps user verify corners align with document edges

#### Scenario: Grid disabled by default
- **WHEN** crop adjustment screen first appears
- **THEN** grid overlay is hidden by default to avoid visual clutter

### Requirement: User can confirm or cancel crop adjustments
The system SHALL provide clear actions to confirm or cancel crop adjustments, styled as Snapchat-style pill buttons.

#### Scenario: User confirms crop
- **WHEN** user taps the "Done" pill button
- **THEN** system applies crop region and proceeds to color mode selection

#### Scenario: User cancels crop adjustment
- **WHEN** user taps the "Cancel" pill button
- **THEN** system discards current capture and returns to camera preview
- **THEN** no image is saved to scanning session

### Requirement: Crop adjustment shows original image
The system SHALL display the uncropped original image during crop adjustment to provide full context.

#### Scenario: Original image displayed
- **WHEN** crop adjustment screen appears
- **THEN** full original captured image is visible
- **THEN** crop region overlay shows which portion will be kept

### Requirement: Crop screen uses dark full-bleed layout with floating controls
The system SHALL display the crop adjustment screen with a black background, full-bleed image, and floating frosted-glass toolbar controls instead of standard navigation bar buttons.

#### Scenario: Crop screen styled with theme
- **WHEN** the crop adjustment screen is displayed
- **THEN** background is solid black
- **THEN** grid and reset buttons appear as frosted-glass pills floating over the image
- **THEN** the "Done" button is a solid green pill at the bottom center
- **THEN** no navigation bar is visible
