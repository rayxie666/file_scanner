## Context

The app is a UIKit-based iOS document scanner using MVVM + Coordinator architecture. All 7 view controllers use programmatic UI with standard UIKit controls (segmented controls, navigation bars, table views). The crop screen has a `CropOverlayView` with draggable `CornerHandleView` handles on a `UIScrollView` that supports 1-3x zoom. Corner positions are stored as normalized (0-1) coordinates. There are no third-party dependencies — everything uses native frameworks (AVFoundation, Vision, PDFKit, Core Image, Combine).

The current UI is functional but conventional. Buttons use standard `UIButton(type: .system)` with manual styling per screen. There's no shared design system — colors, fonts, spacing, and corner radii are hardcoded individually in each view controller.

## Goals / Non-Goals

**Goals:**
- Establish a centralized design system (`ScannerTheme`) so all screens share consistent colors, typography, spacing, blur styles, and animation curves
- Restyle all screens to a Snapchat-inspired dark, full-bleed, floating-controls aesthetic
- Add a `MagnificationLoupeView` that appears during corner handle dragging in CropOverlayView, showing a zoomed view of the area under the drag point
- Keep all changes purely visual — no modifications to data models, services, or business logic

**Non-Goals:**
- SwiftUI migration — stay in UIKit
- Custom screen transitions or hero animations between view controllers (spring animations on individual elements are fine, but custom `UIViewControllerAnimatedTransitioning` is out of scope)
- Redesigning the app icon or launch screen
- Adding new screens or changing the navigation flow

## Decisions

### 1. Centralized theme via a `ScannerTheme` struct

**Decision**: Create a single `ScannerTheme.swift` file with nested enums/structs for `Colors`, `Fonts`, `Spacing`, `Corner`, `Animation`, and factory methods for common components (pill buttons, frosted toolbars, card containers).

**Rationale**: Every view controller currently hardcodes its own styling. A centralized theme prevents drift and makes the Snapchat-style look consistent. A struct with static properties is lightweight, requires no dependency injection, and works identically to the current inline approach — just referenced from one place.

**Alternative considered**: Protocol-based theming or a ThemeManager singleton — overkill for a single visual style with no runtime theme switching.

### 2. Magnification loupe using a snapshot-based approach

**Decision**: Create `MagnificationLoupeView` as a circular UIView that captures a snapshot of the region around the drag point from the original image (not the screen), renders it at 4x magnification inside a clipped circle with a crosshair overlay, and positions itself offset above the active corner handle.

**Implementation approach**:
- The loupe samples directly from `originalImage` using the normalized corner coordinates, not from the screen/scroll view. This ensures the zoomed content is always sharp regardless of the scroll view's zoom level.
- On `handlePan(.began)`: create and add the loupe to the crop view controller's view (above everything, not inside the scroll view).
- On `handlePan(.changed)`: update the loupe's position (offset 80pt above the finger to stay visible) and re-render the zoomed region from the original image around the current normalized corner coordinate.
- On `handlePan(.ended)`: animate the loupe out and remove it.
- The loupe is a 120pt diameter circle with a 2pt white border and a thin crosshair at center.

**Rationale**: Sampling from the original image avoids resolution issues when the scroll view is zoomed out. A snapshot-based approach is simpler and more performant than embedding a second UIScrollView or using CALayer magnification. The 80pt offset keeps the loupe visible above the user's thumb.

**Alternative considered**: Using a `UIView` with a scaled sublayer transform pointing at the same image view — complex z-ordering issues with the scroll view and crop overlay. Also considered iOS's built-in magnifier API (`UITextInteraction` magnifier) but it's only available for text views and not customizable.

### 3. Communication between CropOverlayView and MagnificationLoupeView

**Decision**: Add a delegate callback to `CropOverlayView` that notifies when a corner drag begins, moves, or ends, passing the corner index, normalized position, and gesture state. `CropViewController` owns the loupe and responds to these callbacks.

**Rationale**: The loupe needs to be positioned in the view controller's coordinate space (above the scroll view), not inside the overlay. A delegate pattern matches the existing architecture — `CropOverlayView` already uses this pattern for its public API. This keeps the overlay and loupe decoupled.

**Alternative considered**: Having `CropOverlayView` own the loupe directly — but the loupe must be added to a view above the scroll view to avoid being clipped or scaled by zoom.

### 4. Snapchat-style button components

**Decision**: Replace standard buttons with pill-shaped buttons using `ScannerTheme` factory methods. The "done/confirm" actions use a solid green pill. Secondary actions use frosted-glass (`UIVisualEffectView` with `UIBlurEffect(.dark)`) backgrounds with white text. The capture button on the camera screen gets a ring-pulse animation on tap.

**Rationale**: Pill shapes, blur backgrounds, and vibrant accent colors are the core visual signatures of Snapchat's UI. Using `UIVisualEffectView` for blur is native, performant, and adapts to accessibility settings (reduce transparency).

### 5. Color mode filter strip

**Decision**: Replace the `UISegmentedControl` on the color mode screen with a horizontal `UICollectionView` using a custom cell that shows a circular thumbnail preview of each color mode, with a label beneath. The selected mode gets a highlighted ring. The collection view is positioned at the bottom of the screen over the full-bleed image preview.

**Rationale**: A filter strip matches the Snapchat/Instagram visual language for choosing filters. The segmented control looks dated and doesn't show previews. A collection view with circular thumbnails is both more visual and more extensible if new modes are added later.

### 6. Document library redesign

**Decision**: Convert the grouped table view to a card-based layout using `UICollectionView` with `UICollectionViewCompositionalLayout`. Each card shows a large thumbnail, document name, metadata (pages, size, date), with rounded corners and a subtle shadow. A floating action button (FAB) replaces the navigation bar scan button.

**Rationale**: Card layouts surface document previews more prominently and feel more modern. `UICollectionViewCompositionalLayout` is the standard Apple approach for complex layouts (iOS 13+). The FAB is a common pattern in camera-centric apps for the primary action.

### 7. Dark theme approach

**Decision**: Set all screen backgrounds to solid black (`UIColor.black`). Use `UIColor.white` and `UIColor.white.withAlphaComponent()` for text hierarchy. Use `UIColor.systemGreen` as the primary accent. Keep system colors for any tinted elements so they adapt to accessibility overrides.

**Rationale**: The crop and camera screens already use black backgrounds. Extending this to all screens creates visual consistency and matches Snapchat's dark aesthetic. Using system colors where possible respects accessibility settings.

## Risks / Trade-offs

**[Every screen changes at once]** → Mitigated by the fact that all changes are purely visual with no logic changes. Each screen can be restyled independently and tested in isolation. The centralized theme reduces per-screen risk since shared components are defined once.

**[Loupe performance on older devices]** → Sampling and rendering a 120pt circle from the original image on every pan gesture could be expensive for very large images (e.g. 12MP). Mitigated by using `CGImage.cropping(to:)` on a downsampled version of the original image (screen-resolution, not full camera resolution) for loupe rendering. This keeps the loupe responsive while preserving enough detail.

**[Loupe position near screen edges]** → When a corner handle is near the top of the screen, the loupe (offset 80pt above) could clip. Mitigated by flipping the loupe to appear below the handle when the handle is within 120pt of the top safe area.

**[Collection view migration for document library]** → Converting from `UITableView` to `UICollectionView` requires rewriting the data source and layout code. Mitigated by the fact that the view model layer stays the same — only the view controller's presentation code changes.

**[Filter strip thumbnail generation]** → Generating circular preview thumbnails for each color mode at scroll time could cause jank. Mitigated by pre-generating them (the existing code already pre-processes color modes in the background).
