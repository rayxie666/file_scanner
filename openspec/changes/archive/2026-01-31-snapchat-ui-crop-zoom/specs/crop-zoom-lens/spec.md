## ADDED Requirements

### Requirement: Magnification loupe appears during corner handle dragging
The system SHALL display a circular magnification loupe when the user drags a crop corner handle, showing a zoomed view of the image area around the drag point.

#### Scenario: Loupe appears on drag start
- **WHEN** user begins dragging a corner handle
- **THEN** a circular magnification loupe fades in near the active corner
- **THEN** the loupe is 120pt in diameter with a 2pt white border

#### Scenario: Loupe disappears on drag end
- **WHEN** user releases a corner handle
- **THEN** the loupe animates out (fade + scale down)
- **THEN** the loupe is removed from the view hierarchy

### Requirement: Loupe shows zoomed content from original image
The system SHALL render the loupe content by sampling from the original captured image at the normalized corner coordinate, at 4x magnification.

#### Scenario: Loupe displays magnified content
- **WHEN** user is dragging a corner handle
- **THEN** the loupe shows a 4x magnified view of the image area centered on the current corner position
- **THEN** the magnified content is sampled from the original image (not the screen) for sharpness

#### Scenario: Loupe content updates in real-time
- **WHEN** user moves a corner handle during drag
- **THEN** the loupe content updates on every pan gesture change to reflect the new position

### Requirement: Loupe displays crosshair at center
The system SHALL render a thin crosshair at the center of the loupe to indicate the exact corner position.

#### Scenario: Crosshair visible in loupe
- **WHEN** the loupe is displayed
- **THEN** a thin crosshair (1pt lines, white with 70% opacity) is drawn at the center of the loupe circle
- **THEN** the crosshair extends the full diameter of the loupe

### Requirement: Loupe is positioned offset from the drag point
The system SHALL position the loupe above the active corner handle with an 80pt vertical offset so it remains visible above the user's finger.

#### Scenario: Loupe positioned above finger
- **WHEN** user drags a corner handle with space above
- **THEN** the loupe center is positioned 80pt above the corner handle center

#### Scenario: Loupe flips below when near top edge
- **WHEN** user drags a corner handle within 120pt of the top safe area
- **THEN** the loupe center is positioned 80pt below the corner handle center instead

### Requirement: Loupe is rendered above all other views
The system SHALL add the loupe to the view controller's main view (not inside the scroll view) so it is not affected by scroll view zoom or pan.

#### Scenario: Loupe not clipped by scroll view
- **WHEN** the loupe is displayed while the scroll view is zoomed in
- **THEN** the loupe appears above the scroll view and crop overlay
- **THEN** the loupe is not clipped, scaled, or panned by the scroll view

### Requirement: Loupe performs efficiently on large images
The system SHALL use a screen-resolution downsampled version of the original image for loupe rendering to maintain smooth performance during dragging.

#### Scenario: Smooth loupe updates on drag
- **WHEN** user drags a corner handle on a high-resolution captured image (e.g. 12MP)
- **THEN** the loupe updates without visible lag or dropped frames
- **THEN** the loupe content remains sharp enough to show document edges clearly
