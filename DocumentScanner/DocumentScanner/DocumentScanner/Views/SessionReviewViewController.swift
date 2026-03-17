//
//  SessionReviewViewController.swift
//  DocumentScanner
//
//  Session review with grid view for reordering, deleting, and saving pages
//

import UIKit

protocol SessionReviewViewControllerDelegate: AnyObject {
    func sessionReviewDidRequestAddPage(_ controller: SessionReviewViewController)
    func sessionReviewDidRequestSavePDF(_ controller: SessionReviewViewController, filename: String)
    func sessionReviewDidRequestEditPage(_ controller: SessionReviewViewController, at index: Int)
    func sessionReviewDidCancel(_ controller: SessionReviewViewController)
}

class SessionReviewViewController: UIViewController {

    weak var delegate: SessionReviewViewControllerDelegate?

    private let sessionViewModel = SessionViewModel()

    // MARK: - UI Components
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)

        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.register(PageThumbnailCell.self, forCellWithReuseIdentifier: PageThumbnailCell.reuseIdentifier)
        cv.delegate = self
        cv.dataSource = self
        cv.dragDelegate = self
        cv.dropDelegate = self
        cv.dragInteractionEnabled = true
        return cv
    }()

    private let pageCountLabel: UILabel = {
        let label = UILabel()
        label.font = ScannerTheme.Fonts.body
        label.textColor = ScannerTheme.Colors.textSecondary
        label.textAlignment = .center
        label.adjustsFontForContentSizeCategory = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // Floating action bar
    private lazy var floatingBar: UIVisualEffectView = {
        let bar = ScannerTheme.makeFrostedToolbar()
        return bar
    }()

    private lazy var addPageButton: UIButton = {
        let button = ScannerTheme.makePillButton(title: "Add Page", style: .secondary, iconName: "plus.circle.fill")
        ScannerTheme.applyFrostedBackground(to: button)
        return button
    }()

    private lazy var savePDFButton: UIButton = {
        let button = ScannerTheme.makePillButton(title: "Save as PDF", style: .primary)
        return button
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .white
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()

    private let progressView: UIProgressView = {
        let pv = UIProgressView(progressViewStyle: .default)
        pv.translatesAutoresizingMaskIntoConstraints = false
        pv.progressTintColor = ScannerTheme.Colors.accent
        pv.trackTintColor = UIColor.white.withAlphaComponent(0.2)
        pv.isHidden = true
        pv.accessibilityIdentifier = "savingProgressView"
        return pv
    }()

    private let progressLabel: UILabel = {
        let label = UILabel()
        label.font = ScannerTheme.Fonts.caption
        label.adjustsFontForContentSizeCategory = true
        label.textColor = ScannerTheme.Colors.textSecondary
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        return label
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ScannerTheme.Colors.background
        navigationController?.setNavigationBarHidden(true, animated: false)
        setupUI()
        updatePageCount()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        sessionViewModel.loadSession()
        collectionView.reloadData()
        updatePageCount()
    }

    // MARK: - Setup
    private func setupUI() {
        // Cancel button (floating top-left)
        let cancelButton = ScannerTheme.makePillButton(title: "Cancel", style: .secondary)
        ScannerTheme.applyFrostedBackground(to: cancelButton)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        cancelButton.accessibilityLabel = "Cancel"

        view.addSubview(collectionView)
        view.addSubview(pageCountLabel)
        view.addSubview(progressView)
        view.addSubview(progressLabel)
        view.addSubview(cancelButton)
        view.addSubview(activityIndicator)

        // Floating bottom bar
        view.addSubview(floatingBar)
        floatingBar.contentView.addSubview(addPageButton)
        floatingBar.contentView.addSubview(savePDFButton)

        NSLayoutConstraint.activate([
            // Cancel
            cancelButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: ScannerTheme.Spacing.screenMargin),
            cancelButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: ScannerTheme.Spacing.screenMargin),

            // Page count
            pageCountLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: ScannerTheme.Spacing.screenMargin + 8),
            pageCountLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            // Collection view
            collectionView.topAnchor.constraint(equalTo: pageCountLabel.bottomAnchor, constant: ScannerTheme.Spacing.medium),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: floatingBar.topAnchor, constant: -ScannerTheme.Spacing.small),

            // Floating bar
            floatingBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: ScannerTheme.Spacing.medium),
            floatingBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -ScannerTheme.Spacing.medium),
            floatingBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -ScannerTheme.Spacing.medium),

            // Buttons inside floating bar
            addPageButton.topAnchor.constraint(equalTo: floatingBar.contentView.topAnchor, constant: 12),
            addPageButton.leadingAnchor.constraint(equalTo: floatingBar.contentView.leadingAnchor, constant: 16),
            addPageButton.bottomAnchor.constraint(equalTo: floatingBar.contentView.bottomAnchor, constant: -12),

            savePDFButton.topAnchor.constraint(equalTo: floatingBar.contentView.topAnchor, constant: 12),
            savePDFButton.trailingAnchor.constraint(equalTo: floatingBar.contentView.trailingAnchor, constant: -16),
            savePDFButton.bottomAnchor.constraint(equalTo: floatingBar.contentView.bottomAnchor, constant: -12),

            // Progress
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            progressView.bottomAnchor.constraint(equalTo: floatingBar.topAnchor, constant: -12),

            progressLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            progressLabel.bottomAnchor.constraint(equalTo: progressView.topAnchor, constant: -4),

            // Activity indicator
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        addPageButton.addTarget(self, action: #selector(addPageTapped), for: .touchUpInside)
        savePDFButton.addTarget(self, action: #selector(savePDFTapped), for: .touchUpInside)

        // Accessibility
        addPageButton.accessibilityLabel = "Add Page"
        addPageButton.accessibilityIdentifier = "addPageButton"
        savePDFButton.accessibilityLabel = "Save as PDF"
        savePDFButton.accessibilityIdentifier = "savePDFButton"
        collectionView.accessibilityIdentifier = "pageCollectionView"
    }

    private func updatePageCount() {
        let count = sessionViewModel.pages.count
        pageCountLabel.text = "\(count) page\(count == 1 ? "" : "s")"
        savePDFButton.isEnabled = count > 0
        savePDFButton.alpha = count > 0 ? 1.0 : 0.5
    }

    // MARK: - Actions
    @objc private func addPageTapped() {
        delegate?.sessionReviewDidRequestAddPage(self)
    }

    @objc private func savePDFTapped() {
        showFilenameInput()
    }

    @objc private func cancelTapped() {
        let alert = UIAlertController(
            title: "Discard Session?",
            message: "All scanned pages will be lost.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Discard", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            self.sessionViewModel.clearSession()
            self.delegate?.sessionReviewDidCancel(self)
        })
        alert.addAction(UIAlertAction(title: "Keep Editing", style: .cancel))
        present(alert, animated: true)
    }

    private func showFilenameInput() {
        let storageService = DocumentStorageService()
        let defaultName = storageService.generateDefaultFilename()
        let nameWithoutExt = (defaultName as NSString).deletingPathExtension

        let alert = UIAlertController(
            title: "Save PDF",
            message: "Enter a filename for your document.\nSaved as: \(nameWithoutExt).pdf",
            preferredStyle: .alert
        )

        var textObserver: NSObjectProtocol?

        alert.addTextField { textField in
            textField.text = nameWithoutExt
            textField.placeholder = "Document name"
            textField.clearButtonMode = .whileEditing

            textObserver = NotificationCenter.default.addObserver(
                forName: UITextField.textDidChangeNotification,
                object: textField,
                queue: .main
            ) { _ in
                let raw = textField.text ?? ""
                let invalidCharacters = CharacterSet(charactersIn: "/:\\?*|\"<>")
                let sanitized = raw.components(separatedBy: invalidCharacters).joined(separator: "_")
                    .trimmingCharacters(in: .whitespaces)
                let displayName = sanitized.isEmpty ? nameWithoutExt : sanitized
                alert.message = "Enter a filename for your document.\nSaved as: \(displayName).pdf"
            }
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            if let observer = textObserver {
                NotificationCenter.default.removeObserver(observer)
            }
        })
        alert.addAction(UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            if let observer = textObserver {
                NotificationCenter.default.removeObserver(observer)
            }
            guard let self = self else { return }
            let filename = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespaces) ?? nameWithoutExt
            let finalName = filename.isEmpty ? nameWithoutExt : filename

            self.activityIndicator.startAnimating()
            self.savePDFButton.isEnabled = false

            self.delegate?.sessionReviewDidRequestSavePDF(self, filename: finalName)
        })

        present(alert, animated: true)
    }

    func finishedSaving() {
        activityIndicator.stopAnimating()
        savePDFButton.isEnabled = true
        progressView.isHidden = true
        progressLabel.isHidden = true
        progressView.setProgress(0, animated: false)
    }

    func updateSavingProgress(_ progress: Float, message: String? = nil) {
        progressView.isHidden = false
        progressLabel.isHidden = false
        progressView.setProgress(progress, animated: true)
        progressLabel.text = message ?? "Saving..."
    }

    // MARK: - Page Management
    func addPage(_ page: ScannedPage) {
        sessionViewModel.addPage(page)
        collectionView.reloadData()
        updatePageCount()
    }

    private func deletePage(at index: Int) {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
        sessionViewModel.removePage(at: index)
        collectionView.performBatchUpdates {
            collectionView.deleteItems(at: [IndexPath(item: index, section: 0)])
        } completion: { _ in
            self.collectionView.reloadData()
            self.updatePageCount()
        }
    }
}

// MARK: - UICollectionViewDataSource
extension SessionReviewViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return sessionViewModel.pages.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PageThumbnailCell.reuseIdentifier, for: indexPath) as? PageThumbnailCell else {
            return UICollectionViewCell()
        }
        let page = sessionViewModel.pages[indexPath.item]
        cell.configure(with: page)
        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension SessionReviewViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.sessionReviewDidRequestEditPage(self, at: indexPath.item)
    }

    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            let delete = UIAction(title: "Delete", image: UIImage(systemName: "trash"), attributes: .destructive) { [weak self] _ in
                self?.deletePage(at: indexPath.item)
            }
            return UIMenu(children: [delete])
        }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension SessionReviewViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let padding: CGFloat = 16 * 2 + 12
        let width = (collectionView.bounds.width - padding) / 2
        return CGSize(width: width, height: width * 1.4)
    }
}

// MARK: - UICollectionViewDragDelegate
extension SessionReviewViewController: UICollectionViewDragDelegate {
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        let item = UIDragItem(itemProvider: NSItemProvider())
        item.localObject = indexPath
        return [item]
    }
}

// MARK: - UICollectionViewDropDelegate
extension SessionReviewViewController: UICollectionViewDropDelegate {
    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
    }

    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        guard let destinationIndexPath = coordinator.destinationIndexPath,
              let item = coordinator.items.first,
              let sourceIndexPath = item.sourceIndexPath else { return }

        collectionView.performBatchUpdates {
            sessionViewModel.movePage(from: sourceIndexPath.item, to: destinationIndexPath.item)
            collectionView.moveItem(at: sourceIndexPath, to: destinationIndexPath)
        } completion: { _ in
            self.collectionView.reloadData()
        }

        coordinator.drop(item.dragItem, toItemAt: destinationIndexPath)
    }
}

// MARK: - Page Thumbnail Cell
class PageThumbnailCell: UICollectionViewCell {

    static let reuseIdentifier = "PageThumbnailCell"

    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = ScannerTheme.Corner.card
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let pageNumberLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .bold)
        label.textColor = ScannerTheme.Colors.textPrimary
        label.backgroundColor = ScannerTheme.Colors.overlayDark
        label.textAlignment = .center
        label.layer.cornerRadius = 12
        label.layer.masksToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCell()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupCell() {
        contentView.addSubview(imageView)
        contentView.addSubview(pageNumberLabel)

        contentView.layer.cornerRadius = ScannerTheme.Corner.card
        contentView.backgroundColor = ScannerTheme.Colors.cardBackground

        // Card shadow
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.3
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 6
        layer.masksToBounds = false

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            pageNumberLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            pageNumberLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            pageNumberLabel.widthAnchor.constraint(equalToConstant: 24),
            pageNumberLabel.heightAnchor.constraint(equalToConstant: 24)
        ])
    }

    private var currentCacheKey: String?

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        currentCacheKey = nil
    }

    func configure(with page: ScannedPage) {
        pageNumberLabel.text = "\(page.pageNumber)"

        isAccessibilityElement = true
        accessibilityLabel = "Page \(page.pageNumber)"
        accessibilityHint = "Double tap to edit. Use drag to reorder."

        // Use thumbnail service for downsampled preview
        let cacheKey = "page_\(page.pageNumber)_\(page.croppedImage.hash)"
        currentCacheKey = cacheKey
        let targetSize = CGSize(width: contentView.bounds.width * UIScreen.main.scale,
                                height: contentView.bounds.height * UIScreen.main.scale)

        imageView.backgroundColor = ScannerTheme.Colors.cardBackground
        ThumbnailService.shared.generateThumbnail(for: page.croppedImage, targetSize: targetSize, cacheKey: cacheKey) { [weak self] thumbnail in
            guard self?.currentCacheKey == cacheKey else { return }
            self?.imageView.image = thumbnail ?? page.croppedImage
        }
    }
}
