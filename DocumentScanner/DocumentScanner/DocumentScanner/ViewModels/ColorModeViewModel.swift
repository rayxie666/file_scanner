//
//  ColorModeViewModel.swift
//  DocumentScanner
//
//  ViewModel for color mode selection
//

import Foundation
import Combine
import UIKit

class ColorModeViewModel: ObservableObject {

    @Published var selectedColorMode: ColorMode = .original
    @Published var previewImage: UIImage?
    @Published var isProcessing = false
    @Published var errorMessage: String?

    private let originalImage: UIImage
    private let quadrilateral: DetectedQuadrilateral
    private let imageProcessingService = ImageProcessingService()
    private var cancellables = Set<AnyCancellable>()

    init(image: UIImage, quadrilateral: DetectedQuadrilateral) {
        self.originalImage = image
        self.quadrilateral = quadrilateral

        // Process with initial color mode
        processImage(with: .original)
    }

    func selectColorMode(_ mode: ColorMode) {
        guard selectedColorMode != mode else { return }
        selectedColorMode = mode
        processImage(with: mode)
    }

    private func processImage(with colorMode: ColorMode) {
        isProcessing = true
        errorMessage = nil

        imageProcessingService.processImage(originalImage, quadrilateral: quadrilateral, colorMode: colorMode) { [weak self] result in
            guard let self = self else { return }

            self.isProcessing = false

            switch result {
            case .success(let processedImage):
                self.previewImage = processedImage

            case .failure(let error):
                self.errorMessage = "Failed to process image: \(error.localizedDescription)"
            }
        }
    }

    func getCurrentProcessedImage() -> UIImage? {
        return previewImage
    }
}
