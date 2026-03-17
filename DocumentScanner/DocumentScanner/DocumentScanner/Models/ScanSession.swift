//
//  ScanSession.swift
//  DocumentScanner
//
//  Model representing a scanning session with multiple pages
//

import Foundation

class ScanSession {
    var pages: [ScannedPage]
    let dateCreated: Date

    init(pages: [ScannedPage] = [], dateCreated: Date = Date()) {
        self.pages = pages
        self.dateCreated = dateCreated
    }

    func addPage(_ page: ScannedPage) {
        pages.append(page)
    }

    func removePage(at index: Int) {
        guard index >= 0 && index < pages.count else { return }
        pages.remove(at: index)
        updatePageNumbers()
    }

    func movePage(from sourceIndex: Int, to destinationIndex: Int) {
        guard sourceIndex >= 0 && sourceIndex < pages.count &&
              destinationIndex >= 0 && destinationIndex < pages.count else { return }
        let page = pages.remove(at: sourceIndex)
        pages.insert(page, at: destinationIndex)
        updatePageNumbers()
    }

    private func updatePageNumbers() {
        for (index, _) in pages.enumerated() {
            pages[index].pageNumber = index + 1
        }
    }
}
