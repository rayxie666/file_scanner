//
//  ScanSessionManager.swift
//  DocumentScanner
//
//  Manages the current scanning session
//

import Foundation

class ScanSessionManager {

    static let shared = ScanSessionManager()

    private(set) var currentSession: ScanSession?

    private init() {}

    func startNewSession() {
        currentSession = ScanSession()
    }

    func addPage(_ page: ScannedPage) {
        guard let session = currentSession else {
            startNewSession()
            currentSession?.addPage(page)
            return
        }

        session.addPage(page)
    }

    func removePage(at index: Int) {
        currentSession?.removePage(at: index)
    }

    func movePage(from sourceIndex: Int, to destinationIndex: Int) {
        currentSession?.movePage(from: sourceIndex, to: destinationIndex)
    }

    func endSession() {
        currentSession = nil
    }

    func hasPages() -> Bool {
        return (currentSession?.pages.count ?? 0) > 0
    }

    func pageCount() -> Int {
        return currentSession?.pages.count ?? 0
    }
}
