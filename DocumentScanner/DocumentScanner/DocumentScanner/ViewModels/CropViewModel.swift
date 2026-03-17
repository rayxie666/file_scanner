//
//  CropViewModel.swift
//  DocumentScanner
//
//  ViewModel for crop adjustment functionality
//

import Foundation
import Combine
import UIKit

class CropViewModel: ObservableObject {

    @Published var quadrilateral: DetectedQuadrilateral
    @Published var isProcessing = false
    @Published var showGrid = false
    @Published var errorMessage: String?

    private let originalImage: UIImage
    private let originalQuadrilateral: DetectedQuadrilateral

    init(image: UIImage, detectedQuadrilateral: DetectedQuadrilateral) {
        self.originalImage = image
        self.quadrilateral = detectedQuadrilateral
        self.originalQuadrilateral = detectedQuadrilateral
    }

    func updateCorner(at index: Int, to point: CGPoint) {
        var points = quadrilateral.points
        guard index >= 0 && index < points.count else { return }

        // Constrain point to image bounds
        let constrainedPoint = constrainPoint(point, to: originalImage.size)
        points[index] = constrainedPoint

        // Update quadrilateral with new points
        quadrilateral = DetectedQuadrilateral(
            topLeft: points[0],
            topRight: points[1],
            bottomRight: points[2],
            bottomLeft: points[3],
            confidence: quadrilateral.confidence
        )
    }

    func resetToDetected() {
        quadrilateral = originalQuadrilateral
    }

    func toggleGrid() {
        showGrid.toggle()
    }

    private func constrainPoint(_ point: CGPoint, to size: CGSize) -> CGPoint {
        let x = min(max(point.x, 0), size.width)
        let y = min(max(point.y, 0), size.height)
        return CGPoint(x: x, y: y)
    }

    func validateQuadrilateral() -> Bool {
        let points = quadrilateral.points
        guard points.count == 4 else { return false }

        // Check for self-intersection by testing opposite edges
        func cross(_ a: CGPoint, _ b: CGPoint, _ c: CGPoint) -> CGFloat {
            return (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)
        }

        func segmentsIntersect(_ p1: CGPoint, _ p2: CGPoint, _ p3: CGPoint, _ p4: CGPoint) -> Bool {
            let d1 = cross(p3, p4, p1)
            let d2 = cross(p3, p4, p2)
            let d3 = cross(p1, p2, p3)
            let d4 = cross(p1, p2, p4)
            return ((d1 > 0 && d2 < 0) || (d1 < 0 && d2 > 0)) &&
                   ((d3 > 0 && d4 < 0) || (d3 < 0 && d4 > 0))
        }

        // Edge 0-1 vs Edge 2-3, Edge 1-2 vs Edge 3-0
        if segmentsIntersect(points[0], points[1], points[2], points[3]) { return false }
        if segmentsIntersect(points[1], points[2], points[3], points[0]) { return false }

        return true
    }
}
