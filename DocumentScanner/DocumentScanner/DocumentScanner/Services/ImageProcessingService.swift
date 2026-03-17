//
//  ImageProcessingService.swift
//  DocumentScanner
//
//  Service for image processing including perspective correction and color mode transformations
//

import UIKit
import CoreImage
import Accelerate

class ImageProcessingService {

    enum ProcessingError: Error {
        case invalidImage
        case perspectiveCorrectionFailed
        case colorModeProcessingFailed
    }

    private let ciContext = CIContext(options: [.useSoftwareRenderer: false])

    func processImage(
        _ image: UIImage,
        quadrilateral: DetectedQuadrilateral,
        colorMode: ColorMode,
        completion: @escaping (Result<UIImage, ProcessingError>) -> Void
    ) {
        DispatchQueue.global(qos: .userInitiated).async { [self] in

            guard var inputCIImage = CIImage(image: image) else {
                DispatchQueue.main.async {
                    completion(.failure(.invalidImage))
                }
                return
            }

            // Apply image orientation so CIImage coordinate space matches UIImage.size
            // CIImage(image:) does NOT apply orientation — the extent is in raw pixel space.
            // Our corner coordinates come from UIImage.size which IS orientation-aware.
            if image.imageOrientation != .up {
                inputCIImage = inputCIImage.oriented(forExifOrientation: Int32(image.cgImagePropertyOrientation.rawValue))
            }

            // Step 1: Apply perspective correction
            guard let correctedImage = self.applyPerspectiveCorrection(
                to: inputCIImage,
                quadrilateral: quadrilateral
            ) else {
                DispatchQueue.main.async {
                    completion(.failure(.perspectiveCorrectionFailed))
                }
                return
            }

            // Step 2: Apply color mode
            guard let processedImage = self.applyColorMode(to: correctedImage, mode: colorMode) else {
                DispatchQueue.main.async {
                    completion(.failure(.colorModeProcessingFailed))
                }
                return
            }

            // Step 3: Convert to UIImage (orientation is already applied, use .up)
            guard let cgImage = self.ciContext.createCGImage(processedImage, from: processedImage.extent) else {
                DispatchQueue.main.async {
                    completion(.failure(.colorModeProcessingFailed))
                }
                return
            }

            let finalImage = UIImage(cgImage: cgImage, scale: image.scale, orientation: .up)

            DispatchQueue.main.async {
                completion(.success(finalImage))
            }
        }
    }

    private func applyPerspectiveCorrection(to image: CIImage, quadrilateral: DetectedQuadrilateral) -> CIImage? {
        // Calculate destination rectangle size maintaining aspect ratio
        let destinationSize = calculateDestinationSize(for: quadrilateral)

        // CIPerspectiveCorrection uses Core Image coordinates (origin at bottom-left)
        // but our quadrilateral points are in UIKit coordinates (origin at top-left).
        // We need to flip Y: ciY = imageHeight - uikitY
        let imageHeight = image.extent.height

        let topLeft = CIVector(cgPoint: CGPoint(x: quadrilateral.topLeft.x, y: imageHeight - quadrilateral.topLeft.y))
        let topRight = CIVector(cgPoint: CGPoint(x: quadrilateral.topRight.x, y: imageHeight - quadrilateral.topRight.y))
        let bottomRight = CIVector(cgPoint: CGPoint(x: quadrilateral.bottomRight.x, y: imageHeight - quadrilateral.bottomRight.y))
        let bottomLeft = CIVector(cgPoint: CGPoint(x: quadrilateral.bottomLeft.x, y: imageHeight - quadrilateral.bottomLeft.y))

        guard let perspectiveFilter = CIFilter(name: "CIPerspectiveCorrection") else {
            return nil
        }

        perspectiveFilter.setValue(image, forKey: kCIInputImageKey)
        perspectiveFilter.setValue(topLeft, forKey: "inputTopLeft")
        perspectiveFilter.setValue(topRight, forKey: "inputTopRight")
        perspectiveFilter.setValue(bottomRight, forKey: "inputBottomRight")
        perspectiveFilter.setValue(bottomLeft, forKey: "inputBottomLeft")

        return perspectiveFilter.outputImage
    }

    private func calculateDestinationSize(for quadrilateral: DetectedQuadrilateral) -> CGSize {
        // Calculate width as average of top and bottom edges
        let topWidth = distance(from: quadrilateral.topLeft, to: quadrilateral.topRight)
        let bottomWidth = distance(from: quadrilateral.bottomLeft, to: quadrilateral.bottomRight)
        let width = (topWidth + bottomWidth) / 2

        // Calculate height as average of left and right edges
        let leftHeight = distance(from: quadrilateral.topLeft, to: quadrilateral.bottomLeft)
        let rightHeight = distance(from: quadrilateral.topRight, to: quadrilateral.bottomRight)
        let height = (leftHeight + rightHeight) / 2

        return CGSize(width: width, height: height)
    }

    private func distance(from point1: CGPoint, to point2: CGPoint) -> CGFloat {
        let dx = point2.x - point1.x
        let dy = point2.y - point1.y
        return sqrt(dx * dx + dy * dy)
    }

    private func applyColorMode(to image: CIImage, mode: ColorMode) -> CIImage? {
        switch mode {
        case .original:
            return image

        case .grayscale:
            return applyGrayscale(to: image)

        case .blackAndWhite:
            return applyBlackAndWhite(to: image)
        }
    }

    private func applyGrayscale(to image: CIImage) -> CIImage? {
        guard let colorControlsFilter = CIFilter(name: "CIColorControls") else {
            return nil
        }

        colorControlsFilter.setValue(image, forKey: kCIInputImageKey)
        colorControlsFilter.setValue(0.0, forKey: kCIInputSaturationKey)

        return colorControlsFilter.outputImage
    }

    private func applyBlackAndWhite(to image: CIImage) -> CIImage? {
        // First convert to grayscale
        guard let grayscaleImage = applyGrayscale(to: image) else {
            return nil
        }

        // Calculate optimal threshold using histogram analysis
        let threshold = calculateAdaptiveThreshold(for: grayscaleImage)

        // Apply threshold
        guard let colorMatrix = CIFilter(name: "CIColorMatrix") else {
            return nil
        }

        // Create a high contrast black and white effect
        let rVector = CIVector(x: 3.5, y: 0, z: 0, w: 0)
        let gVector = CIVector(x: 0, y: 3.5, z: 0, w: 0)
        let bVector = CIVector(x: 0, y: 0, z: 3.5, w: 0)
        let biasVector = CIVector(x: -threshold, y: -threshold, z: -threshold, w: 0)

        colorMatrix.setValue(grayscaleImage, forKey: kCIInputImageKey)
        colorMatrix.setValue(rVector, forKey: "inputRVector")
        colorMatrix.setValue(gVector, forKey: "inputGVector")
        colorMatrix.setValue(bVector, forKey: "inputBVector")
        colorMatrix.setValue(biasVector, forKey: "inputBiasVector")

        // Clamp to ensure pure black and white
        guard let clampFilter = CIFilter(name: "CIColorClamp") else {
            return colorMatrix.outputImage
        }

        clampFilter.setValue(colorMatrix.outputImage, forKey: kCIInputImageKey)
        clampFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputMinComponents")
        clampFilter.setValue(CIVector(x: 1, y: 1, z: 1, w: 1), forKey: "inputMaxComponents")

        return clampFilter.outputImage
    }

    private func calculateAdaptiveThreshold(for image: CIImage) -> CGFloat {
        // Sample the image to calculate histogram
        // For simplicity, use a fixed threshold that works well for most documents
        // A more sophisticated implementation would analyze the actual histogram
        return 0.5
    }

    // MARK: - Convenience Methods

    func cropAndCorrect(
        _ image: UIImage,
        corners: [CGPoint],
        completion: @escaping (Result<UIImage, ProcessingError>) -> Void
    ) {
        guard corners.count == 4 else {
            completion(.failure(.invalidImage))
            return
        }

        // Convert normalized corners to image coordinates
        let imageSize = image.size
        let quad = DetectedQuadrilateral(
            topLeft: CGPoint(x: corners[0].x * imageSize.width, y: corners[0].y * imageSize.height),
            topRight: CGPoint(x: corners[1].x * imageSize.width, y: corners[1].y * imageSize.height),
            bottomRight: CGPoint(x: corners[2].x * imageSize.width, y: corners[2].y * imageSize.height),
            bottomLeft: CGPoint(x: corners[3].x * imageSize.width, y: corners[3].y * imageSize.height),
            confidence: 1.0
        )

        processImage(image, quadrilateral: quad, colorMode: .original, completion: completion)
    }

    func applyColorMode(
        _ image: UIImage,
        mode: ColorMode,
        completion: @escaping (Result<UIImage, ProcessingError>) -> Void
    ) {
        DispatchQueue.global(qos: .userInitiated).async { [self] in

            guard let inputCIImage = CIImage(image: image) else {
                DispatchQueue.main.async { completion(.failure(.invalidImage)) }
                return
            }

            guard let processed = self.applyColorMode(to: inputCIImage, mode: mode),
                  let cgImage = self.ciContext.createCGImage(processed, from: processed.extent) else {
                DispatchQueue.main.async { completion(.failure(.colorModeProcessingFailed)) }
                return
            }

            let result = UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
            DispatchQueue.main.async { completion(.success(result)) }
        }
    }
}

// MARK: - UIImage Orientation to CGImagePropertyOrientation
extension UIImage {
    var cgImagePropertyOrientation: CGImagePropertyOrientation {
        switch imageOrientation {
        case .up: return .up
        case .upMirrored: return .upMirrored
        case .down: return .down
        case .downMirrored: return .downMirrored
        case .left: return .left
        case .leftMirrored: return .leftMirrored
        case .right: return .right
        case .rightMirrored: return .rightMirrored
        @unknown default: return .up
        }
    }
}
