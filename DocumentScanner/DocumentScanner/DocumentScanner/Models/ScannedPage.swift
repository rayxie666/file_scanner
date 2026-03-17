//
//  ScannedPage.swift
//  DocumentScanner
//
//  Model representing a single scanned document page
//

import UIKit

struct ScannedPage {
    let originalImage: UIImage
    let croppedImage: UIImage
    let colorMode: ColorMode
    var pageNumber: Int

    init(originalImage: UIImage, croppedImage: UIImage, colorMode: ColorMode, pageNumber: Int) {
        self.originalImage = originalImage
        self.croppedImage = croppedImage
        self.colorMode = colorMode
        self.pageNumber = pageNumber
    }
}
