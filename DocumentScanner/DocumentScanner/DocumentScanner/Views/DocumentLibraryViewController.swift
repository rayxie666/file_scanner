//
//  DocumentLibraryViewController.swift
//  DocumentScanner
//
//  Main screen showing saved PDF documents
//

import UIKit

protocol DocumentLibraryViewControllerDelegate: AnyObject {
    func documentLibraryDidRequestScan(_ controller: DocumentLibraryViewController)
    func documentLibraryDidRequestUpload(_ controller: DocumentLibraryViewController)
    func documentLibrary(_ controller: DocumentLibraryViewController, didSelectDocument metadata: DocumentMetadata)
}

class DocumentLibraryViewController: UIViewController {

    weak var delegate: DocumentLibraryViewControllerDelegate?

    private let viewModel = DocumentLibraryViewModel()

    // MARK: - UI Components
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewCompositionalLayout { _, environment in
            let itemWidth = (environment.container.effectiveContentSize.width - 48) / 2
            let itemHeight = itemWidth * 1.5

            let itemSize = NSCollectionLayoutSize(widthDimension: .absolute(itemWidth), heightDimension: .absolute(itemHeight))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)

            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(itemHeight))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item, item])
            group.interItemSpacing = .fixed(16)

            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = 16
            section.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 100, trailing: 16)
            return section
        }

        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.register(DocumentCardCell.self, forCellWithReuseIdentifier: DocumentCardCell.reuseIdentifier)
        cv.delegate = self
        cv.dataSource = self
        return cv
    }()

    private let emptyStateView: UIView = {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.isHidden = true

        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false

        let iconConfig = UIImage.SymbolConfiguration(pointSize: 48, weight: .light)
        let iconView = UIImageView(image: UIImage(systemName: "doc.text.magnifyingglass", withConfiguration: iconConfig))
        iconView.tintColor = ScannerTheme.Colors.textSecondary

        let titleLabel = UILabel()
        titleLabel.text = "No Documents"
        titleLabel.font = ScannerTheme.Fonts.headline
        titleLabel.textColor = ScannerTheme.Colors.textPrimary

        let subtitleLabel = UILabel()
        subtitleLabel.text = "Tap the button below to scan your first document."
        subtitleLabel.font = ScannerTheme.Fonts.body
        subtitleLabel.textColor = ScannerTheme.Colors.textSecondary
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0

        stack.addArrangedSubview(iconView)
        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(subtitleLabel)
        container.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor, constant: 40),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -40)
        ])

        return container
    }()

    private var isEditMode = false
    private var selectedIndices = Set<Int>()

    private let deleteSelectedButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Delete Selected", for: .normal)
        button.titleLabel?.font = ScannerTheme.Fonts.button
        button.tintColor = .white
        button.backgroundColor = .systemRed
        button.layer.cornerRadius = 20
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isHidden = true
        button.accessibilityLabel = "Delete Selected"
        button.accessibilityIdentifier = "deleteSelectedButton"
        return button
    }()

    private let storageLabel: UILabel = {
        let label = UILabel()
        label.font = ScannerTheme.Fonts.caption
        label.textColor = ScannerTheme.Colors.textSecondary
        label.textAlignment = .center
        label.adjustsFontForContentSizeCategory = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // FABs
    private lazy var uploadFAB: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .semibold)
        button.setImage(UIImage(systemName: "square.and.arrow.down", withConfiguration: config), for: .normal)
        button.tintColor = ScannerTheme.Colors.textPrimary
        button.backgroundColor = ScannerTheme.Colors.accent
        button.layer.cornerRadius = 28
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.4
        button.layer.shadowOffset = CGSize(width: 0, height: 4)
        button.layer.shadowRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        button.accessibilityLabel = "Upload Document"
        button.accessibilityIdentifier = "uploadFAB"
        return button
    }()

    private lazy var scanFAB: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .semibold)
        button.setImage(UIImage(systemName: "camera.fill", withConfiguration: config), for: .normal)
        button.tintColor = ScannerTheme.Colors.textPrimary
        button.backgroundColor = ScannerTheme.Colors.accent
        button.layer.cornerRadius = 28
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.4
        button.layer.shadowOffset = CGSize(width: 0, height: 4)
        button.layer.shadowRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        button.accessibilityLabel = "Scan Document"
        button.accessibilityIdentifier = "scanFAB"
        return button
    }()

    // Sort button (floating top-right)
    private lazy var sortButton: UIButton = {
        let button = ScannerTheme.makePillButton(title: "", style: .secondary, iconName: "arrow.up.arrow.down")
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 14, bottom: 10, right: 14)
        ScannerTheme.applyFrostedBackground(to: button)
        button.accessibilityLabel = "Sort Documents"
        button.accessibilityIdentifier = "sortButton"
        return button
    }()

    private lazy var editButton: UIButton = {
        let button = ScannerTheme.makePillButton(title: "Select", style: .secondary)
        ScannerTheme.applyFrostedBackground(to: button)
        button.accessibilityLabel = "Select Documents"
        button.accessibilityIdentifier = "editButton"
        return button
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ScannerTheme.Colors.background
        navigationController?.setNavigationBarHidden(true, animated: false)
        setupUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        refreshData()
    }

    // MARK: - Setup
    private func setupUI() {
        view.addSubview(collectionView)
        view.addSubview(emptyStateView)
        view.addSubview(deleteSelectedButton)
        view.addSubview(storageLabel)
        view.addSubview(uploadFAB)
        view.addSubview(scanFAB)
        view.addSubview(sortButton)
        view.addSubview(editButton)

        NSLayoutConstraint.activate([
            // Sort button
            sortButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: ScannerTheme.Spacing.screenMargin),
            sortButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: ScannerTheme.Spacing.screenMargin),

            // Edit button
            editButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: ScannerTheme.Spacing.screenMargin),
            editButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -ScannerTheme.Spacing.screenMargin),

            // Collection view
            collectionView.topAnchor.constraint(equalTo: sortButton.bottomAnchor, constant: ScannerTheme.Spacing.medium),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // Empty state
            emptyStateView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emptyStateView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // Delete selected
            deleteSelectedButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            deleteSelectedButton.bottomAnchor.constraint(equalTo: storageLabel.topAnchor, constant: -8),

            // Storage label
            storageLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            storageLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            storageLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -4),

            // FABs
            scanFAB.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -ScannerTheme.Spacing.screenMargin),
            scanFAB.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -ScannerTheme.Spacing.screenMargin),
            scanFAB.widthAnchor.constraint(equalToConstant: 56),
            scanFAB.heightAnchor.constraint(equalToConstant: 56),

            uploadFAB.trailingAnchor.constraint(equalTo: scanFAB.leadingAnchor, constant: -16),
            uploadFAB.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -ScannerTheme.Spacing.screenMargin),
            uploadFAB.widthAnchor.constraint(equalToConstant: 56),
            uploadFAB.heightAnchor.constraint(equalToConstant: 56)
        ])

        scanFAB.addTarget(self, action: #selector(scanTapped), for: .touchUpInside)
        uploadFAB.addTarget(self, action: #selector(uploadTapped), for: .touchUpInside)
        sortButton.addTarget(self, action: #selector(sortTapped), for: .touchUpInside)
        editButton.addTarget(self, action: #selector(editModeTapped), for: .touchUpInside)
        deleteSelectedButton.addTarget(self, action: #selector(deleteSelectedTapped), for: .touchUpInside)

        collectionView.accessibilityIdentifier = "documentList"
    }

    // MARK: - Data
    func refreshData() {
        viewModel.loadDocuments()
        viewModel.updateStorageInfo()
        collectionView.reloadData()
        updateEmptyState()
        updateStorageLabel()
    }

    private func updateEmptyState() {
        let isEmpty = viewModel.documents.isEmpty
        emptyStateView.isHidden = !isEmpty
        collectionView.isHidden = isEmpty
    }

    private func updateStorageLabel() {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        let used = formatter.string(fromByteCount: viewModel.storageUsed)
        let available = formatter.string(fromByteCount: viewModel.storageAvailable)

        if viewModel.isLowStorage() {
            storageLabel.text = "Storage: \(used) used - Low storage (\(available) available)"
            storageLabel.textColor = .systemOrange
        } else {
            storageLabel.text = "Storage: \(used) used / \(available) available"
            storageLabel.textColor = ScannerTheme.Colors.textSecondary
        }
    }

    // MARK: - Actions
    @objc private func scanTapped() {
        delegate?.documentLibraryDidRequestScan(self)
    }

    @objc private func uploadTapped() {
        delegate?.documentLibraryDidRequestUpload(self)
    }

    @objc private func editModeTapped() {
        isEditMode.toggle()
        selectedIndices.removeAll()

        editButton.setTitle(isEditMode ? "Done" : "Select", for: .normal)
        deleteSelectedButton.isHidden = !isEditMode
        updateDeleteSelectedButton()
        collectionView.reloadData()
    }

    @objc private func deleteSelectedTapped() {
        guard !selectedIndices.isEmpty else { return }

        let count = selectedIndices.count
        let alert = UIAlertController(
            title: "Delete \(count) Document\(count == 1 ? "" : "s")?",
            message: "This action cannot be undone.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            UINotificationFeedbackGenerator().notificationOccurred(.warning)

            let sortedIndices = self.selectedIndices.sorted(by: >)
            for index in sortedIndices {
                let doc = self.viewModel.documents[index]
                self.viewModel.deleteDocument(doc) { _ in }
            }
            self.selectedIndices.removeAll()
            self.refreshData()
            self.updateDeleteSelectedButton()
        })
        present(alert, animated: true)
    }

    private func updateDeleteSelectedButton() {
        let count = selectedIndices.count
        deleteSelectedButton.setTitle(count > 0 ? "Delete Selected (\(count))" : "Delete Selected", for: .normal)
        deleteSelectedButton.isEnabled = count > 0
        deleteSelectedButton.alpha = count > 0 ? 1.0 : 0.5
    }

    @objc private func sortTapped() {
        let alert = UIAlertController(title: "Sort By", message: nil, preferredStyle: .actionSheet)

        alert.addAction(UIAlertAction(title: "Newest First", style: .default) { [weak self] _ in
            self?.viewModel.changeSortOrder(to: .dateDescending)
            self?.collectionView.reloadData()
        })
        alert.addAction(UIAlertAction(title: "Oldest First", style: .default) { [weak self] _ in
            self?.viewModel.changeSortOrder(to: .dateAscending)
            self?.collectionView.reloadData()
        })
        alert.addAction(UIAlertAction(title: "Alphabetical", style: .default) { [weak self] _ in
            self?.viewModel.changeSortOrder(to: .alphabetical)
            self?.collectionView.reloadData()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        present(alert, animated: true)
    }
}

// MARK: - UICollectionViewDataSource
extension DocumentLibraryViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.documents.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DocumentCardCell.reuseIdentifier, for: indexPath) as? DocumentCardCell else {
            return UICollectionViewCell()
        }
        let doc = viewModel.documents[indexPath.item]
        let isSelected = isEditMode && selectedIndices.contains(indexPath.item)
        cell.configure(with: doc, showCheckmark: isEditMode, isChecked: isSelected)
        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension DocumentLibraryViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if isEditMode {
            if selectedIndices.contains(indexPath.item) {
                selectedIndices.remove(indexPath.item)
            } else {
                selectedIndices.insert(indexPath.item)
            }
            collectionView.reloadItems(at: [indexPath])
            updateDeleteSelectedButton()
            return
        }

        let doc = viewModel.documents[indexPath.item]
        delegate?.documentLibrary(self, didSelectDocument: doc)
    }

    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let doc = viewModel.documents[indexPath.item]
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
            let delete = UIAction(title: "Delete", image: UIImage(systemName: "trash"), attributes: .destructive) { _ in
                guard let self = self else { return }
                let alert = UIAlertController(
                    title: "Delete Document",
                    message: "Are you sure you want to delete \"\(doc.filename)\"?",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
                    self.viewModel.deleteDocument(doc) { success in
                        if success {
                            self.refreshData()
                        }
                    }
                })
                self.present(alert, animated: true)
            }
            return UIMenu(children: [delete])
        }
    }
}

// MARK: - DocumentCardCell
class DocumentCardCell: UICollectionViewCell {

    static let reuseIdentifier = "DocumentCardCell"

    private let thumbnailView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = ScannerTheme.Colors.cardBackground
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = ScannerTheme.Fonts.body
        label.textColor = ScannerTheme.Colors.textPrimary
        label.adjustsFontForContentSizeCategory = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let detailLabel: UILabel = {
        let label = UILabel()
        label.font = ScannerTheme.Fonts.caption
        label.textColor = ScannerTheme.Colors.textSecondary
        label.adjustsFontForContentSizeCategory = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let checkmarkView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.tintColor = ScannerTheme.Colors.accent
        iv.isHidden = true
        return iv
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCell()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupCell() {
        contentView.backgroundColor = ScannerTheme.Colors.cardBackground
        contentView.layer.cornerRadius = ScannerTheme.Corner.card
        contentView.clipsToBounds = true

        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.3
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 6
        layer.masksToBounds = false
        layer.cornerRadius = ScannerTheme.Corner.card

        contentView.addSubview(thumbnailView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(detailLabel)
        contentView.addSubview(checkmarkView)

        NSLayoutConstraint.activate([
            thumbnailView.topAnchor.constraint(equalTo: contentView.topAnchor),
            thumbnailView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            thumbnailView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            thumbnailView.bottomAnchor.constraint(equalTo: nameLabel.topAnchor, constant: -8),

            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            nameLabel.bottomAnchor.constraint(equalTo: detailLabel.topAnchor, constant: -2),

            detailLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            detailLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            detailLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),

            checkmarkView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            checkmarkView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            checkmarkView.widthAnchor.constraint(equalToConstant: 24),
            checkmarkView.heightAnchor.constraint(equalToConstant: 24)
        ])
    }

    private var currentCacheKey: String?

    override func prepareForReuse() {
        super.prepareForReuse()
        thumbnailView.image = nil
        thumbnailView.contentMode = .scaleAspectFill
        currentCacheKey = nil
        checkmarkView.isHidden = true
    }

    func configure(with metadata: DocumentMetadata, showCheckmark: Bool = false, isChecked: Bool = false) {
        let name = (metadata.filename as NSString).deletingPathExtension
        nameLabel.text = name
        detailLabel.text = "\(metadata.pageCount)p · \(metadata.formattedFileSize) · \(metadata.formattedDate)"

        accessibilityLabel = "\(name), \(metadata.formattedDate), \(metadata.pageCount) page\(metadata.pageCount == 1 ? "" : "s"), \(metadata.formattedFileSize)"

        if showCheckmark {
            checkmarkView.isHidden = false
            let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
            checkmarkView.image = UIImage(systemName: isChecked ? "checkmark.circle.fill" : "circle", withConfiguration: config)
        } else {
            checkmarkView.isHidden = true
        }

        // Load PDF thumbnail
        let storageService = DocumentStorageService()
        let pdfURL = storageService.getScannedDocumentsDirectory().appendingPathComponent(metadata.filename)
        let cacheKey = metadata.filename
        currentCacheKey = cacheKey
        let targetSize = CGSize(width: contentView.bounds.width * UIScreen.main.scale,
                                height: contentView.bounds.width * UIScreen.main.scale)

        ThumbnailService.shared.generatePDFThumbnail(for: pdfURL, targetSize: targetSize) { [weak self] thumbnail in
            guard self?.currentCacheKey == cacheKey else { return }
            if let thumbnail = thumbnail {
                self?.thumbnailView.image = thumbnail
            } else {
                let config = UIImage.SymbolConfiguration(pointSize: 36, weight: .regular)
                self?.thumbnailView.image = UIImage(systemName: "doc.fill", withConfiguration: config)
                self?.thumbnailView.tintColor = ScannerTheme.Colors.textSecondary
                self?.thumbnailView.contentMode = .center
            }
        }
    }
}
