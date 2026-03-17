//
//  CameraViewController.swift
//  DocumentScanner
//
//  Camera view controller using AVFoundation
//

import UIKit
import AVFoundation
import Combine

protocol CameraViewControllerDelegate: AnyObject {
    func cameraViewController(_ controller: CameraViewController, didCaptureImage image: UIImage)
    func cameraViewControllerDidCancel(_ controller: CameraViewController)
}

class CameraViewController: UIViewController {

    weak var delegate: CameraViewControllerDelegate?

    // MARK: - Camera Components
    private var captureSession: AVCaptureSession?
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    private var photoOutput: AVCapturePhotoOutput?
    private var currentCamera: AVCaptureDevice?

    // MARK: - UI Components
    private let captureButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .clear
        button.layer.cornerRadius = 35
        button.layer.borderWidth = 4
        button.layer.borderColor = UIColor.white.cgColor
        button.translatesAutoresizingMaskIntoConstraints = false

        // Inner white circle
        let innerCircle = UIView()
        innerCircle.backgroundColor = .white
        innerCircle.layer.cornerRadius = 28
        innerCircle.isUserInteractionEnabled = false
        innerCircle.translatesAutoresizingMaskIntoConstraints = false
        button.addSubview(innerCircle)
        NSLayoutConstraint.activate([
            innerCircle.centerXAnchor.constraint(equalTo: button.centerXAnchor),
            innerCircle.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            innerCircle.widthAnchor.constraint(equalToConstant: 56),
            innerCircle.heightAnchor.constraint(equalToConstant: 56)
        ])

        return button
    }()

    private lazy var flashButton: UIButton = {
        let button = ScannerTheme.makePillButton(title: "", style: .secondary, iconName: "bolt.slash.fill")
        button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
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

    private var isFlashOn = false

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ScannerTheme.Colors.background
        navigationController?.setNavigationBarHidden(true, animated: false)
        setupCamera()
        setupUI()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startCamera()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopCamera()
    }

    // MARK: - Camera Setup
    private func setupCamera() {
        // Check camera permission
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configureCaptureSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    DispatchQueue.main.async {
                        self?.configureCaptureSession()
                    }
                } else {
                    DispatchQueue.main.async {
                        self?.showPermissionDeniedAlert()
                    }
                }
            }
        case .denied, .restricted:
            showPermissionDeniedAlert()
        @unknown default:
            break
        }
    }

    private func configureCaptureSession() {
        let session = AVCaptureSession()
        session.sessionPreset = .photo

        // Get camera device
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            showNoCameraAlert()
            return
        }

        currentCamera = camera

        do {
            let input = try AVCaptureDeviceInput(device: camera)

            if session.canAddInput(input) {
                session.addInput(input)
            }

            let output = AVCapturePhotoOutput()
            if session.canAddOutput(output) {
                session.addOutput(output)
                photoOutput = output
            }

            captureSession = session

            // Setup preview layer
            let previewLayer = AVCaptureVideoPreviewLayer(session: session)
            previewLayer.videoGravity = .resizeAspectFill
            previewLayer.frame = view.bounds
            view.layer.insertSublayer(previewLayer, at: 0)
            videoPreviewLayer = previewLayer

            // Configure tap to focus
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapToFocus(_:)))
            view.addGestureRecognizer(tapGesture)

        } catch {
            // Camera setup failed silently - user sees no preview
        }
    }

    private func startCamera() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.startRunning()
        }
    }

    private func stopCamera() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.stopRunning()
        }
    }

    // MARK: - UI Setup
    private func setupUI() {
        view.addSubview(captureButton)
        view.addSubview(flashButton)
        view.addSubview(cancelButton)
        view.addSubview(activityIndicator)

        NSLayoutConstraint.activate([
            // Capture button
            captureButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            captureButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            captureButton.widthAnchor.constraint(equalToConstant: 70),
            captureButton.heightAnchor.constraint(equalToConstant: 70),

            // Flash button
            flashButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -ScannerTheme.Spacing.screenMargin),
            flashButton.centerYAnchor.constraint(equalTo: captureButton.centerYAnchor),

            // Cancel button
            cancelButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: ScannerTheme.Spacing.screenMargin),
            cancelButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: ScannerTheme.Spacing.screenMargin),

            // Activity indicator
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        captureButton.addTarget(self, action: #selector(captureButtonTapped), for: .touchUpInside)
        flashButton.addTarget(self, action: #selector(flashButtonTapped), for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)

        // Accessibility
        captureButton.accessibilityLabel = "Take Photo"
        captureButton.accessibilityIdentifier = "captureButton"
        flashButton.accessibilityLabel = isFlashOn ? "Flash On" : "Flash Off"
        flashButton.accessibilityIdentifier = "flashButton"
        cancelButton.accessibilityLabel = "Cancel"
        cancelButton.accessibilityIdentifier = "cameraCancelButton"
    }

    // MARK: - Actions
    @objc private func captureButtonTapped() {
        // Ring-pulse animation
        UIView.animate(
            withDuration: 0.15,
            animations: {
                self.captureButton.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
            },
            completion: { _ in
                UIView.animate(
                    withDuration: ScannerTheme.Animation.duration,
                    delay: 0,
                    usingSpringWithDamping: ScannerTheme.Animation.springDamping,
                    initialSpringVelocity: ScannerTheme.Animation.springVelocity,
                    options: .curveEaseOut
                ) {
                    self.captureButton.transform = .identity
                }
            }
        )

        capturePhoto()
    }

    @objc private func flashButtonTapped() {
        isFlashOn.toggle()
        updateFlashButton()
    }

    @objc private func cancelButtonTapped() {
        delegate?.cameraViewControllerDidCancel(self)
    }

    @objc private func handleTapToFocus(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: view)
        focusCamera(at: location)
    }

    // MARK: - Camera Operations
    private let captureHaptic = UIImpactFeedbackGenerator(style: .medium)

    private func capturePhoto() {
        guard let photoOutput = photoOutput else { return }

        // Disable capture button during processing
        captureButton.isEnabled = false
        activityIndicator.startAnimating()
        captureHaptic.impactOccurred()

        let settings = AVCapturePhotoSettings()

        // Set flash mode
        if isFlashOn && photoOutput.supportedFlashModes.contains(.on) {
            settings.flashMode = .on
        } else {
            settings.flashMode = .off
        }

        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    private func focusCamera(at point: CGPoint) {
        guard let device = currentCamera,
              let previewLayer = videoPreviewLayer else { return }

        let focusPoint = previewLayer.captureDevicePointConverted(fromLayerPoint: point)

        do {
            try device.lockForConfiguration()

            if device.isFocusModeSupported(.autoFocus) && device.isFocusPointOfInterestSupported {
                device.focusMode = .autoFocus
                device.focusPointOfInterest = focusPoint
            }

            if device.isExposureModeSupported(.autoExpose) && device.isExposurePointOfInterestSupported {
                device.exposureMode = .autoExpose
                device.exposurePointOfInterest = focusPoint
            }

            device.unlockForConfiguration()

            // Show focus indicator
            showFocusIndicator(at: point)
        } catch {
            // Focus adjustment failed - non-critical
        }
    }

    private func showFocusIndicator(at point: CGPoint) {
        let focusView = UIView(frame: CGRect(x: 0, y: 0, width: 80, height: 80))
        focusView.center = point
        focusView.layer.borderColor = UIColor.yellow.cgColor
        focusView.layer.borderWidth = 2
        focusView.layer.cornerRadius = 40
        focusView.alpha = 0
        view.addSubview(focusView)

        UIView.animate(withDuration: 0.3, animations: {
            focusView.alpha = 1
            focusView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        }) { _ in
            UIView.animate(withDuration: 0.3, delay: 0.5, animations: {
                focusView.alpha = 0
            }) { _ in
                focusView.removeFromSuperview()
            }
        }
    }

    private func updateFlashButton() {
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        let imageName = isFlashOn ? "bolt.fill" : "bolt.slash.fill"
        flashButton.setImage(UIImage(systemName: imageName, withConfiguration: config), for: .normal)
        flashButton.accessibilityLabel = isFlashOn ? "Flash On" : "Flash Off"
    }

    // MARK: - Alerts
    private func showPermissionDeniedAlert() {
        let alert = UIAlertController(
            title: "Camera Access Required",
            message: "Camera access is required to scan documents. Please enable it in Settings.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
            guard let self = self else { return }
            self.delegate?.cameraViewControllerDidCancel(self)
        })

        alert.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
            if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsUrl)
            }
        })

        present(alert, animated: true)
    }

    private func showNoCameraAlert() {
        let alert = UIAlertController(
            title: "Camera Not Available",
            message: "This device does not have a camera.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            guard let self = self else { return }
            self.delegate?.cameraViewControllerDidCancel(self)
        })

        present(alert, animated: true)
    }

    // MARK: - Orientation
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate { [weak self] _ in
            self?.videoPreviewLayer?.frame = CGRect(origin: .zero, size: size)
            self?.updatePreviewOrientation()
        }
    }

    private func updatePreviewOrientation() {
        guard let connection = videoPreviewLayer?.connection else { return }

        if connection.isVideoOrientationSupported {
            connection.videoOrientation = currentVideoOrientation()
        }
    }

    private func currentVideoOrientation() -> AVCaptureVideoOrientation {
        switch UIDevice.current.orientation {
        case .portrait:
            return .portrait
        case .portraitUpsideDown:
            return .portraitUpsideDown
        case .landscapeLeft:
            return .landscapeRight
        case .landscapeRight:
            return .landscapeLeft
        default:
            return .portrait
        }
    }
}

// MARK: - AVCapturePhotoCaptureDelegate
extension CameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        captureButton.isEnabled = true
        activityIndicator.stopAnimating()

        if let error = error {
            // Photo capture failed
            return
        }

        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            return
        }

        UIAccessibility.post(notification: .announcement, argument: "Photo captured")
        delegate?.cameraViewController(self, didCaptureImage: image)
    }
}
