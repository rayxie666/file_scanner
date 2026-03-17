//
//  MagnificationLoupeView.swift
//  DocumentScanner
//
//  Circular magnification loupe for precise crop corner placement
//

import UIKit

class MagnificationLoupeView: UIView {

    private static let diameter: CGFloat = 120
    private static let magnification: CGFloat = 4.0
    private static let verticalOffset: CGFloat = 80
    private static let topEdgeThreshold: CGFloat = 120

    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()

    private let crosshairVertical = CAShapeLayer()
    private let crosshairHorizontal = CAShapeLayer()
    private let borderLayer = CAShapeLayer()

    override init(frame: CGRect) {
        let size = CGSize(width: Self.diameter, height: Self.diameter)
        super.init(frame: CGRect(origin: .zero, size: size))
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        let radius = Self.diameter / 2

        // Clip to circle
        layer.cornerRadius = radius
        clipsToBounds = true
        backgroundColor = .black

        // Image view fills the loupe
        imageView.frame = bounds
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(imageView)

        // Border
        borderLayer.fillColor = UIColor.clear.cgColor
        borderLayer.strokeColor = UIColor.white.cgColor
        borderLayer.lineWidth = 2
        let borderPath = UIBezierPath(ovalIn: bounds.insetBy(dx: 1, dy: 1))
        borderLayer.path = borderPath.cgPath
        layer.addSublayer(borderLayer)

        // Crosshair - vertical line
        let crossColor = UIColor.white.withAlphaComponent(0.7).cgColor
        let vPath = UIBezierPath()
        vPath.move(to: CGPoint(x: radius, y: 0))
        vPath.addLine(to: CGPoint(x: radius, y: Self.diameter))
        crosshairVertical.path = vPath.cgPath
        crosshairVertical.strokeColor = crossColor
        crosshairVertical.lineWidth = 1
        layer.addSublayer(crosshairVertical)

        // Crosshair - horizontal line
        let hPath = UIBezierPath()
        hPath.move(to: CGPoint(x: 0, y: radius))
        hPath.addLine(to: CGPoint(x: Self.diameter, y: radius))
        crosshairHorizontal.path = hPath.cgPath
        crosshairHorizontal.strokeColor = crossColor
        crosshairHorizontal.lineWidth = 1
        layer.addSublayer(crosshairHorizontal)
    }

    // MARK: - Public API

    func update(normalizedPoint: CGPoint, in image: UIImage) {
        guard let cgImage = image.cgImage else { return }

        let imgW = CGFloat(cgImage.width)
        let imgH = CGFloat(cgImage.height)

        // Region size in image pixels for 4x magnification
        let regionW = (Self.diameter / Self.magnification) * image.scale
        let regionH = regionW

        // Center the crop region on the normalized point
        let centerX = normalizedPoint.x * imgW
        let centerY = normalizedPoint.y * imgH

        var cropRect = CGRect(
            x: centerX - regionW / 2,
            y: centerY - regionH / 2,
            width: regionW,
            height: regionH
        )

        // Clamp to image bounds
        cropRect.origin.x = max(0, min(cropRect.origin.x, imgW - cropRect.width))
        cropRect.origin.y = max(0, min(cropRect.origin.y, imgH - cropRect.height))
        cropRect.size.width = min(cropRect.width, imgW)
        cropRect.size.height = min(cropRect.height, imgH)

        if let cropped = cgImage.cropping(to: cropRect) {
            imageView.image = UIImage(cgImage: cropped)
        }
    }

    func updatePosition(for viewPoint: CGPoint, in parentView: UIView) {
        let safeTop = parentView.safeAreaInsets.top
        let aboveY = viewPoint.y - Self.verticalOffset - Self.diameter / 2

        if aboveY - safeTop < Self.topEdgeThreshold {
            // Flip below
            center = CGPoint(x: viewPoint.x, y: viewPoint.y + Self.verticalOffset + Self.diameter / 2)
        } else {
            center = CGPoint(x: viewPoint.x, y: aboveY)
        }

        // Keep horizontally within parent bounds
        let halfW = Self.diameter / 2
        let minX = halfW + 8
        let maxX = parentView.bounds.width - halfW - 8
        center.x = max(minX, min(center.x, maxX))
    }

    // MARK: - Animations

    func animateIn() {
        alpha = 0
        transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        UIView.animate(
            withDuration: ScannerTheme.Animation.quickDuration,
            delay: 0,
            usingSpringWithDamping: ScannerTheme.Animation.springDamping,
            initialSpringVelocity: ScannerTheme.Animation.springVelocity,
            options: .curveEaseOut
        ) {
            self.alpha = 1
            self.transform = .identity
        }
    }

    func animateOut(completion: @escaping () -> Void) {
        UIView.animate(
            withDuration: ScannerTheme.Animation.quickDuration,
            animations: {
                self.alpha = 0
                self.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
            },
            completion: { _ in completion() }
        )
    }
}
