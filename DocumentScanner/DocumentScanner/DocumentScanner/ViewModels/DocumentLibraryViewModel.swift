//
//  DocumentLibraryViewModel.swift
//  DocumentScanner
//
//  ViewModel for document library
//

import Foundation
import Combine

class DocumentLibraryViewModel: ObservableObject {

    @Published var documents: [DocumentMetadata] = []
    @Published var sortOrder: SortOrder = .dateDescending
    @Published var storageUsed: Int64 = 0
    @Published var storageAvailable: Int64 = 0
    @Published var errorMessage: String?

    private let storageService = DocumentStorageService()

    enum SortOrder {
        case dateDescending
        case dateAscending
        case alphabetical
    }

    init() {
        // Delay initialization to avoid crashes during app startup
        DispatchQueue.main.async { [weak self] in
            self?.loadDocuments()
            self?.updateStorageInfo()
        }
    }

    func loadDocuments() {
        let result = storageService.listDocuments()

        switch result {
        case .success(let docs):
            documents = docs
            applySorting()

        case .failure(let error):
            errorMessage = "Failed to load documents: \(error)"
        }
    }

    func deleteDocument(_ metadata: DocumentMetadata, completion: @escaping (Bool) -> Void) {
        let url = storageService.getScannedDocumentsDirectory().appendingPathComponent(metadata.filename)

        let result = storageService.deletePDF(at: url)

        switch result {
        case .success:
            loadDocuments()
            updateStorageInfo()
            completion(true)

        case .failure(let error):
            errorMessage = "Failed to delete document: \(error)"
            completion(false)
        }
    }

    func renameDocument(_ metadata: DocumentMetadata, to newFilename: String, completion: @escaping (Bool) -> Void) {
        let url = storageService.getScannedDocumentsDirectory().appendingPathComponent(metadata.filename)

        let result = storageService.renamePDF(at: url, to: newFilename)

        switch result {
        case .success:
            loadDocuments()
            completion(true)

        case .failure(let error):
            errorMessage = "Failed to rename document: \(error)"
            completion(false)
        }
    }

    func changeSortOrder(to order: SortOrder) {
        sortOrder = order
        applySorting()
    }

    private func applySorting() {
        switch sortOrder {
        case .dateDescending:
            documents.sort { $0.creationDate > $1.creationDate }

        case .dateAscending:
            documents.sort { $0.creationDate < $1.creationDate }

        case .alphabetical:
            documents.sort { $0.filename.lowercased() < $1.filename.lowercased() }
        }
    }

    func updateStorageInfo() {
        let (used, available) = storageService.getStorageInfo()
        storageUsed = used
        storageAvailable = available
    }

    func isLowStorage() -> Bool {
        let lowStorageThreshold: Int64 = 100 * 1024 * 1024 // 100 MB
        return storageAvailable < lowStorageThreshold
    }
}
