//
//  DocumentStorageService.swift
//  DocumentScanner
//
//  Service for managing PDF document storage
//

import Foundation
import PDFKit
import os.log

private let storageLog = OSLog(subsystem: "com.documentscanner", category: "storage")

class DocumentStorageService {

    enum StorageError: Error {
        case directoryCreationFailed
        case fileWriteFailed
        case fileNotFound
        case insufficientStorage
        case invalidFilename
        case permissionDenied
    }

    private let fileManager = FileManager.default
    private let documentsDirectory: URL
    private let scannedDocumentsDirectory: URL

    init() {
        documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        scannedDocumentsDirectory = documentsDirectory.appendingPathComponent("ScannedDocuments", isDirectory: true)
    }

    func getScannedDocumentsDirectory() -> URL {
        return scannedDocumentsDirectory
    }

    func savePDF(
        _ pdfDocument: PDFDocument,
        filename: String,
        completion: @escaping (Result<URL, StorageError>) -> Void
    ) {
        DispatchQueue.global(qos: .userInitiated).async { [self] in

            // Ensure ScannedDocuments directory exists
            do {
                try self.ensureDirectoryExists()
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(.directoryCreationFailed))
                }
                return
            }

            // Sanitize filename
            let sanitizedFilename = self.sanitizeFilename(filename)

            // Handle duplicate filenames
            let finalFilename = self.handleDuplicateFilename(sanitizedFilename)

            let fileURL = self.scannedDocumentsDirectory.appendingPathComponent(finalFilename)

            // Check available storage
            if !self.hasEnoughStorage(for: pdfDocument) {
                DispatchQueue.main.async {
                    completion(.failure(.insufficientStorage))
                }
                return
            }

            // Write PDF to file
            guard let pdfData = pdfDocument.dataRepresentation() else {
                DispatchQueue.main.async {
                    completion(.failure(.fileWriteFailed))
                }
                return
            }

            do {
                try pdfData.write(to: fileURL, options: .atomic)
                DispatchQueue.main.async {
                    completion(.success(fileURL))
                }
            } catch let error as NSError where error.domain == NSCocoaErrorDomain && error.code == NSFileWriteNoPermissionError {
                DispatchQueue.main.async {
                    completion(.failure(.permissionDenied))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(.fileWriteFailed))
                }
            }
        }
    }

    func listDocuments() -> Result<[DocumentMetadata], StorageError> {
        do {
            try ensureDirectoryExists()

            let fileURLs = try fileManager.contentsOfDirectory(
                at: scannedDocumentsDirectory,
                includingPropertiesForKeys: [.fileSizeKey, .creationDateKey],
                options: [.skipsHiddenFiles]
            )

            let pdfURLs = fileURLs.filter { $0.pathExtension.lowercased() == "pdf" }

            var documents: [DocumentMetadata] = []

            for url in pdfURLs {
                if let metadata = createMetadata(for: url) {
                    documents.append(metadata)
                }
            }

            // Sort by creation date (newest first)
            documents.sort { $0.creationDate > $1.creationDate }

            return .success(documents)
        } catch {
            return .failure(.directoryCreationFailed)
        }
    }

    func deletePDF(at url: URL) -> Result<Void, StorageError> {
        guard fileManager.fileExists(atPath: url.path) else {
            return .failure(.fileNotFound)
        }

        do {
            try fileManager.removeItem(at: url)
            return .success(())
        } catch let error as NSError where error.domain == NSCocoaErrorDomain && error.code == NSFileWriteNoPermissionError {
            return .failure(.permissionDenied)
        } catch {
            return .failure(.fileWriteFailed)
        }
    }

    func renamePDF(at url: URL, to newFilename: String) -> Result<URL, StorageError> {
        guard fileManager.fileExists(atPath: url.path) else {
            return .failure(.fileNotFound)
        }

        let sanitizedFilename = sanitizeFilename(newFilename)
        let newURL = scannedDocumentsDirectory.appendingPathComponent(sanitizedFilename)

        do {
            try fileManager.moveItem(at: url, to: newURL)
            return .success(newURL)
        } catch {
            return .failure(.fileWriteFailed)
        }
    }

    func getStorageInfo() -> (used: Int64, available: Int64) {
        var used: Int64 = 0

        if let enumerator = fileManager.enumerator(at: scannedDocumentsDirectory, includingPropertiesForKeys: [.fileSizeKey]) {
            for case let fileURL as URL in enumerator {
                if let fileSize = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                    used += Int64(fileSize)
                }
            }
        }

        let available = getAvailableStorage()

        return (used, available)
    }

    // MARK: - Private Methods

    private func ensureDirectoryExists() throws {
        if !fileManager.fileExists(atPath: scannedDocumentsDirectory.path) {
            try fileManager.createDirectory(at: scannedDocumentsDirectory, withIntermediateDirectories: true)
        }
    }

    private func sanitizeFilename(_ filename: String) -> String {
        var sanitized = filename

        // Remove file extension if provided
        if sanitized.hasSuffix(".pdf") {
            sanitized = String(sanitized.dropLast(4))
        }

        // Remove invalid characters
        let invalidCharacters = CharacterSet(charactersIn: "/:\\?*|\"<>")
        sanitized = sanitized.components(separatedBy: invalidCharacters).joined(separator: "_")

        // Ensure filename is not empty
        if sanitized.trimmingCharacters(in: .whitespaces).isEmpty {
            sanitized = generateDefaultFilename()
        }

        return sanitized + ".pdf"
    }

    func generateDefaultFilename() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HHmmss"
        let timestamp = dateFormatter.string(from: Date())
        return "Document_\(timestamp).pdf"
    }

    private func handleDuplicateFilename(_ filename: String) -> String {
        var finalFilename = filename
        var counter = 1

        while fileManager.fileExists(atPath: scannedDocumentsDirectory.appendingPathComponent(finalFilename).path) {
            let nameWithoutExtension = (filename as NSString).deletingPathExtension
            let fileExtension = (filename as NSString).pathExtension
            finalFilename = "\(nameWithoutExtension) (\(counter)).\(fileExtension)"
            counter += 1
        }

        return finalFilename
    }

    private func hasEnoughStorage(for pdfDocument: PDFDocument) -> Bool {
        guard let pdfData = pdfDocument.dataRepresentation() else {
            return false
        }

        let requiredSpace = Int64(pdfData.count)
        let availableSpace = getAvailableStorage()

        // Require at least 50MB buffer
        let minimumBuffer: Int64 = 50 * 1024 * 1024

        return availableSpace > (requiredSpace + minimumBuffer)
    }

    private func getAvailableStorage() -> Int64 {
        do {
            let values = try documentsDirectory.resourceValues(forKeys: [.volumeAvailableCapacityKey])
            return Int64(values.volumeAvailableCapacity ?? 0)
        } catch {
            return 0
        }
    }

    private func createMetadata(for url: URL) -> DocumentMetadata? {
        do {
            let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey, .creationDateKey])

            guard let fileSize = resourceValues.fileSize,
                  let creationDate = resourceValues.creationDate else {
                return nil
            }

            // Load PDF to get page count - skip corrupt files
            guard let pdfDocument = PDFDocument(url: url) else {
                os_log("Unable to read PDF at %{public}@ - file may be corrupt", log: storageLog, type: .error, url.lastPathComponent)
                return nil
            }

            let pageCount = pdfDocument.pageCount

            return DocumentMetadata(
                filename: url.lastPathComponent,
                creationDate: creationDate,
                pageCount: pageCount,
                fileSize: Int64(fileSize)
            )
        } catch {
            os_log("Unable to read metadata for %{public}@: %{public}@", log: storageLog, type: .error, url.lastPathComponent, error.localizedDescription)
            return nil
        }
    }
}
