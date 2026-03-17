## ADDED Requirements

### Requirement: Image downsampling for previews
The system SHALL display downsampled preview images in the UI while preserving full-resolution images for PDF generation.

#### Scenario: Session review uses thumbnails
- **WHEN** pages are displayed in the session review grid
- **THEN** the system SHALL generate and display thumbnails at the cell's display resolution (not full camera resolution)

#### Scenario: Full resolution preserved for PDF
- **WHEN** the user saves a PDF
- **THEN** the PDF generation service SHALL use the original full-resolution images, not the downsampled thumbnails

### Requirement: Thumbnail caching with NSCache
The system SHALL cache generated thumbnails in memory using NSCache to avoid redundant processing.

#### Scenario: Cached thumbnail reused
- **WHEN** a page thumbnail has already been generated and the cell is recycled
- **THEN** the system SHALL serve the thumbnail from the cache without regenerating it

#### Scenario: Cache evicts under memory pressure
- **WHEN** the system is under memory pressure
- **THEN** NSCache SHALL automatically evict thumbnails, and the system SHALL regenerate them on demand without crashing

### Requirement: Lazy loading for document library thumbnails
The system SHALL lazy-load PDF thumbnail previews in the document library rather than loading all at once.

#### Scenario: Thumbnails load as cells appear
- **WHEN** the user scrolls through the document library
- **THEN** PDF thumbnails SHALL load on a background queue and appear as they become ready, with a placeholder shown until loaded

#### Scenario: Rapid scrolling cancels stale loads
- **WHEN** the user scrolls quickly past multiple cells
- **THEN** the system SHALL prioritize loading thumbnails for currently visible cells over cells that have scrolled off-screen

### Requirement: Background queue processing for all image operations
The system SHALL perform all image processing operations on background queues, never blocking the main thread.

#### Scenario: Color mode change remains responsive
- **WHEN** the user switches between color modes on the color mode screen
- **THEN** the UI SHALL remain responsive (no frame drops) while processing happens on a background queue

#### Scenario: PDF generation does not freeze UI
- **WHEN** a multi-page PDF is being generated
- **THEN** the progress view SHALL update smoothly without the UI freezing
