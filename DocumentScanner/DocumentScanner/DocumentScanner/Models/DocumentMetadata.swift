//
//  DocumentMetadata.swift
//  DocumentScanner
//
//  Metadata for PDF documents
//

import Foundation

struct DocumentMetadata: Codable {
    let filename: String
    let creationDate: Date
    let pageCount: Int
    let fileSize: Int64

    var formattedFileSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: creationDate)
    }
}
