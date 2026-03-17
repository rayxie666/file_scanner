## ADDED Requirements

### Requirement: User can select document color mode
The system SHALL allow users to select from multiple color modes to process the scanned document.

#### Scenario: User selects color mode
- **WHEN** user taps color mode selector after cropping
- **THEN** system displays available color mode options: Original Color, Grayscale, Black & White

#### Scenario: Color mode selection shows preview
- **WHEN** user taps a color mode option
- **THEN** system displays real-time preview of document with selected color mode applied

### Requirement: Original color mode preserves image
The system SHALL provide "Original Color" mode that preserves the captured image without color modifications.

#### Scenario: Original color mode selected
- **WHEN** user selects "Original Color" mode
- **THEN** system uses cropped image without color processing
- **THEN** preview shows document in full color as captured

### Requirement: Grayscale mode converts to gray tones
The system SHALL provide "Grayscale" mode that converts the document to grayscale while preserving tonal detail.

#### Scenario: Grayscale mode selected
- **WHEN** user selects "Grayscale" mode
- **THEN** system converts image to grayscale using desaturation
- **THEN** preview shows document in shades of gray

#### Scenario: Grayscale preserves contrast
- **WHEN** grayscale mode is applied
- **THEN** system maintains contrast and detail from original image
- **THEN** text and graphics remain clearly readable

### Requirement: Black and white mode creates high-contrast binary image
The system SHALL provide "Black & White" mode that converts the document to pure black and white using adaptive thresholding.

#### Scenario: Black and white mode selected
- **WHEN** user selects "Black & White" mode
- **THEN** system applies adaptive threshold to create binary image
- **THEN** preview shows document with only black and white pixels

#### Scenario: Adaptive threshold optimizes per image
- **WHEN** black and white mode is applied
- **THEN** system analyzes image histogram to determine optimal threshold value
- **THEN** threshold ensures text is crisp black against white background

#### Scenario: Black and white mode on low-contrast document
- **WHEN** black and white mode is applied to faded or low-contrast document
- **THEN** system adjusts threshold to preserve text readability
- **THEN** faint text becomes clearly visible as black on white

### Requirement: Color mode processing applies perspective correction
The system SHALL apply perspective correction when processing color modes to produce rectangular document output.

#### Scenario: Perspective correction with color mode
- **WHEN** user confirms color mode selection
- **THEN** system applies perspective warp to transform quadrilateral crop to rectangle
- **THEN** output image is rectangular regardless of capture angle

### Requirement: Color mode preview updates in real-time
The system SHALL update color mode preview immediately when user switches between modes.

#### Scenario: User switches between color modes
- **WHEN** user taps different color mode options
- **THEN** preview updates within 0.5 seconds to show new color mode
- **THEN** no loading delay disrupts user experience

### Requirement: Color mode setting persists for session
The system SHALL remember the last selected color mode for subsequent page captures within the same scanning session.

#### Scenario: User captures second page
- **WHEN** user adds another page to current scan session
- **THEN** system defaults to previously selected color mode
- **THEN** user can change color mode if desired

### Requirement: User can change color mode after initial selection
The system SHALL allow users to change color mode for a captured page after initial processing.

#### Scenario: User edits page color mode
- **WHEN** user taps on a previously captured page in session
- **THEN** system allows changing color mode
- **THEN** page is reprocessed with new color mode

### Requirement: Color mode processing preserves image quality
The system SHALL apply color mode transformations without significant quality degradation.

#### Scenario: High-resolution processing
- **WHEN** color mode is applied to captured image
- **THEN** system processes at full resolution (not downsampled)
- **THEN** output maintains sharpness and detail of original capture

#### Scenario: Processing completes without artifacts
- **WHEN** color mode transformation is applied
- **THEN** output image has no visible compression artifacts or banding
- **THEN** edges and text remain crisp
