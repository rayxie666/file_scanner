//
//  CropOverlayView.swift
//  DocumentScanner
//
//  Overlay view with draggable corner handles for crop adjustment
//

import UIKit

protocol CropOverlayViewDelegate: AnyObject {
    func cornerDragDidBegin(index: Int, normalizedPosition: CGPoint)
    func cornerDragDidMove(index: Int, normalizedPosition: CGPoint)
    func cornerDragDidEnd(index: Int)
}

class CropOverlayView: UIView {

    weak var delegate: CropOverlayViewDelegate?

    private var corners: [CGPoint]
    private var cornerHandles: [CornerHandleView] = []
    private let shapeLayer = CAShapeLayer()
    private let maskLayer = CAShapeLayer()
    private let gridLayer = CAShapeLayer()
    var showGrid = false {
        didSet { gridLayer.isHidden = !showGrid; if showGrid { updateGrid() } }
    }

    // MARK: - Initialization
    init(frame: CGRect, corners: [CGPoint]) {
        self.corners = corners
        super.init(frame: frame)
        setupLayers()
        setupCornerHandles()
        updatePath()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateCornerHandlePositions()
        updatePath()
    }

    // MARK: - Setup
    private func setupLayers() {
        backgroundColor = .clear

        // Shape layer for the quadrilateral border
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.strokeColor = UIColor.systemBlue.cgColor
        shapeLayer.lineWidth = 2
        layer.addSublayer(shapeLayer)

        // Mask layer for shaded area outside crop
        maskLayer.fillRule = .evenOdd
        maskLayer.fillColor = UIColor.black.withAlphaComponent(0.5).cgColor
        layer.addSublayer(maskLayer)

        // Grid layer for perspective grid overlay
        gridLayer.fillColor = UIColor.clear.cgColor
        gridLayer.strokeColor = UIColor.white.withAlphaComponent(0.4).cgColor
        gridLayer.lineWidth = 0.5
        gridLayer.isHidden = true
        layer.addSublayer(gridLayer)
    }

    private func setupCornerHandles() {
        let cornerNames = ["Top Left Corner", "Top Right Corner", "Bottom Right Corner", "Bottom Left Corner"]
        for i in 0..<4 {
            let handle = CornerHandleView()
            handle.tag = i
            handle.isAccessibilityElement = true
            handle.accessibilityLabel = cornerNames[i]
            handle.accessibilityHint = "Drag to adjust crop corner"
            addSubview(handle)
            cornerHandles.append(handle)

            let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
            handle.addGestureRecognizer(panGesture)
        }
    }

    // MARK: - Public Methods
    func getCurrentCorners() -> [CGPoint] {
        return corners
    }

    func resetToCorners(_ newCorners: [CGPoint]) {
        corners = newCorners
        updateCornerHandlePositions()
        updatePath()

        // Animate reset
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: .curveEaseOut) {
            self.layoutIfNeeded()
        }
    }

    // MARK: - Corner Handle Management
    private func updateCornerHandlePositions() {
        for (index, handle) in cornerHandles.enumerated() {
            if index < corners.count {
                let normalizedPoint = corners[index]
                let actualPoint = CGPoint(
                    x: normalizedPoint.x * bounds.width,
                    y: normalizedPoint.y * bounds.height
                )
                handle.center = actualPoint
            }
        }
    }

    private func updatePath() {
        guard corners.count == 4 else { return }

        // Convert normalized coordinates to actual points
        let actualCorners = corners.map { corner in
            CGPoint(
                x: corner.x * bounds.width,
                y: corner.y * bounds.height
            )
        }

        // Create quadrilateral path
        let path = UIBezierPath()
        path.move(to: actualCorners[0])
        for i in 1..<4 {
            path.addLine(to: actualCorners[i])
        }
        path.close()

        shapeLayer.path = path.cgPath

        // Create mask path (full view minus quadrilateral)
        let maskPath = UIBezierPath(rect: bounds)
        maskPath.append(path)
        maskLayer.path = maskPath.cgPath

        if showGrid { updateGrid() }
    }

    private func updateGrid() {
        guard corners.count == 4 else { return }

        let c = corners.map { CGPoint(x: $0.x * bounds.width, y: $0.y * bounds.height) }
        let gridPath = UIBezierPath()

        // Draw 3x3 grid lines (2 horizontal + 2 vertical)
        for i in 1...2 {
            let t = CGFloat(i) / 3.0
            // Horizontal line: interpolate left edge and right edge
            let leftPt = CGPoint(x: c[0].x + (c[3].x - c[0].x) * t, y: c[0].y + (c[3].y - c[0].y) * t)
            let rightPt = CGPoint(x: c[1].x + (c[2].x - c[1].x) * t, y: c[1].y + (c[2].y - c[1].y) * t)
            gridPath.move(to: leftPt)
            gridPath.addLine(to: rightPt)

            // Vertical line: interpolate top edge and bottom edge
            let topPt = CGPoint(x: c[0].x + (c[1].x - c[0].x) * t, y: c[0].y + (c[1].y - c[0].y) * t)
            let bottomPt = CGPoint(x: c[3].x + (c[2].x - c[3].x) * t, y: c[3].y + (c[2].y - c[3].y) * t)
            gridPath.move(to: topPt)
            gridPath.addLine(to: bottomPt)
        }

        gridLayer.path = gridPath.cgPath
    }

    private let dragHaptic = UIImpactFeedbackGenerator(style: .light)

    // MARK: - Gesture Handling
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let handle = gesture.view as? CornerHandleView else { return }
        let index = handle.tag

        switch gesture.state {
        case .began:
            handle.setHighlighted(true)
            dragHaptic.impactOccurred()
            delegate?.cornerDragDidBegin(index: index, normalizedPosition: corners[index])

        case .changed:
            let translation = gesture.translation(in: self)
            let newCenter = CGPoint(
                x: handle.center.x + translation.x,
                y: handle.center.y + translation.y
            )

            // Constrain to bounds
            let constrainedCenter = constrainPoint(newCenter)
            handle.center = constrainedCenter

            // Update corner in normalized coordinates
            corners[index] = CGPoint(
                x: constrainedCenter.x / bounds.width,
                y: constrainedCenter.y / bounds.height
            )

            updatePath()
            gesture.setTranslation(.zero, in: self)
            delegate?.cornerDragDidMove(index: index, normalizedPosition: corners[index])

        case .ended, .cancelled:
            handle.setHighlighted(false)
            delegate?.cornerDragDidEnd(index: index)

        default:
            break
        }
    }

    private func constrainPoint(_ point: CGPoint) -> CGPoint {
        let handleSize: CGFloat = 44
        let margin = handleSize / 2

        return CGPoint(
            x: max(margin, min(point.x, bounds.width - margin)),
            y: max(margin, min(point.y, bounds.height - margin))
        )
    }

    // MARK: - Quadrilateral Validation
    func isValidQuadrilateral() -> Bool {
        guard corners.count == 4 else { return false }

        let actualCorners = corners.map { corner in
            CGPoint(x: corner.x * bounds.width, y: corner.y * bounds.height)
        }

        // Check for self-intersection by testing each pair of non-adjacent edges
        let edges = [
            (actualCorners[0], actualCorners[1]),
            (actualCorners[1], actualCorners[2]),
            (actualCorners[2], actualCorners[3]),
            (actualCorners[3], actualCorners[0])
        ]

        // Check edge 0 vs edge 2 (opposite sides)
        if segmentsIntersect(edges[0].0, edges[0].1, edges[2].0, edges[2].1) {
            return false
        }
        // Check edge 1 vs edge 3 (opposite sides)
        if segmentsIntersect(edges[1].0, edges[1].1, edges[3].0, edges[3].1) {
            return false
        }

        return true
    }

    private func segmentsIntersect(_ p1: CGPoint, _ p2: CGPoint, _ p3: CGPoint, _ p4: CGPoint) -> Bool {
        let d1 = crossProduct(p3, p4, p1)
        let d2 = crossProduct(p3, p4, p2)
        let d3 = crossProduct(p1, p2, p3)
        let d4 = crossProduct(p1, p2, p4)

        if ((d1 > 0 && d2 < 0) || (d1 < 0 && d2 > 0)) &&
           ((d3 > 0 && d4 < 0) || (d3 < 0 && d4 > 0)) {
            return true
        }
        return false
    }

    private func crossProduct(_ a: CGPoint, _ b: CGPoint, _ c: CGPoint) -> CGFloat {
        return (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)
    }
}

// MARK: - Corner Handle View
class CornerHandleView: UIView {

    private let outerCircle = CAShapeLayer()
    private let innerCircle = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        backgroundColor = .clear

        // Outer circle (white border)
        outerCircle.fillColor = ScannerTheme.Colors.textPrimary.cgColor
        outerCircle.strokeColor = ScannerTheme.Colors.accent.cgColor
        outerCircle.lineWidth = 2
        layer.addSublayer(outerCircle)

        // Inner circle (accent fill)
        innerCircle.fillColor = ScannerTheme.Colors.accent.cgColor
        layer.addSublayer(innerCircle)

        updateCircles()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateCircles()
    }

    private func updateCircles() {
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let outerRadius: CGFloat = 8
        let innerRadius: CGFloat = 4

        let outerPath = UIBezierPath(
            arcCenter: center,
            radius: outerRadius,
            startAngle: 0,
            endAngle: .pi * 2,
            clockwise: true
        )
        outerCircle.path = outerPath.cgPath

        let innerPath = UIBezierPath(
            arcCenter: center,
            radius: innerRadius,
            startAngle: 0,
            endAngle: .pi * 2,
            clockwise: true
        )
        innerCircle.path = innerPath.cgPath
    }

    func setHighlighted(_ highlighted: Bool) {
        UIView.animate(withDuration: ScannerTheme.Animation.quickDuration) {
            self.transform = highlighted ? CGAffineTransform(scaleX: 1.3, y: 1.3) : .identity
            self.outerCircle.strokeColor = highlighted ? ScannerTheme.Colors.handleHighlight.cgColor : ScannerTheme.Colors.accent.cgColor
            self.innerCircle.fillColor = highlighted ? ScannerTheme.Colors.handleHighlight.cgColor : ScannerTheme.Colors.accent.cgColor
        }
    }
}
