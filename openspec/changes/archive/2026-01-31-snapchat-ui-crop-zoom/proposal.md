## Why

The app has solid document scanning functionality but the UI feels utilitarian and dated. Users expect a modern, fluid camera-first experience similar to Snapchat — full-bleed previews, minimal chrome, bold action buttons, and smooth transitions. Additionally, when cropping, users can zoom in but lack a magnification loupe to see fine detail at the exact point they're dragging a corner handle. This makes precise corner placement difficult, especially on smaller screens.

## What Changes

- **Snapchat-style UI overhaul across all screens**: Full-bleed camera preview, floating translucent controls, rounded pill-shaped buttons, dark theme with vibrant accents, bottom-aligned action areas, card-style modals, smooth spring animations between screens.
- **Camera screen**: Remove navigation bar chrome; use floating overlay buttons (flash, cancel) with frosted-glass backgrounds; large circular capture button with ring animation on tap; edge-detection hint overlay.
- **Crop screen**: Dark full-bleed background, minimal floating controls, translucent toolbar, Snapchat-style "done" pill button.
- **Color mode screen**: Horizontal scrollable filter strip at bottom (like Snapchat filters) instead of a segmented control; full-bleed preview with swipe-to-switch.
- **Session review**: Card-based page grid with rounded corners, shadow, and subtle parallax; floating action bar at bottom.
- **Document library**: Clean card-based list with large thumbnails, swipe actions, floating scan FAB button.
- **Crop zoom lens**: A circular magnification loupe that appears near the active corner handle during drag, showing a zoomed-in view (3-5x) of the area around the finger so users can see exactly where they're placing the crop boundary.

## Capabilities

### New Capabilities
- `snapchat-ui-theme`: Global visual design system — color palette, typography, spacing, blur/frosted-glass styles, animation curves, and reusable UI components (pill buttons, floating toolbars, card containers) applied across all screens.
- `crop-zoom-lens`: Magnification loupe overlay during corner handle dragging in the crop screen — shows a zoomed circle near the drag point with crosshair, follows the finger, and disappears when drag ends.

### Modified Capabilities
- `manual-crop-adjustment`: Updated to integrate the zoom lens loupe during corner dragging and adopt the new Snapchat-style visual theme (dark background, floating controls, pill buttons).

## Impact

- **Views (all 7 view controllers)**: Every screen gets visual updates — layout changes, new styling, animation additions. CropViewController and CropOverlayView get the most changes (zoom lens integration).
- **New files**: A UI theme/style constants file, a `MagnificationLoupeView` custom view, possibly a shared floating toolbar component.
- **No model/service changes**: Data flow, scanning logic, PDF generation, and storage remain untouched.
- **No new dependencies**: All effects (blur, animations, magnification) achievable with native UIKit.
- **Risk**: Moderate — touches every screen but changes are purely visual; no business logic modifications.
