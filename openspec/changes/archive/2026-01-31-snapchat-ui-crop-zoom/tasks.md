## 1. ScannerTheme Design System

- [x] 1.1 Create `ScannerTheme.swift` with `Colors` nested enum (background, textPrimary, textSecondary, accent, overlayDark)
- [x] 1.2 Add `Fonts` nested enum with Dynamic Type-compatible styles (headline, body, caption, button)
- [x] 1.3 Add `Spacing`, `Corner`, and `Animation` nested enums (standard margins, corner radii, spring damping/velocity)
- [x] 1.4 Add factory method `makePillButton(title:style:)` returning a pill-shaped UIButton (primary=green fill, secondary=frosted blur)
- [x] 1.5 Add factory method `makeFrostedToolbar()` returning a UIVisualEffectView with dark blur and rounded corners
- [x] 1.6 Add factory method `makeCardContainer()` returning a UIView with rounded corners, shadow, and dark background

## 2. MagnificationLoupeView

- [x] 2.1 Create `MagnificationLoupeView.swift` — 120pt circular UIView with white 2pt border, clipped to circle
- [x] 2.2 Add crosshair overlay (1pt white lines at 70% opacity spanning full diameter)
- [x] 2.3 Implement `update(normalizedPoint:in image:)` method that crops a region from the image at 4x magnification and renders it in the loupe
- [x] 2.4 Use a downsampled (screen-resolution) copy of the original image for loupe rendering to maintain performance
- [x] 2.5 Implement positioning logic: center 80pt above the drag point, flip to 80pt below when within 120pt of top safe area
- [x] 2.6 Add fade-in animation on appear and fade+scale-down animation on dismiss

## 3. CropOverlayView Delegate Integration

- [x] 3.1 Define `CropOverlayViewDelegate` protocol with `cornerDragDidBegin(index:normalizedPosition:)`, `cornerDragDidMove(index:normalizedPosition:)`, `cornerDragDidEnd(index:)` methods
- [x] 3.2 Add `weak var delegate: CropOverlayViewDelegate?` property to CropOverlayView
- [x] 3.3 Update `handlePan(_:)` to call delegate methods on `.began`, `.changed`, and `.ended`/`.cancelled` states

## 4. CropViewController Loupe Integration

- [x] 4.1 Conform CropViewController to `CropOverlayViewDelegate`
- [x] 4.2 On `cornerDragDidBegin`: create MagnificationLoupeView, add to main view (above scroll view), prepare downsampled image if not already cached
- [x] 4.3 On `cornerDragDidMove`: update loupe position (converting normalized coordinates to view coordinates) and update loupe content
- [x] 4.4 On `cornerDragDidEnd`: animate loupe out and remove from view hierarchy
- [x] 4.5 Cache the downsampled image on first drag so subsequent drags reuse it

## 5. CropViewController Theme Restyling

- [x] 5.1 Replace grid button with `ScannerTheme.makePillButton(style: .secondary)` frosted pill
- [x] 5.2 Replace reset button with `ScannerTheme.makePillButton(style: .secondary)` frosted pill
- [x] 5.3 Replace done button with `ScannerTheme.makePillButton(style: .primary)` green pill
- [x] 5.4 Replace cancel button with themed secondary pill style
- [x] 5.5 Hide navigation bar, ensure black background and full-bleed image layout

## 6. CameraViewController Theme Restyling

- [x] 6.1 Hide navigation bar, set black background for full-bleed camera preview
- [x] 6.2 Replace flash toggle with frosted-glass pill button floating over preview
- [x] 6.3 Replace cancel button with frosted-glass pill floating at top-left
- [x] 6.4 Restyle capture button as large circle with white ring, add ring-pulse scale animation on tap
- [x] 6.5 Verify haptic feedback still fires on capture with new animation

## 7. ColorModeViewController Filter Strip

- [x] 7.1 Remove UISegmentedControl from color mode screen
- [x] 7.2 Create `FilterThumbnailCell` — circular UICollectionViewCell with image thumbnail, label beneath, highlighted ring for selection
- [x] 7.3 Add horizontal UICollectionView at bottom of screen with flow layout for filter strip
- [x] 7.4 Populate cells with pre-generated color mode preview thumbnails (original, grayscale, B&W)
- [x] 7.5 On cell selection, update the highlighted ring and trigger full-screen preview update
- [x] 7.6 Restyle confirm and re-crop buttons as themed pill buttons
- [x] 7.7 Hide navigation bar, set black background for full-bleed preview

## 8. SessionReviewViewController Theme Restyling

- [x] 8.1 Set black background, hide navigation bar
- [x] 8.2 Restyle page thumbnail cells as cards with rounded corners and subtle shadow
- [x] 8.3 Replace bottom buttons (Add Page, Save as PDF) with a floating frosted-glass action bar at bottom
- [x] 8.4 Style the "Save as PDF" button as a primary green pill within the floating bar
- [x] 8.5 Ensure page number badges are visible on dark card backgrounds

## 9. DocumentLibraryViewController Redesign

- [x] 9.1 Replace UITableView with UICollectionView using UICollectionViewCompositionalLayout
- [x] 9.2 Create `DocumentCardCell` — card-style UICollectionViewCell with large thumbnail, filename, page count, file size, date, rounded corners, shadow
- [x] 9.3 Migrate data source from table view to collection view (reuse existing DocumentLibraryViewModel)
- [x] 9.4 Migrate swipe-to-delete and edit mode functionality to collection view context menus
- [x] 9.5 Add floating action button (FAB) — circular green button with camera icon at bottom-right
- [x] 9.6 Wire FAB to trigger scanning (replace navigation bar scan button)
- [x] 9.7 Set black background, hide or make navigation bar transparent
- [x] 9.8 Update empty state view styling to match dark theme
- [x] 9.9 Update sort controls to use frosted-glass pill style

## 10. PDFPreviewViewController Theme Restyling

- [x] 10.1 Set black background, adjust PDFView appearance for dark theme
- [x] 10.2 Restyle share and more-options buttons as frosted-glass pills
- [x] 10.3 Update metadata label typography to use ScannerTheme fonts and white text

## 11. CornerHandleView Theme Update

- [x] 11.1 Update CornerHandleView colors to use ScannerTheme.Colors (white fill, green highlight accent)
- [x] 11.2 Verify handle sizing and touch targets remain at minimum 44x44pt
