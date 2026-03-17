//
//  ColorModeViewController.swift
//  DocumentScanner
//
//  Color mode selection view controller with filter strip and real-time preview
//

import UIKit

protocol ColorModeViewControllerDelegate: AnyObject {
    func colorModeViewController(_ controller: ColorModeViewController, didFinishWithImage image: UIImage, colorMode: ColorMode)
    func colorModeViewControllerDidRequestRecrop(_ controller: ColorModeViewController)
    func colorModeViewControllerDidCancel(_ controller: ColorModeViewController)
}

class ColorModeViewController: UIViewController {

    weak var delegate: ColorModeViewControllerDelegate?

    private let originalImage: UIImage
    private let corners: [CGPoint]
    private var currentColorMode: ColorMode = .original
    private var processedImages: [ColorMode: UIImage] = [:]
    private let imageProcessingService = ImageProcessingService()

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
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private lazy var filterCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 72, height: 92)
        layout.minimumInteritemSpacing = 16
        layout.sectionInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.backgroundColor = .clear
        cv.showsHorizontalScrollIndicator = false
        cv.register(FilterThumbnailCell.self, forCellWithReuseIdentifier: FilterThumbnailCell.reuseIdentifier)
        cv.dataSource = self
        cv.delegate = self
        return cv
    }()

    private lazy var confirmButton: UIButton = {
        let button = ScannerTheme.makePillButton(title: "Confirm", style: .primary)
        return button
    }()

    private lazy var recropButton: UIButton = {
        let button = ScannerTheme.makePillButton(title: "Re-crop", style: .secondary, iconName: "crop.rotate")
        ScannerTheme.applyFrostedBackground(to: button)
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
    init(image: UIImage, corners: [CGPoint]) {
        self.originalImage = image
        self.corners = corners
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

        setupUI()
        processInitialImage()
    }

    // MARK: - Setup
    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        scrollView.delegate = self

        view.addSubview(filterCollectionView)
        view.addSubview(confirmButton)
        view.addSubview(recropButton)
        view.addSubview(cancelButton)
        view.addSubview(activityIndicator)

        NSLayoutConstraint.activate([
            // Cancel button
            cancelButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: ScannerTheme.Spacing.screenMargin),
            cancelButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: ScannerTheme.Spacing.screenMargin),

            // Re-crop button
            recropButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: ScannerTheme.Spacing.screenMargin),
            recropButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -ScannerTheme.Spacing.screenMargin),

            // Scroll view — full bleed behind everything
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // Image view
            imageView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            imageView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            imageView.heightAnchor.constraint(equalTo: scrollView.heightAnchor),

            // Filter strip
            filterCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            filterCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            filterCollectionView.bottomAnchor.constraint(equalTo: confirmButton.topAnchor, constant: -ScannerTheme.Spacing.medium),
            filterCollectionView.heightAnchor.constraint(equalToConstant: 100),

            // Confirm button
            confirmButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -ScannerTheme.Spacing.screenMargin),
            confirmButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            // Activity indicator
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        confirmButton.addTarget(self, action: #selector(confirmButtonTapped), for: .touchUpInside)
        recropButton.addTarget(self, action: #selector(recropButtonTapped), for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)

        // Accessibility
        confirmButton.accessibilityLabel = "Confirm"
        confirmButton.accessibilityIdentifier = "confirmButton"
        recropButton.accessibilityLabel = "Re-crop"
        recropButton.accessibilityIdentifier = "recropButton"
        cancelButton.accessibilityLabel = "Cancel"
        cancelButton.accessibilityIdentifier = "cancelButton"
        filterCollectionView.accessibilityLabel = "Color Mode Filters"
        filterCollectionView.accessibilityIdentifier = "filterCollectionView"

        // Select first item
        DispatchQueue.main.async {
            self.filterCollectionView.selectItem(
                at: IndexPath(item: 0, section: 0),
                animated: false,
                scrollPosition: []
            )
        }
    }

    // MARK: - Image Processing
    private func processInitialImage() {
        activityIndicator.startAnimating()
        setControlsEnabled(false)

        // Process image with perspective correction first
        imageProcessingService.cropAndCorrect(originalImage, corners: corners) { [weak self] result in
            guard let self = self else { return }

            DispatchQueue.main.async {
                switch result {
                case .success(let croppedImage):
                    // Store original color mode
                    self.processedImages[.original] = croppedImage
                    self.imageView.image = croppedImage

                    // Pre-process other color modes in background
                    self.preProcessColorModes(croppedImage)

                    self.activityIndicator.stopAnimating()
                    self.setControlsEnabled(true)
                    self.filterCollectionView.reloadData()

                case .failure:
                    // Perspective correction failed — fall back to original image
                    self.processedImages[.original] = self.originalImage
                    self.imageView.image = self.originalImage
                    self.activityIndicator.stopAnimating()
                    self.setControlsEnabled(true)
                    self.filterCollectionView.reloadData()
                }
            }
        }
    }

    private func preProcessColorModes(_ baseImage: UIImage) {
        // Process grayscale in background
        imageProcessingService.applyColorMode(baseImage, mode: .grayscale) { [weak self] result in
            if case .success(let grayscaleImage) = result {
                self?.processedImages[.grayscale] = grayscaleImage
                DispatchQueue.main.async {
                    self?.filterCollectionView.reloadData()
                }
            }
        }

        // Process black & white in background
        imageProcessingService.applyColorMode(baseImage, mode: .blackAndWhite) { [weak self] result in
            if case .success(let bwImage) = result {
                self?.processedImages[.blackAndWhite] = bwImage
                DispatchQueue.main.async {
                    self?.filterCollectionView.reloadData()
                }
            }
        }
    }

    private func updatePreviewForColorMode(_ colorMode: ColorMode) {
        // Check if we already have the processed image
        if let cachedImage = processedImages[colorMode] {
            imageView.image = cachedImage
            return
        }

        // If not cached, process it now
        guard let baseImage = processedImages[.original] else { return }

        activityIndicator.startAnimating()
        setControlsEnabled(false)

        imageProcessingService.applyColorMode(baseImage, mode: colorMode) { [weak self] result in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                self.setControlsEnabled(true)

                switch result {
                case .success(let processedImage):
                    self.processedImages[colorMode] = processedImage
                    self.imageView.image = processedImage

                case .failure(let error):
                    _ = error
                }
            }
        }
    }

    private func setControlsEnabled(_ enabled: Bool) {
        filterCollectionView.isUserInteractionEnabled = enabled
        confirmButton.isEnabled = enabled
        recropButton.isEnabled = enabled
    }

    // MARK: - Actions
    @objc private func confirmButtonTapped() {
        guard let finalImage = processedImages[currentColorMode] else { return }
        delegate?.colorModeViewController(self, didFinishWithImage: finalImage, colorMode: currentColorMode)
    }

    @objc private func recropButtonTapped() {
        delegate?.colorModeViewControllerDidRequestRecrop(self)
    }

    @objc private func cancelButtonTapped() {
        delegate?.colorModeViewControllerDidCancel(self)
    }

    // MARK: - Alert
    private func showErrorAlert() {
        let alert = UIAlertController(
            title: "Processing Error",
            message: "Failed to process the image. Please try again.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Retry", style: .default) { [weak self] _ in
            self?.processInitialImage()
        })

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
            guard let self = self else { return }
            self.delegate?.colorModeViewControllerDidCancel(self)
        })

        present(alert, animated: true)
    }
}

// MARK: - UIScrollViewDelegate
extension ColorModeViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
}

// MARK: - UICollectionViewDataSource
extension ColorModeViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return ColorMode.allCases.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FilterThumbnailCell.reuseIdentifier, for: indexPath) as! FilterThumbnailCell
        let mode = ColorMode.allCases[indexPath.item]
        let thumbnail = processedImages[mode]
        cell.configure(with: thumbnail, label: mode.rawValue, isSelected: mode == currentColorMode)
        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension ColorModeViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let mode = ColorMode.allCases[indexPath.item]
        currentColorMode = mode
        updatePreviewForColorMode(mode)
        collectionView.reloadData()
    }
}

// MARK: - FilterThumbnailCell

class FilterThumbnailCell: UICollectionViewCell {

    static let reuseIdentifier = "FilterThumbnailCell"

    private let thumbnailImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.backgroundColor = ScannerTheme.Colors.cardBackground
        return iv
    }()

    private let selectionRing: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.fillColor = UIColor.clear.cgColor
        layer.strokeColor = ScannerTheme.Colors.accent.cgColor
        layer.lineWidth = 3
        return layer
    }()

    private let label: UILabel = {
        let lbl = UILabel()
        lbl.font = ScannerTheme.Fonts.caption
        lbl.textColor = ScannerTheme.Colors.textPrimary
        lbl.textAlignment = .center
        lbl.adjustsFontForContentSizeCategory = true
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCell()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupCell() {
        let thumbnailSize: CGFloat = 64

        thumbnailImageView.layer.cornerRadius = thumbnailSize / 2
        contentView.addSubview(thumbnailImageView)
        contentView.addSubview(label)

        NSLayoutConstraint.activate([
            thumbnailImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            thumbnailImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            thumbnailImageView.widthAnchor.constraint(equalToConstant: thumbnailSize),
            thumbnailImageView.heightAnchor.constraint(equalToConstant: thumbnailSize),

            label.topAnchor.constraint(equalTo: thumbnailImageView.bottomAnchor, constant: 4),
            label.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])

        thumbnailImageView.layer.addSublayer(selectionRing)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let size = thumbnailImageView.bounds.size
        let ringPath = UIBezierPath(ovalIn: CGRect(origin: .zero, size: size).insetBy(dx: 1.5, dy: 1.5))
        selectionRing.path = ringPath.cgPath
        selectionRing.frame = thumbnailImageView.bounds
    }

    func configure(with image: UIImage?, label text: String, isSelected: Bool) {
        thumbnailImageView.image = image
        label.text = text
        selectionRing.isHidden = !isSelected
        label.textColor = isSelected ? ScannerTheme.Colors.accent : ScannerTheme.Colors.textPrimary
    }
}
