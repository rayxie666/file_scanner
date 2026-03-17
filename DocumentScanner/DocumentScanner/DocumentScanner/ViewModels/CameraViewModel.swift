//
//  CameraViewModel.swift
//  DocumentScanner
//
//  ViewModel for camera capture functionality
//

import Foundation
import Combine
import AVFoundation
import UIKit

class CameraViewModel: ObservableObject {

    @Published var isCapturing = false
    @Published var flashMode: AVCaptureDevice.FlashMode = .off
    @Published var errorMessage: String?
    @Published var capturedImage: UIImage?

    var cameraPermissionGranted: Bool {
        return AVCaptureDevice.authorizationStatus(for: .video) == .authorized
    }

    func requestCameraPermission(completion: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }

    func checkCameraPermission() -> AVAuthorizationStatus {
        return AVCaptureDevice.authorizationStatus(for: .video)
    }

    func toggleFlash() {
        flashMode = flashMode == .off ? .on : .off
    }

    func capturePhoto() {
        guard !isCapturing else { return }
        isCapturing = true
    }

    func captureCompleted(with image: UIImage?) {
        isCapturing = false
        capturedImage = image
    }

    func handleError(_ error: String) {
        errorMessage = error
    }

    func clearError() {
        errorMessage = nil
    }
}
