//
//  SessionViewModel.swift
//  DocumentScanner
//
//  ViewModel for managing scanning session
//

import Foundation
import Combine
import UIKit
import PDFKit

class SessionViewModel: ObservableObject {

    @Published var pages: [ScannedPage] = []
    @Published var isGeneratingPDF = false
    @Published var pdfProgress: (current: Int, total: Int)?
    @Published var errorMessage: String?

    private let sessionManager = ScanSessionManager.shared
    private let pdfGenerationService = PDFGenerationService()
    private let storageService = DocumentStorageService()

    init() {
        loadSession()
    }

    func loadSession() {
        pages = sessionManager.currentSession?.pages ?? []
    }

    func addPage(_ page: ScannedPage) {
        sessionManager.addPage(page)
        loadSession()
    }

    func removePage(at index: Int) {
        sessionManager.removePage(at: index)
        loadSession()
    }

    func movePage(from sourceIndex: Int, to destinationIndex: Int) {
        sessionManager.movePage(from: sourceIndex, to: destinationIndex)
        loadSession()
    }

    func generatePDF(filename: String, completion: @escaping (Result<URL, Error>) -> Void) {
        guard !pages.isEmpty else {
            completion(.failure(PDFGenerationService.PDFError.noImages))
            return
        }

        isGeneratingPDF = true
        errorMessage = nil

        let images = pages.map { $0.croppedImage }

        pdfGenerationService.createPDF(from: images, progressHandler: { [weak self] current, total in
            self?.pdfProgress = (current, total)
        }) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let (pdfDocument, _)):
                self.savePDFDocument(pdfDocument, filename: filename, completion: completion)

            case .failure(let error):
                self.isGeneratingPDF = false
                self.pdfProgress = nil
                completion(.failure(error))
            }
        }
    }

    private func savePDFDocument(_ pdfDocument: PDFDocument, filename: String, completion: @escaping (Result<URL, Error>) -> Void) {
        storageService.savePDF(pdfDocument, filename: filename) { [weak self] result in
            guard let self = self else { return }

            self.isGeneratingPDF = false
            self.pdfProgress = nil

            switch result {
            case .success(let url):
                self.sessionManager.endSession()
                self.pages = []
                completion(.success(url))

            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func clearSession() {
        sessionManager.endSession()
        pages = []
    }
}
