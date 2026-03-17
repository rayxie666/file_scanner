## Why

The Document Scanner app has all core functionality implemented (camera capture, edge detection, crop adjustment, color modes, PDF generation, document storage, navigation flow) but lacks the polish, robustness, accessibility, and testing needed for a production release. Without these, the app will feel unfinished, crash on edge cases, exclude users who rely on assistive technologies, and ship with unverified behavior.

## What Changes

- **UI Polish**: Add haptic feedback, progress views for PDF generation, consistent color scheme, and responsive layout validation across device sizes
- **Error Resilience**: Handle file system permission errors, corrupt PDF files, session interruptions (phone calls, backgrounding), and add crash recovery for unsaved scan sessions
- **Performance**: Downsample images for previews, generate thumbnails for session grid and library, lazy-load PDF thumbnails, and profile/optimize for older devices
- **Accessibility**: Add VoiceOver labels, hints, and announcements for all screens; support Dynamic Type; ensure WCAG AA color contrast; add accessibility identifiers for UI testing
- **Testing**: Write unit tests for all services and models; write UI tests for critical flows; validate on physical devices with various document types and conditions
- **Code Quality**: Remove debug prints, eliminate force-unwraps, resolve TODOs/FIXMEs, run SwiftLint, remove unused assets
- **Release Preparation**: Set version/build numbers, verify Info.plist permissions, prepare App Store metadata and screenshots
- **Minor Feature Gaps**: Bulk edit mode for document library, real-time filename validation, perspective grid overlay for crop view, PDF generation progress bar

## Capabilities

### New Capabilities
- `accessibility`: VoiceOver support, Dynamic Type, WCAG AA compliance, and accessibility identifiers across all screens
- `error-resilience`: Handling of corrupt files, session interruption recovery, file permission errors, and crash recovery for unsaved sessions
- `performance-optimization`: Image downsampling for previews, thumbnail generation, lazy loading, and memory/launch-time profiling

### Modified Capabilities
- `camera-document-capture`: Adding haptic feedback and accessibility labels to capture controls
- `manual-crop-adjustment`: Adding perspective grid overlay and accessibility labels for corner handles
- `document-storage`: Adding corrupt PDF handling and bulk deletion support
- `pdf-generation`: Adding progress view for multi-page generation

## Impact

- **Views**: All view controllers gain accessibility labels, hints, Dynamic Type support, and haptic feedback
- **Services**: DocumentStorageService gains corrupt file handling; ImageProcessingService gains thumbnail/preview downsampling
- **ViewModels**: SessionViewModel gains progress reporting for PDF generation UI
- **Tests**: New test targets for unit tests (services, models) and UI tests (flows)
- **Project Config**: Info.plist verification, version/build number, asset catalog updates
- **Dependencies**: None - all changes use native iOS frameworks
