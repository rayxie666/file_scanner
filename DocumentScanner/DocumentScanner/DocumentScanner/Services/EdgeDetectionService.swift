//
//  EdgeDetectionService.swift
//  DocumentScanner
//
//  Service for automatic document edge detection using Vision framework
//

import UIKit
import Vision

struct DetectedQuadrilateral {
    let topLeft: CGPoint
    let topRight: CGPoint
    let bottomRight: CGPoint
    let bottomLeft: CGPoint
    let confidence: Float

    var points: [CGPoint] {
        return [topLeft, topRight, bottomRight, bottomLeft]
    }
}

class EdgeDetectionService {

    enum EdgeDetectionError: Error {
        case noImageData
        case detectionFailed
        case noRectangleDetected
        case timeout
    }

    private let minimumConfidence: Float = 0.6
    private let minimumAspectRatio: Float = 0.3
    private let timeoutSeconds: TimeInterval = 3.0

    func detectEdges(in image: UIImage, completion: @escaping (Result<DetectedQuadrilateral, EdgeDetectionError>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [self] in

            guard let cgImage = image.cgImage else {
                DispatchQueue.main.async {
                    completion(.failure(.noImageData))
                }
                return
            }

            let request = VNDetectRectanglesRequest { request, error in
                self.handleDetectionResult(request: request, error: error, imageSize: image.size, completion: completion)
            }

            request.minimumConfidence = self.minimumConfidence
            request.minimumAspectRatio = VNAspectRatio(self.minimumAspectRatio)
            request.maximumObservations = 1

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

            let timeoutWorkItem = DispatchWorkItem {
                let fallbackQuad = self.createFallbackQuadrilateral(for: image.size)
                DispatchQueue.main.async {
                    completion(.success(fallbackQuad))
                }
            }

            DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + self.timeoutSeconds, execute: timeoutWorkItem)

            do {
                try handler.perform([request])
                timeoutWorkItem.cancel()
            } catch {
                timeoutWorkItem.cancel()
                DispatchQueue.main.async {
                    completion(.failure(.detectionFailed))
                }
            }
        }
    }

    private func handleDetectionResult(request: VNRequest, error: Error?, imageSize: CGSize, completion: @escaping (Result<DetectedQuadrilateral, EdgeDetectionError>) -> Void) {
        guard error == nil else {
            let fallbackQuad = createFallbackQuadrilateral(for: imageSize)
            DispatchQueue.main.async {
                completion(.success(fallbackQuad))
            }
            return
        }

        guard let observations = request.results as? [VNRectangleObservation],
              let observation = observations.first else {
            let fallbackQuad = createFallbackQuadrilateral(for: imageSize)
            DispatchQueue.main.async {
                completion(.success(fallbackQuad))
            }
            return
        }

        let quad = convertToQuadrilateral(observation: observation, imageSize: imageSize)
        DispatchQueue.main.async {
            completion(.success(quad))
        }
    }

    private func convertToQuadrilateral(observation: VNRectangleObservation, imageSize: CGSize) -> DetectedQuadrilateral {
        // Vision coordinates are normalized and origin is bottom-left
        // Convert to UIKit coordinates (origin top-left)
        let topLeft = CGPoint(
            x: observation.topLeft.x * imageSize.width,
            y: (1 - observation.topLeft.y) * imageSize.height
        )
        let topRight = CGPoint(
            x: observation.topRight.x * imageSize.width,
            y: (1 - observation.topRight.y) * imageSize.height
        )
        let bottomRight = CGPoint(
            x: observation.bottomRight.x * imageSize.width,
            y: (1 - observation.bottomRight.y) * imageSize.height
        )
        let bottomLeft = CGPoint(
            x: observation.bottomLeft.x * imageSize.width,
            y: (1 - observation.bottomLeft.y) * imageSize.height
        )

        return DetectedQuadrilateral(
            topLeft: topLeft,
            topRight: topRight,
            bottomRight: bottomRight,
            bottomLeft: bottomLeft,
            confidence: observation.confidence
        )
    }

    private func createFallbackQuadrilateral(for imageSize: CGSize) -> DetectedQuadrilateral {
        // Return full image bounds as fallback
        return DetectedQuadrilateral(
            topLeft: CGPoint(x: 0, y: 0),
            topRight: CGPoint(x: imageSize.width, y: 0),
            bottomRight: CGPoint(x: imageSize.width, y: imageSize.height),
            bottomLeft: CGPoint(x: 0, y: imageSize.height),
            confidence: 0.0
        )
    }
}
