## Context

The Document Scanner iOS app has a fully functional core: camera capture, edge detection, crop adjustment, color modes, PDF generation, document storage, and a coordinator-driven navigation flow across 26 Swift files. The app uses MVVM with Combine, UIKit for primary UI, and native frameworks only (AVFoundation, Vision, PDFKit, Core Image).

The codebase is missing production-readiness features: accessibility support, error resilience for edge cases, performance optimization for older devices, automated tests, and code quality cleanup. These are cross-cutting concerns that touch every view controller and most services.

**Constraints:**
- iOS 14.0+ deployment target
- No third-party dependencies
- All existing services and view controllers must remain backward-compatible
- Tests must work in both simulator and device contexts (camera tests are device-only)

## Goals / Non-Goals

**Goals:**
- Make every screen fully accessible via VoiceOver and Dynamic Type
- Prevent crashes from corrupt files, interrupted sessions, and permission errors
- Optimize image handling so the app remains responsive on iPhone 8-class hardware
- Achieve meaningful test coverage for services, models, and critical UI flows
- Clean up code quality issues (force-unwraps, debug prints, unused code)
- Prepare project metadata for App Store submission

**Non-Goals:**
- Adding new user-facing features beyond the minor gaps (grid overlay, bulk edit, filename validation)
- Redesigning any existing UI screens or changing the navigation flow
- Adding localization or multi-language support
- Implementing OCR, cloud sync, or other major feature additions
- Achieving 100% test coverage — focus on services and critical paths

## Decisions

### 1. Accessibility Approach: Programmatic Labels on UIKit Views

**Decision**: Add accessibility properties directly in each UIViewController's setup methods rather than using Interface Builder or a centralized accessibility manager.

**Rationale**:
- All views are created programmatically, so labels belong alongside the UI code
- Each view controller already has a `setupUI()` method — accessibility fits naturally there
- Centralized approaches add indirection for minimal benefit at this scale

**Alternatives Considered**:
- Accessibility configuration file/manager: Over-engineered for ~6 view controllers
- SwiftUI accessibility modifiers: Would require rewriting UIKit views

### 2. Error Resilience: Guard-and-Skip Pattern for Corrupt Files

**Decision**: When listing documents, skip corrupt/unreadable PDFs silently and log the error. Do not show error dialogs for individual corrupt files in the library.

**Rationale**:
- Users should not be blocked from using the app because one file is corrupt
- The existing `createMetadata(for:)` method already returns nil for unreadable PDFs — this behavior just needs to be preserved and documented
- Logging enables debugging without disrupting UX

**Alternatives Considered**:
- Show error badge on corrupt files: Adds UI complexity, users can't fix corrupt files anyway
- Delete corrupt files automatically: Destructive, could lose data the user values

### 3. Session Recovery: UserDefaults with Serialized Page References

**Decision**: On session interruption (backgrounding, phone call), persist the current session state to UserDefaults by saving image file paths (writing temp images to the Caches directory). On next launch, check for a recovery file and offer to resume.

**Rationale**:
- UserDefaults is simple and synchronous for small metadata
- Writing images to Caches avoids filling Documents with temp data
- Asking the user whether to resume (vs. auto-resuming) avoids confusion

**Alternatives Considered**:
- Core Data: Overkill for a single recovery record
- NSCoding with file archiver: More complex, same result
- No recovery: Acceptable for v1 but frustrating for multi-page sessions

### 4. Performance: Thumbnail Cache with NSCache

**Decision**: Use NSCache for in-memory thumbnail caching in both the session review grid and document library. Generate thumbnails at display resolution (e.g., 200x280pt) rather than passing full-resolution images to collection/table view cells.

**Rationale**:
- NSCache automatically evicts under memory pressure — no manual management needed
- Thumbnails for a 10-page session at 200x280 are ~2-4MB vs. ~100MB+ for full-resolution images
- Generation happens on a background queue, cells show a placeholder until ready

**Alternatives Considered**:
- Disk-based thumbnail cache: Adds I/O complexity, NSCache is sufficient for session-scoped data
- Downsample at capture time: Loses full resolution for PDF generation

### 5. Testing Strategy: XCTest for Services, XCUITest for Flows

**Decision**: Write XCTest unit tests for all 5 services and the model layer. Write XCUITest UI tests for 3 critical flows (scan-to-save, library management, share). Skip camera-dependent tests in CI (mark as device-only).

**Rationale**:
- Services are stateless or file-based — straightforward to test
- UI tests for the full flow catch integration issues
- Camera tests cannot run in simulator — marking them avoids CI failures

**Alternatives Considered**:
- Snapshot testing: Requires third-party dependency (iOSSnapshotTestCase), violates no-dependencies constraint
- Mock camera for simulator tests: Complex AVFoundation mocking for limited value

### 6. Haptic Feedback: UIImpactFeedbackGenerator at Key Interaction Points

**Decision**: Add haptic feedback at three points: photo capture (medium impact), corner handle drag begin (light impact), and page delete (notification warning).

**Rationale**:
- These are the key physical interaction moments where haptics reinforce the action
- UIImpactFeedbackGenerator is available on iOS 10+ and costs nothing to add
- Keeping haptics sparse avoids annoyance

**Alternatives Considered**:
- Haptics on every button tap: Too noisy, reduces the signal of important actions
- No haptics: Acceptable but misses easy polish

### 7. Code Quality: Manual Review Over SwiftLint

**Decision**: Do a manual pass to fix force-unwraps, remove debug prints, and resolve TODOs. Run SwiftLint once for a baseline check but do not add it as a build phase dependency.

**Rationale**:
- The codebase is small enough (~1,500 lines) for a manual audit
- Adding SwiftLint as a build dependency introduces tooling complexity for a solo project
- A one-time lint check catches style issues without ongoing overhead

**Alternatives Considered**:
- SwiftLint as build phase: Ongoing value but adds build-time dependency management
- SwiftFormat: Complementary but not needed for this scope

## Risks / Trade-offs

### Risk: Session Recovery Data Loss
**Impact**: If the app crashes mid-write to UserDefaults, recovery data could be incomplete or corrupted.
**Mitigation**: Write recovery data atomically (serialize to Data, write in one operation). Accept that crashes during the write itself may lose the recovery — this is an edge case of an edge case.

### Risk: Dynamic Type Breaking Layouts
**Impact**: Very large accessibility text sizes could overflow fixed-height cells or overlap buttons.
**Mitigation**: Use `adjustsFontForContentSizeCategory = true` and test at the largest accessibility size. Use `UIStackView` with flexible spacing where possible. Accept minor layout compromises at extreme sizes.

### Risk: Performance Profiling Results May Require Architecture Changes
**Impact**: If edge detection or perspective correction are unacceptably slow on iPhone 8, fixes may require more than optimization — potentially reducing image resolution or adding a loading UI.
**Mitigation**: Profile first, optimize second. The existing async/background-queue architecture already handles latency. If processing exceeds 3 seconds, show a progress indicator (already partially implemented). Do not reduce output quality for PDF generation.

### Trade-off: Test Coverage Gaps for Camera-Dependent Features
**Impact**: Camera capture, edge detection on real images, and tap-to-focus cannot be tested in CI.
**Mitigation**: Manual testing checklist for physical device validation. These features use well-tested Apple frameworks (AVFoundation, Vision) which reduces the risk of regressions.

### Trade-off: No Localization
**Impact**: All accessibility labels and UI strings are English-only.
**Mitigation**: Use `NSLocalizedString` wrappers now so localization can be added later without code changes. This is a non-goal for this change but the pattern costs nothing to establish.

## Open Questions

1. **App icon**: Should we design a custom icon or use a placeholder SF Symbol-based icon for initial release?
2. **App Store metadata**: Is this targeting TestFlight first or direct App Store submission?
3. **Minimum test coverage threshold**: Is there a target percentage, or is "all services + critical flows" sufficient?
