//
//  CropViewController.swift
//  DocumentScanner
//
//  Crop adjustment view controller with edge detection and manual corner adjustment
//

import UIKit
import Vision

protocol CropViewControllerDelegate: AnyObject {
    func cropViewController(_ controller: CropViewController, didFinishWithImage image: UIImage, corners: [CGPoint])
    func cropViewControllerDidCancel(_ controller: CropViewController)
}

class CropViewController: UIViewController {

    weak var delegate: CropViewControllerDelegate?

    private let originalImage: UIImage
    private var detectedCorners: [CGPoint] = []

    // MARK: - Loupe
    private var loupeView: MagnificationLoupeView?
    private var downsampledImage: UIImage?

    // MARK: - UI Components
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 3.0
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }()

    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleToFill
        imageView.clipsToBounds = true
        imageView.isUserInteractionEnabled = true
        return imageView
    }()

    private var cropOverlayView: CropOverlayView!

    private lazy var gridButton: UIButton = {
        let button = ScannerTheme.makePillButton(title: "", style: .secondary, iconName: "grid")
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 14, bottom: 10, right: 14)
        button.accessibilityLabel = "Toggle Grid"
        button.accessibilityIdentifier = "gridButton"
        button.alpha = 0.6
        ScannerTheme.applyFrostedBackground(to: button)
        return button
    }()

    private lazy var resetButton: UIButton = {
        let button = ScannerTheme.makePillButton(title: "Reset", style: .secondary, iconName: "arrow.counterclockwise")
        ScannerTheme.applyFrostedBackground(to: button)
        return button
    }()

    private lazy var doneButton: UIButton = {
        let button = ScannerTheme.makePillButton(title: "Done", style: .primary)
        return button
    }()

    private lazy var cancelButton: UIButton = {
        let button = ScannerTheme.makePillButton(title: "Cancel", style: .secondary)
        ScannerTheme.applyFrostedBackground(to: button)
        return button
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .white
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()

    // MARK: - Initialization
    init(image: UIImage) {
        self.originalImage = image
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ScannerTheme.Colors.background
        navigationController?.setNavigationBarHidden(true, animated: false)

        setupImageView()
        setupUI()
        detectEdges()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateImageLayout()
    }

    // MARK: - Setup
    private func setupImageView() {
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        scrollView.delegate = self

        imageView.image = originalImage

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupUI() {
        view.addSubview(gridButton)
        view.addSubview(resetButton)
        view.addSubview(doneButton)
        view.addSubview(cancelButton)
        view.addSubview(activityIndicator)

        NSLayoutConstraint.activate([
            // Cancel button
            cancelButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: ScannerTheme.Spacing.screenMargin),
            cancelButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: ScannerTheme.Spacing.screenMargin),

            // Grid button (next to reset)
            gridButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: ScannerTheme.Spacing.screenMargin),
            gridButton.trailingAnchor.constraint(equalTo: resetButton.leadingAnchor, constant: -12),

            // Reset button
            resetButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: ScannerTheme.Spacing.screenMargin),
            resetButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -ScannerTheme.Spacing.screenMargin),

            // Done button
            doneButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -ScannerTheme.Spacing.screenMargin),
            doneButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            // Activity indicator
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        gridButton.addTarget(self, action: #selector(gridButtonTapped), for: .touchUpInside)
        resetButton.addTarget(self, action: #selector(resetButtonTapped), for: .touchUpInside)
        doneButton.addTarget(self, action: #selector(doneButtonTapped), for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)

        // Accessibility
        resetButton.accessibilityLabel = "Reset Crop"
        resetButton.accessibilityIdentifier = "resetButton"
        doneButton.accessibilityLabel = "Done"
        doneButton.accessibilityIdentifier = "doneButton"
        cancelButton.accessibilityLabel = "Cancel"
        cancelButton.accessibilityIdentifier = "cancelButton"
    }

    private func updateImageLayout() {
        let imageSize = originalImage.size
        guard imageSize.width > 0 && imageSize.height > 0 else { return }

        let viewSize = scrollView.bounds.size
        guard viewSize.width > 0 && viewSize.height > 0 else { return }

        // Calculate aspect fit size
        let imageAspect = imageSize.width / imageSize.height
        let viewAspect = viewSize.width / viewSize.height

        var displaySize: CGSize
        if imageAspect > viewAspect {
            // Image is wider
            displaySize = CGSize(width: viewSize.width, height: viewSize.width / imageAspect)
        } else {
            // Image is taller
            displaySize = CGSize(width: viewSize.height * imageAspect, height: viewSize.height)
        }

        imageView.frame = CGRect(origin: .zero, size: displaySize)
        scrollView.contentSize = displaySize

        // Center the image
        let offsetX = max((viewSize.width - displaySize.width) / 2, 0)
        let offsetY = max((viewSize.height - displaySize.height) / 2, 0)
        scrollView.contentInset = UIEdgeInsets(top: offsetY, left: offsetX, bottom: offsetY, right: offsetX)
    }

    private func setupCropOverlay(with corners: [CGPoint]) {
        cropOverlayView?.removeFromSuperview()

        cropOverlayView = CropOverlayView(frame: imageView.bounds, corners: corners)
        cropOverlayView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        cropOverlayView.delegate = self
        imageView.addSubview(cropOverlayView)
    }

    // MARK: - Downsampled Image for Loupe
    private func prepareDownsampledImage() {
        guard downsampledImage == nil else { return }
        let screenScale = UIScreen.main.scale
        let maxDimension = max(view.bounds.width, view.bounds.height) * screenScale
        let imageSize = originalImage.size
        let scale = min(maxDimension / imageSize.width, maxDimension / imageSize.height, 1.0)

        if scale < 1.0 {
            let newSize = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
            UIGraphicsBeginImageContextWithOptions(newSize, true, 1.0)
            originalImage.draw(in: CGRect(origin: .zero, size: newSize))
            downsampledImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
        } else {
            downsampledImage = originalImage
        }
    }

    // MARK: - Edge Detection
    private func detectEdges() {
        activityIndicator.startAnimating()
        resetButton.isEnabled = false
        doneButton.isEnabled = false

        let edgeDetectionService = EdgeDetectionService()

        edgeDetectionService.detectEdges(in: originalImage) { [weak self] result in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                self.resetButton.isEnabled = true
                self.doneButton.isEnabled = true

                switch result {
                case .success(let quadrilateral):
                    // Convert from image coordinates to normalized (0-1) coordinates
                    let imageSize = self.originalImage.size
                    self.detectedCorners = [
                        CGPoint(x: quadrilateral.topLeft.x / imageSize.width,
                                y: quadrilateral.topLeft.y / imageSize.height),
                        CGPoint(x: quadrilateral.topRight.x / imageSize.width,
                                y: quadrilateral.topRight.y / imageSize.height),
                        CGPoint(x: quadrilateral.bottomRight.x / imageSize.width,
                                y: quadrilateral.bottomRight.y / imageSize.height),
                        CGPoint(x: quadrilateral.bottomLeft.x / imageSize.width,
                                y: quadrilateral.bottomLeft.y / imageSize.height)
                    ]
                    self.setupCropOverlay(with: self.detectedCorners)

                    let announcement = quadrilateral.confidence > 0 ? "Document edges detected" : "No document edges found, showing full image"
                    UIAccessibility.post(notification: .announcement, argument: announcement)

                case .failure:
                    // Use default corners (full image)
                    self.detectedCorners = [
                        CGPoint(x: 0, y: 0),
                        CGPoint(x: 1, y: 0),
                        CGPoint(x: 1, y: 1),
                        CGPoint(x: 0, y: 1)
                    ]
                    self.setupCropOverlay(with: self.detectedCorners)
                    UIAccessibility.post(notification: .announcement, argument: "No document edges found, showing full image")
                }
            }
        }
    }

    // MARK: - Actions
    @objc private func gridButtonTapped() {
        guard let overlay = cropOverlayView else { return }
        overlay.showGrid.toggle()
        gridButton.alpha = overlay.showGrid ? 1.0 : 0.6
    }

    @objc private func resetButtonTapped() {
        // Reset to automatically detected corners
        cropOverlayView.resetToCorners(detectedCorners)
    }

    @objc private func doneButtonTapped() {
        guard let overlay = cropOverlayView else { return }

        guard overlay.isValidQuadrilateral() else {
            let alert = UIAlertController(
                title: "Invalid Selection",
                message: "The crop area is invalid. Please adjust the corners so they don't overlap.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }

        let currentCorners = overlay.getCurrentCorners()
        delegate?.cropViewController(self, didFinishWithImage: originalImage, corners: currentCorners)
    }

    @objc private func cancelButtonTapped() {
        delegate?.cropViewControllerDidCancel(self)
    }
}

// MARK: - UIScrollViewDelegate
extension CropViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        // Recenter image after zoom
        let offsetX = max((scrollView.bounds.width - scrollView.contentSize.width) / 2, 0)
        let offsetY = max((scrollView.bounds.height - scrollView.contentSize.height) / 2, 0)
        scrollView.contentInset = UIEdgeInsets(top: offsetY, left: offsetX, bottom: offsetY, right: offsetX)
    }
}

// MARK: - CropOverlayViewDelegate
extension CropViewController: CropOverlayViewDelegate {

    func cornerDragDidBegin(index: Int, normalizedPosition: CGPoint) {
        prepareDownsampledImage()

        let loupe = MagnificationLoupeView()
        view.addSubview(loupe)
        loupeView = loupe

        if let image = downsampledImage {
            loupe.update(normalizedPoint: normalizedPosition, in: image)
        }

        let viewPoint = convertNormalizedToViewPoint(normalizedPosition)
        loupe.updatePosition(for: viewPoint, in: view)
        loupe.animateIn()
    }

    func cornerDragDidMove(index: Int, normalizedPosition: CGPoint) {
        guard let loupe = loupeView, let image = downsampledImage else { return }

        loupe.update(normalizedPoint: normalizedPosition, in: image)
        let viewPoint = convertNormalizedToViewPoint(normalizedPosition)
        loupe.updatePosition(for: viewPoint, in: view)
    }

    func cornerDragDidEnd(index: Int) {
        loupeView?.animateOut { [weak self] in
            self?.loupeView?.removeFromSuperview()
            self?.loupeView = nil
        }
    }

    private func convertNormalizedToViewPoint(_ normalized: CGPoint) -> CGPoint {
        // Convert from normalized image coordinates to the view controller's coordinate space
        let pointInImage = CGPoint(
            x: normalized.x * imageView.bounds.width,
            y: normalized.y * imageView.bounds.height
        )
        return imageView.convert(pointInImage, to: view)
    }
}
