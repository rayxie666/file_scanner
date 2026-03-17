//
//  ThumbnailService.swift
//  DocumentScanner
//
//  Service for generating and caching image thumbnails
//

import UIKit

class ThumbnailService {

    static let shared = ThumbnailService()

    private let cache = NSCache<NSString, UIImage>()
    private let queue = DispatchQueue(label: "com.documentscanner.thumbnails", qos: .utility, attributes: .concurrent)

    private init() {
        cache.countLimit = 100
    }

    func generateThumbnail(
        for image: UIImage,
        targetSize: CGSize,
        cacheKey: String,
        completion: @escaping (UIImage?) -> Void
    ) {
        let key = cacheKey as NSString

        // Check cache first
        if let cached = cache.object(forKey: key) {
            DispatchQueue.main.async { completion(cached) }
            return
        }

        // Generate on background queue
        queue.async { [weak self] in
            let renderer = UIGraphicsImageRenderer(size: targetSize)
            let thumbnail = renderer.image { _ in
                image.draw(in: CGRect(origin: .zero, size: targetSize))
            }

            self?.cache.setObject(thumbnail, forKey: key)

            DispatchQueue.main.async { completion(thumbnail) }
        }
    }

    func generatePDFThumbnail(
        for url: URL,
        targetSize: CGSize,
        completion: @escaping (UIImage?) -> Void
    ) {
        let key = url.lastPathComponent as NSString

        if let cached = cache.object(forKey: key) {
            DispatchQueue.main.async { completion(cached) }
            return
        }

        queue.async { [weak self] in
            guard let document = PDFKit.PDFDocument(url: url),
                  let page = document.page(at: 0) else {
                DispatchQueue.main.async { completion(nil) }
                return
            }

            let pageRect = page.bounds(for: .mediaBox)
            let scale = min(targetSize.width / pageRect.width, targetSize.height / pageRect.height)
            let scaledSize = CGSize(width: pageRect.width * scale, height: pageRect.height * scale)

            let renderer = UIGraphicsImageRenderer(size: scaledSize)
            let thumbnail = renderer.image { ctx in
                UIColor.white.setFill()
                ctx.fill(CGRect(origin: .zero, size: scaledSize))

                ctx.cgContext.translateBy(x: 0, y: scaledSize.height)
                ctx.cgContext.scaleBy(x: scale, y: -scale)
                page.draw(with: .mediaBox, to: ctx.cgContext)
            }

            self?.cache.setObject(thumbnail, forKey: key)

            DispatchQueue.main.async { completion(thumbnail) }
        }
    }

    func clearCache() {
        cache.removeAllObjects()
    }
}

import PDFKit
