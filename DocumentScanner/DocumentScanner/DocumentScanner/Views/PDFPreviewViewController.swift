//
//  PDFPreviewViewController.swift
//  DocumentScanner
//
//  PDF preview with share, delete, and rename actions
//

import UIKit
import PDFKit

protocol PDFPreviewViewControllerDelegate: AnyObject {
    func pdfPreviewDidDelete(_ controller: PDFPreviewViewController)
    func pdfPreviewDidRename(_ controller: PDFPreviewViewController, newFilename: String)
}

class PDFPreviewViewController: UIViewController {

    weak var delegate: PDFPreviewViewControllerDelegate?

    private let metadata: DocumentMetadata
    private let pdfURL: URL
    private let storageService = DocumentStorageService()

    // MARK: - UI Components
    private let pdfView: PDFView = {
        let view = PDFView()
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.displayDirection = .vertical
        view.backgroundColor = ScannerTheme.Colors.background
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let metadataLabel: UILabel = {
        let label = UILabel()
        label.font = ScannerTheme.Fonts.caption
        label.textColor = ScannerTheme.Colors.textSecondary
        label.textAlignment = .center
        label.adjustsFontForContentSizeCategory = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var shareButton: UIButton = {
        let button = ScannerTheme.makePillButton(title: "", style: .secondary, iconName: "square.and.arrow.up")
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 14, bottom: 10, right: 14)
        ScannerTheme.applyFrostedBackground(to: button)
        button.accessibilityLabel = "Share"
        return button
    }()

    private lazy var moreButton: UIButton = {
        let button = ScannerTheme.makePillButton(title: "", style: .secondary, iconName: "ellipsis.circle")
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 14, bottom: 10, right: 14)
        ScannerTheme.applyFrostedBackground(to: button)
        button.accessibilityLabel = "More Options"
        return button
    }()

    private lazy var backButton: UIButton = {
        let button = ScannerTheme.makePillButton(title: "", style: .secondary, iconName: "chevron.left")
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 14, bottom: 10, right: 14)
        ScannerTheme.applyFrostedBackground(to: button)
        button.accessibilityLabel = "Back"
        return button
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = ScannerTheme.Fonts.headline
        label.textColor = ScannerTheme.Colors.textPrimary
        label.textAlignment = .center
        label.adjustsFontForContentSizeCategory = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // MARK: - Initialization
    init(metadata: DocumentMetadata) {
        self.metadata = metadata
        self.pdfURL = storageService.getScannedDocumentsDirectory().appendingPathComponent(metadata.filename)
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
        titleLabel.text = (metadata.filename as NSString).deletingPathExtension
        setupUI()
        loadPDF()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Re-show nav bar for library if going back
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    // MARK: - Setup
    private func setupUI() {
        view.addSubview(pdfView)
        view.addSubview(titleLabel)
        view.addSubview(metadataLabel)
        view.addSubview(backButton)
        view.addSubview(shareButton)
        view.addSubview(moreButton)

        NSLayoutConstraint.activate([
            // Back button
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: ScannerTheme.Spacing.screenMargin),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: ScannerTheme.Spacing.screenMargin),

            // Title
            titleLabel.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: backButton.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: shareButton.leadingAnchor, constant: -12),

            // Share button
            shareButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: ScannerTheme.Spacing.screenMargin),
            shareButton.trailingAnchor.constraint(equalTo: moreButton.leadingAnchor, constant: -8),

            // More button
            moreButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: ScannerTheme.Spacing.screenMargin),
            moreButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -ScannerTheme.Spacing.screenMargin),

            // Metadata label
            metadataLabel.topAnchor.constraint(equalTo: backButton.bottomAnchor, constant: 8),
            metadataLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            metadataLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            // PDF view
            pdfView.topAnchor.constraint(equalTo: metadataLabel.bottomAnchor, constant: 4),
            pdfView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pdfView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pdfView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        metadataLabel.text = "\(metadata.formattedDate) · \(metadata.pageCount) page\(metadata.pageCount == 1 ? "" : "s") · \(metadata.formattedFileSize)"

        pdfView.accessibilityIdentifier = "pdfView"

        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        shareButton.addTarget(self, action: #selector(shareTapped), for: .touchUpInside)
        moreButton.addTarget(self, action: #selector(moreTapped), for: .touchUpInside)
    }

    private func loadPDF() {
        if let document = PDFDocument(url: pdfURL) {
            pdfView.document = document
        } else {
            let alert = UIAlertController(
                title: "Unable to Open Document",
                message: "The file may be damaged.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
                guard let self = self else { return }
                let viewModel = DocumentLibraryViewModel()
                viewModel.deleteDocument(self.metadata) { success in
                    if success {
                        self.delegate?.pdfPreviewDidDelete(self)
                    }
                }
            })
            alert.addAction(UIAlertAction(title: "Go Back", style: .cancel) { [weak self] _ in
                self?.navigationController?.popViewController(animated: true)
            })
            present(alert, animated: true)
        }
    }

    // MARK: - Actions
    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func shareTapped() {
        // Check file size and warn if large
        if metadata.fileSize > 10 * 1024 * 1024 {
            let alert = UIAlertController(
                title: "Large File",
                message: "This PDF is \(metadata.formattedFileSize). It may be too large to share via email.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Share Anyway", style: .default) { [weak self] _ in
                self?.presentShareSheet()
            })
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            present(alert, animated: true)
        } else {
            presentShareSheet()
        }
    }

    private func presentShareSheet() {
        let activityVC = UIActivityViewController(activityItems: [pdfURL], applicationActivities: nil)
        activityVC.popoverPresentationController?.sourceView = shareButton
        present(activityVC, animated: true)
    }

    @objc private func moreTapped() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        alert.addAction(UIAlertAction(title: "Rename", style: .default) { [weak self] _ in
            self?.showRenameDialog()
        })

        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.confirmDelete()
        })

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        alert.popoverPresentationController?.sourceView = moreButton
        present(alert, animated: true)
    }

    private func showRenameDialog() {
        let currentName = (metadata.filename as NSString).deletingPathExtension

        let alert = UIAlertController(title: "Rename Document", message: nil, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.text = currentName
            textField.placeholder = "Document name"
            textField.clearButtonMode = .whileEditing
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            guard let self = self,
                  let newName = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespaces),
                  !newName.isEmpty else { return }

            let viewModel = DocumentLibraryViewModel()
            viewModel.renameDocument(self.metadata, to: newName) { success in
                if success {
                    self.titleLabel.text = newName
                    self.delegate?.pdfPreviewDidRename(self, newFilename: newName + ".pdf")
                }
            }
        })

        present(alert, animated: true)
    }

    private func confirmDelete() {
        let alert = UIAlertController(
            title: "Delete Document",
            message: "Are you sure you want to delete \"\((metadata.filename as NSString).deletingPathExtension)\"? This cannot be undone.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            let viewModel = DocumentLibraryViewModel()
            viewModel.deleteDocument(self.metadata) { success in
                if success {
                    self.delegate?.pdfPreviewDidDelete(self)
                }
            }
        })

        present(alert, animated: true)
    }
}
