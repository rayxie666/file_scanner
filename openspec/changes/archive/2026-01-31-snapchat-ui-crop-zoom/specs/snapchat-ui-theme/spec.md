## ADDED Requirements

### Requirement: App provides a centralized design system
The system SHALL define all visual styling through a centralized `ScannerTheme` structure containing colors, typography, spacing, corner radii, and animation curves. All screens MUST reference this theme rather than hardcoding style values.

#### Scenario: Theme defines color palette
- **WHEN** any screen renders UI elements
- **THEN** it uses theme-defined colors: black backgrounds, white/white-alpha text hierarchy, systemGreen accent for primary actions

#### Scenario: Theme defines typography
- **WHEN** any screen renders text
- **THEN** it uses theme-defined font styles that support Dynamic Type

### Requirement: All screens use dark full-bleed backgrounds
The system SHALL render all screens with solid black backgrounds and edge-to-edge content with no visible navigation bar chrome.

#### Scenario: Screen backgrounds are black
- **WHEN** any screen is displayed
- **THEN** the background color is solid black
- **THEN** content extends to screen edges (full-bleed)

#### Scenario: Navigation bar chrome is hidden
- **WHEN** screens that previously used navigation bars are displayed
- **THEN** the navigation bar is hidden or fully transparent
- **THEN** floating overlay controls replace navigation bar buttons

### Requirement: Buttons use pill-shaped styling
The system SHALL render primary action buttons as pill-shaped (fully rounded corners) with solid fill, and secondary action buttons as pill-shaped with frosted-glass blur backgrounds.

#### Scenario: Primary action button rendered
- **WHEN** a primary action button (Done, Save, Confirm) is displayed
- **THEN** it renders as a pill shape with solid systemGreen background and white text
- **THEN** corner radius is half the button height (fully rounded)

#### Scenario: Secondary action button rendered
- **WHEN** a secondary action button (Cancel, Reset, Grid) is displayed
- **THEN** it renders as a pill shape with frosted-glass blur background and white text

### Requirement: Controls use frosted-glass blur effect
The system SHALL render floating toolbars and secondary controls with a `UIVisualEffectView` dark blur background for a translucent glass appearance.

#### Scenario: Frosted-glass effect displayed
- **WHEN** a floating toolbar or secondary button group is rendered
- **THEN** it uses a `UIBlurEffect(.dark)` background
- **THEN** controls remain legible over any content beneath them

#### Scenario: Reduce transparency accessibility respected
- **WHEN** the user has enabled "Reduce Transparency" in accessibility settings
- **THEN** frosted-glass elements fall back to a solid dark background

### Requirement: Camera screen uses floating overlay controls
The system SHALL display camera controls as floating overlays on top of the full-screen camera preview, with no navigation bar.

#### Scenario: Camera screen layout
- **WHEN** the camera screen is displayed
- **THEN** flash toggle and cancel buttons appear as floating frosted-glass pills
- **THEN** a large circular capture button is centered at the bottom
- **THEN** the camera preview fills the entire screen behind all controls

#### Scenario: Capture button animates on tap
- **WHEN** user taps the capture button
- **THEN** the button plays a ring-pulse scale animation
- **THEN** haptic feedback fires simultaneously

### Requirement: Color mode screen uses horizontal filter strip
The system SHALL display color mode options as a horizontal scrollable strip of circular preview thumbnails at the bottom of the screen, replacing the segmented control.

#### Scenario: Filter strip displayed
- **WHEN** the color mode screen is shown
- **THEN** circular thumbnail previews of each color mode appear in a horizontal strip at the bottom
- **THEN** each thumbnail shows a small preview of the image in that color mode
- **THEN** a label beneath each thumbnail identifies the mode

#### Scenario: User selects a color mode from the filter strip
- **WHEN** user taps a filter thumbnail
- **THEN** the selected thumbnail gets a highlighted ring border
- **THEN** the full-screen preview updates to show that color mode

### Requirement: Session review uses card-based page grid
The system SHALL display scanned pages as rounded-corner cards with shadows in a grid layout, with a floating action bar at the bottom.

#### Scenario: Page cards displayed
- **WHEN** the session review screen is shown
- **THEN** pages appear as cards with rounded corners and subtle shadow
- **THEN** page number badges appear on each card

#### Scenario: Floating action bar
- **WHEN** the session review screen is shown
- **THEN** the "Add Page" and "Save as PDF" actions appear in a floating bar at the bottom
- **THEN** the floating bar uses frosted-glass styling

### Requirement: Document library uses card layout with floating scan button
The system SHALL display saved documents as card-style items with large thumbnails in a collection view, with a floating action button (FAB) for scanning.

#### Scenario: Document cards displayed
- **WHEN** the document library is shown
- **THEN** each document appears as a card with a large thumbnail, filename, page count, file size, and date
- **THEN** cards have rounded corners and subtle shadow

#### Scenario: Floating scan button displayed
- **WHEN** the document library is shown
- **THEN** a circular floating action button for scanning appears at the bottom-right
- **THEN** the FAB uses systemGreen background with a camera icon

### Requirement: Animations use spring physics
The system SHALL use spring-based animations for UI transitions, button state changes, and element appearances, with consistent timing defined in the theme.

#### Scenario: Spring animation on interactive elements
- **WHEN** a button is pressed or an element transitions state
- **THEN** the animation uses spring damping and velocity from the theme
- **THEN** the animation feels bouncy and responsive
