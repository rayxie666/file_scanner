//
//  DocumentScannerUITests.swift
//  DocumentScannerUITests
//
//  UI tests for critical flows in DocumentScanner
//

import XCTest

final class DocumentScannerUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Document Library Tests

    @MainActor
    func testDocumentLibraryLoads() throws {
        // Verify the main library screen appears
        let documentList = app.tables["documentList"]
        let emptyState = app.staticTexts["No Documents"]

        // Either the table or empty state should be visible
        let tableExists = documentList.waitForExistence(timeout: 5)
        let emptyExists = emptyState.exists

        XCTAssertTrue(tableExists || emptyExists, "Document library should show either document list or empty state")
    }

    @MainActor
    func testScanButtonExists() throws {
        let scanButton = app.buttons["scanButton"]
        XCTAssertTrue(scanButton.waitForExistence(timeout: 5), "Scan button should exist")
    }

    @MainActor
    func testSortButtonExists() throws {
        let sortButton = app.buttons["sortButton"]
        XCTAssertTrue(sortButton.waitForExistence(timeout: 5), "Sort button should exist")
    }

    @MainActor
    func testSortMenuAppears() throws {
        let sortButton = app.buttons["sortButton"]
        guard sortButton.waitForExistence(timeout: 5) else {
            XCTFail("Sort button not found")
            return
        }

        sortButton.tap()

        // Verify sort options appear
        let newestFirst = app.buttons["Newest First"]
        XCTAssertTrue(newestFirst.waitForExistence(timeout: 3), "Sort menu should show 'Newest First' option")
    }

    @MainActor
    func testSelectModeToggle() throws {
        let editButton = app.buttons["editButton"]
        guard editButton.waitForExistence(timeout: 5) else {
            XCTFail("Edit/Select button not found")
            return
        }

        editButton.tap()

        // The delete selected button should appear
        let deleteSelectedButton = app.buttons["deleteSelectedButton"]
        XCTAssertTrue(deleteSelectedButton.exists, "Delete Selected button should appear in edit mode")

        // Tap again to exit edit mode
        editButton.tap()
        XCTAssertFalse(deleteSelectedButton.isHittable, "Delete Selected button should be hidden after exiting edit mode")
    }

    // MARK: - Launch Performance

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
