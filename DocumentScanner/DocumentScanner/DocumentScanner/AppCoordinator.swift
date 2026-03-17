//
//  AppCoordinator.swift
//  DocumentScanner
//
//  Navigation coordinator managing the full app flow:
//  Library -> Camera -> Crop -> ColorMode -> Session Review -> PDF Save -> Library
//

import UIKit
import PhotosUI
import UniformTypeIdentifiers
import PDFKit

class AppCoordinator: NSObject {

    let navigationController: UINavigationController
    private let sessionManager = ScanSessionManager.shared
    private let sessionViewModel = SessionViewModel()
    private let storageService = DocumentStorageService()

    // Track current image/corners through the scanning pipeline
    private var currentImage: UIImage?
    private var currentCorners: [CGPoint]?

    // Track pending images for multi-image upload flow
    private var pendingUploadImages: [UIImage] = []
    private var isUploadFlow = false

    private var sessionReviewVC: SessionReviewViewController?

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    private let recoveryService = SessionRecoveryService()

    func start() {
        let libraryVC = DocumentLibraryViewController()
        libraryVC.delegate = self
        navigationController.viewControllers = [libraryVC]
    }

    func offerSessionRecovery() {
        let alert = UIAlertController(
            title: "Unsaved Session",
            message: "You have an unsaved scanning session. Would you like to recover it?",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Recover", style: .default) { [weak self] _ in
            guard let self = self,
                  let pages = self.recoveryService.loadRecoveryData() else { return }

            self.sessionManager.startNewSession()
            for page in pages {
                self.sessionManager.addPage(page)
            }
            self.recoveryService.clearRecoveryData()

            let reviewVC = SessionReviewViewController()
            reviewVC.delegate = self
            self.sessionReviewVC = reviewVC
            self.navigationController.pushViewController(reviewVC, animated: true)
        })

        alert.addAction(UIAlertAction(title: "Discard", style: .destructive) { [weak self] _ in
            self?.recoveryService.clearRecoveryData()
        })

        navigationController.viewControllers.first?.present(alert, animated: true)
    }

    // MARK: - Scanning Flow
    private func startScanningFlow() {
        sessionManager.startNewSession()
        showCamera()
    }

    // MARK: - Upload Flow
    private func startUploadFlow() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        alert.addAction(UIAlertAction(title: "Photo Library", style: .default) { [weak self] _ in
            self?.showPhotoPicker()
        })

        alert.addAction(UIAlertAction(title: "Choose File", style: .default) { [weak self] _ in
            self?.showDocumentPicker()
        })

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let popover = alert.popoverPresentationController {
            popover.sourceView = navigationController.view
            popover.sourceRect = CGRect(x: navigationController.view.bounds.midX, y: navigationController.view.bounds.maxY - 100, width: 0, height: 0)
        }

        navigationController.present(alert, animated: true)
    }

    private func showPhotoPicker() {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 0 // 0 means unlimited

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        navigationController.present(picker, animated: true)
    }

    private func showDocumentPicker() {
        let supportedTypes: [UTType] = [.jpeg, .png, .heic, .pdf]
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes)
        picker.delegate = self
        picker.allowsMultipleSelection = false
        navigationController.present(picker, animated: true)
    }

    private func handleUploadedImage(_ image: UIImage) {
        sessionManager.startNewSession()
        pendingUploadImages = []
        isUploadFlow = true
        showCrop(with: image)
    }

    private func handleUploadedImages(_ images: [UIImage]) {
        guard !images.isEmpty else { return }

        sessionManager.startNewSession()
        isUploadFlow = true

        if images.count == 1 {
            pendingUploadImages = []
            showCrop(with: images[0])
        } else {
            pendingUploadImages = Array(images.dropFirst())
            showCrop(with: images[0])
        }
    }

    private func processNextUploadedImage() {
        guard !pendingUploadImages.isEmpty else { return }
        let nextImage = pendingUploadImages.removeFirst()
        showCrop(with: nextImage)
    }

    private func handlePDFImport(from url: URL) {
        guard url.startAccessingSecurityScopedResource() else {
            showError(title: "Access Denied", message: "Unable to access the selected file.")
            return
        }

        defer { url.stopAccessingSecurityScopedResource() }

        guard let pdfDocument = PDFDocument(url: url) else {
            showError(title: "Invalid PDF", message: "The selected file could not be opened as a PDF.")
            return
        }

        let pageCount = pdfDocument.pageCount
        guard pageCount > 0 else {
            showError(title: "Empty PDF", message: "The selected PDF has no pages.")
            return
        }

        var images: [UIImage] = []
        let targetSize = CGSize(width: 2000, height: 2000)

        for i in 0..<pageCount {
            autoreleasepool {
                guard let page = pdfDocument.page(at: i) else { return }
                let pageRect = page.bounds(for: .mediaBox)
                let scale = min(targetSize.width / pageRect.width, targetSize.height / pageRect.height)
                let scaledSize = CGSize(width: pageRect.width * scale, height: pageRect.height * scale)

                let image = page.thumbnail(of: scaledSize, for: .mediaBox)
                images.append(image)
            }
        }

        guard !images.isEmpty else {
            showError(title: "PDF Error", message: "Could not extract pages from the PDF.")
            return
        }

        sessionManager.startNewSession()
        isUploadFlow = true

        if images.count == 1 {
            pendingUploadImages = []
            showCrop(with: images[0])
        } else {
            // Multi-page PDF: add all pages directly to session without crop
            for (index, image) in images.enumerated() {
                let page = ScannedPage(
                    originalImage: image,
                    croppedImage: image,
                    colorMode: .original,
                    pageNumber: index + 1
                )
                sessionManager.addPage(page)
            }
            pendingUploadImages = []
            isUploadFlow = false

            let reviewVC = SessionReviewViewController()
            reviewVC.delegate = self
            sessionReviewVC = reviewVC
            navigationController.pushViewController(reviewVC, animated: true)
        }
    }

    private func handleDocumentFile(from url: URL) {
        guard url.startAccessingSecurityScopedResource() else {
            showError(title: "Access Denied", message: "Unable to access the selected file.")
            return
        }

        defer { url.stopAccessingSecurityScopedResource() }

        let pathExtension = url.pathExtension.lowercased()

        if pathExtension == "pdf" {
            handlePDFImport(from: url)
            return
        }

        // Handle image files
        guard let data = try? Data(contentsOf: url),
              let image = UIImage(data: data) else {
            showError(title: "Invalid File", message: "The selected file could not be opened as an image.")
            return
        }

        handleUploadedImage(image)
    }

    private func showError(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        navigationController.present(alert, animated: true)
    }

    private func showCamera() {
        let cameraVC = CameraViewController()
        cameraVC.delegate = self
        cameraVC.modalPresentationStyle = .fullScreen
        navigationController.present(cameraVC, animated: true)
    }

    private func showCrop(with image: UIImage) {
        currentImage = image
        let cropVC = CropViewController(image: image)
        cropVC.delegate = self
        cropVC.modalPresentationStyle = .fullScreen

        if let presented = navigationController.presentedViewController {
            presented.present(cropVC, animated: true)
        } else {
            navigationController.present(cropVC, animated: true)
        }
    }

    private func showColorMode(with image: UIImage, corners: [CGPoint]) {
        currentCorners = corners
        let colorModeVC = ColorModeViewController(image: image, corners: corners)
        colorModeVC.delegate = self
        colorModeVC.modalPresentationStyle = .fullScreen

        if let presented = navigationController.presentedViewController {
            // Dismiss crop, then present color mode
            presented.dismiss(animated: true) { [weak self] in
                guard let topPresented = self?.navigationController.presentedViewController else { return }
                topPresented.present(colorModeVC, animated: true)
            }
        }
    }

    private func showSessionReview() {
        // Dismiss all modal presentations
        navigationController.dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            self.isUploadFlow = false
            self.pendingUploadImages = []

            let reviewVC = SessionReviewViewController()
            reviewVC.delegate = self
            self.sessionReviewVC = reviewVC
            self.navigationController.pushViewController(reviewVC, animated: true)
        }
    }

    private func showSessionReviewFromUpload() {
        isUploadFlow = false
        pendingUploadImages = []

        let reviewVC = SessionReviewViewController()
        reviewVC.delegate = self
        sessionReviewVC = reviewVC
        navigationController.pushViewController(reviewVC, animated: true)
    }

    private func showPDFPreview(for metadata: DocumentMetadata) {
        let previewVC = PDFPreviewViewController(metadata: metadata)
        previewVC.delegate = self
        navigationController.pushViewController(previewVC, animated: true)
    }

    private func returnToLibrary() {
        sessionManager.endSession()
        recoveryService.clearRecoveryData()
        currentImage = nil
        currentCorners = nil
        sessionReviewVC = nil
        navigationController.popToRootViewController(animated: true)
    }
}

// MARK: - DocumentLibraryViewControllerDelegate
extension AppCoordinator: DocumentLibraryViewControllerDelegate {
    func documentLibraryDidRequestScan(_ controller: DocumentLibraryViewController) {
        startScanningFlow()
    }

    func documentLibraryDidRequestUpload(_ controller: DocumentLibraryViewController) {
        startUploadFlow()
    }

    func documentLibrary(_ controller: DocumentLibraryViewController, didSelectDocument metadata: DocumentMetadata) {
        showPDFPreview(for: metadata)
    }
}

// MARK: - CameraViewControllerDelegate
extension AppCoordinator: CameraViewControllerDelegate {
    func cameraViewController(_ controller: CameraViewController, didCaptureImage image: UIImage) {
        showCrop(with: image)
    }

    func cameraViewControllerDidCancel(_ controller: CameraViewController) {
        // If we have pages, go to session review
        if sessionManager.hasPages() {
            showSessionReview()
        } else {
            navigationController.dismiss(animated: true) {
                self.returnToLibrary()
            }
        }
    }
}

// MARK: - CropViewControllerDelegate
extension AppCoordinator: CropViewControllerDelegate {
    func cropViewController(_ controller: CropViewController, didFinishWithImage image: UIImage, corners: [CGPoint]) {
        currentCorners = corners

        if isUploadFlow {
            // Upload flow: crop is presented directly on nav controller
            controller.dismiss(animated: true) { [weak self] in
                guard let self = self else { return }

                let colorModeVC = ColorModeViewController(image: image, corners: corners)
                colorModeVC.delegate = self
                colorModeVC.modalPresentationStyle = .fullScreen
                self.navigationController.present(colorModeVC, animated: true)
            }
        } else {
            // Camera flow: dismiss crop, then show color mode from camera
            controller.dismiss(animated: true) { [weak self] in
                guard let self = self,
                      let cameraVC = self.navigationController.presentedViewController else { return }

                let colorModeVC = ColorModeViewController(image: image, corners: corners)
                colorModeVC.delegate = self
                colorModeVC.modalPresentationStyle = .fullScreen
                cameraVC.present(colorModeVC, animated: true)
            }
        }
    }

    func cropViewControllerDidCancel(_ controller: CropViewController) {
        if isUploadFlow {
            // Upload flow: go back to library
            controller.dismiss(animated: true) { [weak self] in
                self?.isUploadFlow = false
                self?.pendingUploadImages = []
            }
        } else {
            // Camera flow: go back to camera
            controller.dismiss(animated: true)
        }
    }
}

// MARK: - ColorModeViewControllerDelegate
extension AppCoordinator: ColorModeViewControllerDelegate {
    func colorModeViewController(_ controller: ColorModeViewController, didFinishWithImage image: UIImage, colorMode: ColorMode) {
        // Create scanned page and add to session
        let page = ScannedPage(
            originalImage: currentImage ?? image,
            croppedImage: image,
            colorMode: colorMode,
            pageNumber: sessionManager.pageCount() + 1
        )
        sessionManager.addPage(page)

        if isUploadFlow && !pendingUploadImages.isEmpty {
            // More images to process in upload flow
            controller.dismiss(animated: true) { [weak self] in
                self?.processNextUploadedImage()
            }
        } else {
            // Go to session review
            showSessionReview()
        }
    }

    func colorModeViewControllerDidRequestRecrop(_ controller: ColorModeViewController) {
        // Dismiss color mode, go back to crop
        controller.dismiss(animated: true) { [weak self] in
            guard let self = self, let image = self.currentImage else { return }

            if self.isUploadFlow {
                // Upload flow: present crop directly
                let cropVC = CropViewController(image: image)
                cropVC.delegate = self
                cropVC.modalPresentationStyle = .fullScreen
                self.navigationController.present(cropVC, animated: true)
            } else {
                // Camera flow: present crop from camera
                if let cameraVC = self.navigationController.presentedViewController {
                    let cropVC = CropViewController(image: image)
                    cropVC.delegate = self
                    cropVC.modalPresentationStyle = .fullScreen
                    cameraVC.present(cropVC, animated: true)
                }
            }
        }
    }

    func colorModeViewControllerDidCancel(_ controller: ColorModeViewController) {
        if isUploadFlow {
            // Upload flow: if we have pages, go to session review, otherwise return to library
            controller.dismiss(animated: true) { [weak self] in
                guard let self = self else { return }
                if self.sessionManager.hasPages() {
                    self.showSessionReviewFromUpload()
                } else {
                    self.isUploadFlow = false
                    self.pendingUploadImages = []
                }
            }
        } else {
            // Camera flow: go back to camera
            controller.dismiss(animated: true)
        }
    }
}

// MARK: - SessionReviewViewControllerDelegate
extension AppCoordinator: SessionReviewViewControllerDelegate {
    func sessionReviewDidRequestAddPage(_ controller: SessionReviewViewController) {
        showCamera()
    }

    func sessionReviewDidRequestSavePDF(_ controller: SessionReviewViewController, filename: String) {
        sessionViewModel.loadSession()
        sessionViewModel.generatePDF(filename: filename) { [weak self] result in
            guard let self = self else { return }
            controller.finishedSaving()

            switch result {
            case .success:
                UIAccessibility.post(notification: .announcement, argument: "Document saved as PDF")
                self.returnToLibrary()
                // Refresh library
                if let libraryVC = self.navigationController.viewControllers.first as? DocumentLibraryViewController {
                    libraryVC.refreshData()
                }

            case .failure(let error):
                let message: String
                if "\(error)".contains("permissionDenied") {
                    message = "Unable to save document. Please check your device storage settings."
                } else if "\(error)".contains("insufficientStorage") {
                    message = "Not enough storage space to save this document."
                } else {
                    message = "Could not save PDF: \(error.localizedDescription)"
                }
                let alert = UIAlertController(
                    title: "Save Failed",
                    message: message,
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                controller.present(alert, animated: true)
            }
        }
    }

    func sessionReviewDidRequestEditPage(_ controller: SessionReviewViewController, at index: Int) {
        // For now, just show an info alert. Full edit would re-enter crop/color mode flow.
        let alert = UIAlertController(
            title: "Edit Page",
            message: "Page editing will re-scan this page. Delete and re-scan instead.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        controller.present(alert, animated: true)
    }

    func sessionReviewDidCancel(_ controller: SessionReviewViewController) {
        returnToLibrary()
    }
}

// MARK: - PDFPreviewViewControllerDelegate
extension AppCoordinator: PDFPreviewViewControllerDelegate {
    func pdfPreviewDidDelete(_ controller: PDFPreviewViewController) {
        navigationController.popViewController(animated: true)
        if let libraryVC = navigationController.viewControllers.first as? DocumentLibraryViewController {
            libraryVC.refreshData()
        }
    }

    func pdfPreviewDidRename(_ controller: PDFPreviewViewController, newFilename: String) {
        if let libraryVC = navigationController.viewControllers.first as? DocumentLibraryViewController {
            libraryVC.refreshData()
        }
    }
}

// MARK: - PHPickerViewControllerDelegate
extension AppCoordinator: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        guard !results.isEmpty else {
            picker.dismiss(animated: true)
            return
        }

        var images: [UIImage] = []
        let group = DispatchGroup()

        for result in results {
            group.enter()
            result.itemProvider.loadObject(ofClass: UIImage.self) { object, error in
                if let image = object as? UIImage {
                    images.append(image)
                }
                group.leave()
            }
        }

        group.notify(queue: .main) { [weak self] in
            // Dismiss picker with completion to ensure it's fully gone before presenting crop
            picker.dismiss(animated: true) {
                guard !images.isEmpty else {
                    self?.showError(title: "Import Failed", message: "Could not load the selected images.")
                    return
                }
                self?.handleUploadedImages(images)
            }
        }
    }
}

// MARK: - UIDocumentPickerDelegate
extension AppCoordinator: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        // Dismiss picker with completion to ensure it's fully gone before presenting crop
        controller.dismiss(animated: true) { [weak self] in
            self?.handleDocumentFile(from: url)
        }
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        // User cancelled, no action needed
    }
}
