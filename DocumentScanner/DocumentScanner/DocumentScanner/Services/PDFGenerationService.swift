//
//  PDFGenerationService.swift
//  DocumentScanner
//
//  Service for generating multi-page PDF documents
//

import UIKit
import PDFKit

class PDFGenerationService {

    enum PDFError: Error {
        case noImages
        case pdfCreationFailed
        case compressionFailed
    }

    typealias ProgressHandler = (Int, Int) -> Void

    func createPDF(
        from images: [UIImage],
        progressHandler: ProgressHandler? = nil,
        completion: @escaping (Result<(PDFDocument, Int64), PDFError>) -> Void
    ) {
        DispatchQueue.global(qos: .userInitiated).async {
            guard !images.isEmpty else {
                DispatchQueue.main.async {
                    completion(.failure(.noImages))
                }
                return
            }

            let pdfDocument = PDFDocument()

            for (index, image) in images.enumerated() {
                // Compress image before adding to PDF
                guard let compressedImage = self.compressImage(image, quality: 0.8) else {
                    DispatchQueue.main.async {
                        completion(.failure(.compressionFailed))
                    }
                    return
                }

                guard let pdfPage = PDFPage(image: compressedImage) else {
                    DispatchQueue.main.async {
                        completion(.failure(.pdfCreationFailed))
                    }
                    return
                }

                pdfDocument.insert(pdfPage, at: index)

                // Report progress
                DispatchQueue.main.async {
                    progressHandler?(index + 1, images.count)
                }
            }

            // Set PDF metadata
            self.setPDFMetadata(for: pdfDocument)

            // Calculate file size
            guard let pdfData = pdfDocument.dataRepresentation() else {
                DispatchQueue.main.async {
                    completion(.failure(.pdfCreationFailed))
                }
                return
            }

            let fileSize = Int64(pdfData.count)

            DispatchQueue.main.async {
                completion(.success((pdfDocument, fileSize)))
            }
        }
    }

    private func compressImage(_ image: UIImage, quality: CGFloat) -> UIImage? {
        // Optionally downsample to 300 DPI
        let downsampledImage = downsampleIfNeeded(image, targetDPI: 300)

        // Apply JPEG compression
        guard let imageData = downsampledImage.jpegData(compressionQuality: quality),
              let compressedImage = UIImage(data: imageData) else {
            return nil
        }

        return compressedImage
    }

    private func downsampleIfNeeded(_ image: UIImage, targetDPI: CGFloat) -> UIImage {
        // Calculate if image exceeds 300 DPI
        // Assuming standard print size of 8.5x11 inches for letter size
        let maxDimension = max(image.size.width, image.size.height)
        let maxDimensionInInches: CGFloat = 11.0
        let currentDPI = maxDimension / maxDimensionInInches

        guard currentDPI > targetDPI else {
            return image // No downsampling needed
        }

        let scale = targetDPI / currentDPI
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)

        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let downsampledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return downsampledImage ?? image
    }

    private func setPDFMetadata(for document: PDFDocument) {
        let attributes: [PDFDocumentAttribute: Any] = [
            .creationDateAttribute: Date(),
            .creatorAttribute: "iOS Document Scanner",
            .producerAttribute: "iOS Document Scanner"
        ]

        document.documentAttributes = attributes
    }

    func estimateFileSize(for images: [UIImage]) -> Int64 {
        // Rough estimation: ~200-500 KB per page
        let averageSizePerPage: Int64 = 350_000 // 350 KB
        return Int64(images.count) * averageSizePerPage
    }
}
