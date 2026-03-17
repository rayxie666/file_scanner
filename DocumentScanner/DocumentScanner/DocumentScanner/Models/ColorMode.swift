//
//  ColorMode.swift
//  DocumentScanner
//
//  Color mode options for document processing
//

import Foundation

enum ColorMode: String, Codable, CaseIterable {
    case original = "Original Color"
    case grayscale = "Grayscale"
    case blackAndWhite = "Black & White"

    var description: String {
        return self.rawValue
    }
}
