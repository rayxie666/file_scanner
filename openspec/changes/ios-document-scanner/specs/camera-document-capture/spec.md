## ADDED Requirements

### Requirement: Camera preview displays live video feed
The system SHALL display a real-time camera preview when the user initiates document capture, allowing them to frame the document before capturing.

#### Scenario: User opens camera for scanning
- **WHEN** user taps "Scan Document" button
- **THEN** system displays full-screen camera preview with live video feed

#### Scenario: Camera preview on device without camera
- **WHEN** user attempts to open camera on device without camera hardware
- **THEN** system displays error message "Camera not available on this device"

### Requirement: User can capture document photo
The system SHALL allow users to capture a photo of the document from the camera preview.

#### Scenario: User captures document photo
- **WHEN** user taps the capture button while camera preview is active
- **THEN** system captures current camera frame as a high-resolution image
- **THEN** system transitions to preview/crop screen with captured image

#### Scenario: Capture button disabled during processing
- **WHEN** system is processing a previous capture
- **THEN** capture button SHALL be disabled and show loading indicator

### Requirement: Camera permission request
The system SHALL request camera permission before accessing camera hardware and handle denial gracefully.

#### Scenario: First-time camera access
- **WHEN** user taps "Scan Document" for the first time
- **THEN** system displays iOS camera permission dialog with usage description
- **THEN** camera preview appears after user grants permission

#### Scenario: Camera permission denied
- **WHEN** user denies camera permission
- **THEN** system displays alert with message "Camera access is required to scan documents"
- **THEN** alert includes button to open Settings app

#### Scenario: Camera permission previously denied
- **WHEN** user attempts to scan document after previously denying permission
- **THEN** system displays alert directing user to enable camera access in Settings
- **THEN** system does not show camera preview

### Requirement: Camera controls for focus and exposure
The system SHALL allow users to adjust focus and exposure by tapping on the preview.

#### Scenario: User taps to focus
- **WHEN** user taps on camera preview
- **THEN** system sets focus point at tapped location
- **THEN** system displays focus indicator animation at tap location

#### Scenario: Auto-exposure adjustment
- **WHEN** camera detects lighting changes
- **THEN** system automatically adjusts exposure for optimal document visibility

### Requirement: Camera orientation handling
The system SHALL maintain correct camera preview orientation as device rotates.

#### Scenario: Device rotates during camera preview
- **WHEN** user rotates device while camera preview is active
- **THEN** camera preview rotates to match device orientation
- **THEN** capture button and UI controls remain accessible

### Requirement: Flash control for low-light conditions
The system SHALL provide flash control option for capturing documents in low-light environments.

#### Scenario: User enables flash
- **WHEN** user toggles flash button to "on"
- **THEN** flash activates when capture button is pressed

#### Scenario: Flash disabled by default
- **WHEN** camera preview opens
- **THEN** flash is disabled by default to avoid glare on documents

#### Scenario: Device without flash
- **WHEN** camera preview opens on device without flash hardware
- **THEN** flash toggle button is hidden or disabled
