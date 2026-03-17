//
//  DocumentScannerTests.swift
//  DocumentScannerTests
//
//  Unit tests for DocumentScanner services and models
//

import Testing
import UIKit
@testable import DocumentScanner

// MARK: - ScanSession Tests

struct ScanSessionTests {

    private func makeTestImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 100, height: 100))
        return renderer.image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 100, height: 100))
        }
    }

    private func makePage(number: Int) -> ScannedPage {
        let img = makeTestImage()
        return ScannedPage(originalImage: img, croppedImage: img, colorMode: .original, pageNumber: number)
    }

    @Test func addPage() {
        let session = ScanSession()
        #expect(session.pages.isEmpty)

        let page = makePage(number: 1)
        session.addPage(page)
        #expect(session.pages.count == 1)
        #expect(session.pages[0].pageNumber == 1)
    }

    @Test func addMultiplePages() {
        let session = ScanSession()
        session.addPage(makePage(number: 1))
        session.addPage(makePage(number: 2))
        session.addPage(makePage(number: 3))
        #expect(session.pages.count == 3)
    }

    @Test func removePage() {
        let session = ScanSession()
        session.addPage(makePage(number: 1))
        session.addPage(makePage(number: 2))
        session.addPage(makePage(number: 3))

        session.removePage(at: 1)
        #expect(session.pages.count == 2)
        // Page numbers should be renumbered
        #expect(session.pages[0].pageNumber == 1)
        #expect(session.pages[1].pageNumber == 2)
    }

    @Test func removePageOutOfBounds() {
        let session = ScanSession()
        session.addPage(makePage(number: 1))

        // Should not crash
        session.removePage(at: -1)
        session.removePage(at: 5)
        #expect(session.pages.count == 1)
    }

    @Test func movePage() {
        let session = ScanSession()
        session.addPage(makePage(number: 1))
        session.addPage(makePage(number: 2))
        session.addPage(makePage(number: 3))

        session.movePage(from: 0, to: 2)
        #expect(session.pages.count == 3)
        // After move, page numbers are renumbered
        #expect(session.pages[0].pageNumber == 1)
        #expect(session.pages[1].pageNumber == 2)
        #expect(session.pages[2].pageNumber == 3)
    }

    @Test func movePageOutOfBounds() {
        let session = ScanSession()
        session.addPage(makePage(number: 1))

        // Should not crash
        session.movePage(from: -1, to: 0)
        session.movePage(from: 0, to: 5)
        #expect(session.pages.count == 1)
    }

    @Test func updatePageNumbersAfterRemove() {
        let session = ScanSession()
        session.addPage(makePage(number: 1))
        session.addPage(makePage(number: 2))
        session.addPage(makePage(number: 3))
        session.addPage(makePage(number: 4))

        session.removePage(at: 0)
        // Pages should be renumbered 1, 2, 3
        for (index, page) in session.pages.enumerated() {
            #expect(page.pageNumber == index + 1)
        }
    }
}

// MARK: - DetectedQuadrilateral Tests

struct DetectedQuadrilateralTests {

    @Test func pointsArray() {
        let quad = DetectedQuadrilateral(
            topLeft: CGPoint(x: 0, y: 0),
            topRight: CGPoint(x: 100, y: 0),
            bottomRight: CGPoint(x: 100, y: 100),
            bottomLeft: CGPoint(x: 0, y: 100),
            confidence: 0.9
        )

        #expect(quad.points.count == 4)
        #expect(quad.points[0] == CGPoint(x: 0, y: 0))
        #expect(quad.points[1] == CGPoint(x: 100, y: 0))
        #expect(quad.points[2] == CGPoint(x: 100, y: 100))
        #expect(quad.points[3] == CGPoint(x: 0, y: 100))
    }
}

// MARK: - EdgeDetectionService Tests

struct EdgeDetectionServiceTests {

    private func makeTestImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 200, height: 300))
        return renderer.image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 200, height: 300))
        }
    }

    @Test func detectEdgesReturnsResult() async {
        let service = EdgeDetectionService()
        let image = makeTestImage()

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            service.detectEdges(in: image) { result in
                switch result {
                case .success(let quad):
                    // Either detects or returns fallback - both are success
                    #expect(quad.points.count == 4)
                case .failure:
                    // Detection may fail on a plain white image, that's acceptable
                    break
                }
                continuation.resume()
            }
        }
    }
}

// MARK: - PDFGenerationService Tests

struct PDFGenerationServiceTests {

    private func makeTestImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 200, height: 300))
        return renderer.image { ctx in
            UIColor.blue.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 200, height: 300))
        }
    }

    @Test func createPDFWithOneImage() async {
        let service = PDFGenerationService()
        let image = makeTestImage()

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            service.createPDF(from: [image]) { result in
                switch result {
                case .success(let (pdfDocument, fileSize)):
                    #expect(pdfDocument.pageCount == 1)
                    #expect(fileSize > 0)
                case .failure(let error):
                    Issue.record("PDF creation should succeed: \(error)")
                }
                continuation.resume()
            }
        }
    }

    @Test func createPDFWithMultipleImages() async {
        let service = PDFGenerationService()
        let images = [makeTestImage(), makeTestImage(), makeTestImage()]

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            service.createPDF(from: images) { result in
                switch result {
                case .success(let (pdfDocument, _)):
                    #expect(pdfDocument.pageCount == 3)
                case .failure(let error):
                    Issue.record("PDF creation should succeed: \(error)")
                }
                continuation.resume()
            }
        }
    }

    @Test func createPDFWithEmptyArray() async {
        let service = PDFGenerationService()

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            service.createPDF(from: []) { result in
                switch result {
                case .success:
                    Issue.record("PDF creation with empty array should fail")
                case .failure(let error):
                    #expect(error == .noImages)
                }
                continuation.resume()
            }
        }
    }

    @Test func createPDFReportsProgress() async {
        let service = PDFGenerationService()
        let images = [makeTestImage(), makeTestImage()]
        var progressUpdates: [(Int, Int)] = []

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            service.createPDF(from: images, progressHandler: { current, total in
                progressUpdates.append((current, total))
            }) { _ in
                continuation.resume()
            }
        }

        #expect(progressUpdates.count == 2)
        #expect(progressUpdates[0] == (1, 2))
        #expect(progressUpdates[1] == (2, 2))
    }

    @Test func estimateFileSize() {
        let service = PDFGenerationService()
        let estimate = service.estimateFileSize(for: [UIImage(), UIImage(), UIImage()])
        #expect(estimate > 0)
    }
}

// MARK: - DocumentStorageService Tests

struct DocumentStorageServiceTests {

    @Test func generateDefaultFilename() {
        let service = DocumentStorageService()
        let filename = service.generateDefaultFilename()
        #expect(filename.hasPrefix("Document_"))
        #expect(filename.hasSuffix(".pdf"))
    }

    @Test func getScannedDocumentsDirectory() {
        let service = DocumentStorageService()
        let dir = service.getScannedDocumentsDirectory()
        #expect(dir.lastPathComponent == "ScannedDocuments")
    }
}

// MARK: - DocumentMetadata Tests

struct DocumentMetadataTests {

    @Test func formattedFileSize() {
        let metadata = DocumentMetadata(
            filename: "test.pdf",
            creationDate: Date(),
            pageCount: 5,
            fileSize: 1_048_576 // 1 MB
        )
        #expect(!metadata.formattedFileSize.isEmpty)
    }

    @Test func formattedDate() {
        let metadata = DocumentMetadata(
            filename: "test.pdf",
            creationDate: Date(),
            pageCount: 1,
            fileSize: 1024
        )
        #expect(!metadata.formattedDate.isEmpty)
    }
}

// MARK: - ColorMode Tests

struct ColorModeTests {

    @Test func allCases() {
        #expect(ColorMode.allCases.count == 3)
        #expect(ColorMode.allCases.contains(.original))
        #expect(ColorMode.allCases.contains(.grayscale))
        #expect(ColorMode.allCases.contains(.blackAndWhite))
    }

    @Test func rawValues() {
        #expect(ColorMode.original.rawValue == "Original Color")
        #expect(ColorMode.grayscale.rawValue == "Grayscale")
        #expect(ColorMode.blackAndWhite.rawValue == "Black & White")
    }

    @Test func description() {
        #expect(ColorMode.original.description == "Original Color")
    }
}

// MARK: - ScannedPage Tests

struct ScannedPageTests {

    @Test func initialization() {
        let img = UIGraphicsImageRenderer(size: CGSize(width: 10, height: 10)).image { _ in }
        let page = ScannedPage(originalImage: img, croppedImage: img, colorMode: .grayscale, pageNumber: 3)
        #expect(page.pageNumber == 3)
        #expect(page.colorMode == .grayscale)
    }

    @Test func mutablePageNumber() {
        let img = UIGraphicsImageRenderer(size: CGSize(width: 10, height: 10)).image { _ in }
        var page = ScannedPage(originalImage: img, croppedImage: img, colorMode: .original, pageNumber: 1)
        page.pageNumber = 5
        #expect(page.pageNumber == 5)
    }
}
