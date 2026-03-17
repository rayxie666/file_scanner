//
//  SessionRecoveryService.swift
//  DocumentScanner
//
//  Service for saving and recovering unsaved scanning sessions
//

import UIKit
import os.log

private let recoveryLog = OSLog(subsystem: "com.documentscanner", category: "recovery")

class SessionRecoveryService {

    private static let recoveryKey = "SessionRecoveryData"
    private let fileManager = FileManager.default

    private var recoveryCacheDirectory: URL {
        let caches = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        return caches.appendingPathComponent("SessionRecovery", isDirectory: true)
    }

    // MARK: - Save

    func saveRecoveryData(from session: ScanSession) {
        do {
            // Ensure recovery directory exists
            try fileManager.createDirectory(at: recoveryCacheDirectory, withIntermediateDirectories: true)

            var pageInfos: [[String: Any]] = []

            for (index, page) in session.pages.enumerated() {
                // Write original and cropped images to cache
                let originalPath = recoveryCacheDirectory.appendingPathComponent("original_\(index).jpg")
                let croppedPath = recoveryCacheDirectory.appendingPathComponent("cropped_\(index).jpg")

                if let originalData = page.originalImage.jpegData(compressionQuality: 0.8) {
                    try originalData.write(to: originalPath, options: .atomic)
                }
                if let croppedData = page.croppedImage.jpegData(compressionQuality: 0.8) {
                    try croppedData.write(to: croppedPath, options: .atomic)
                }

                pageInfos.append([
                    "originalPath": originalPath.path,
                    "croppedPath": croppedPath.path,
                    "colorMode": page.colorMode.rawValue,
                    "pageNumber": page.pageNumber
                ])
            }

            let recoveryData: [String: Any] = [
                "pages": pageInfos,
                "timestamp": Date().timeIntervalSince1970
            ]

            UserDefaults.standard.set(recoveryData, forKey: SessionRecoveryService.recoveryKey)
        } catch {
            os_log("Failed to save recovery data: %{public}@", log: recoveryLog, type: .error, error.localizedDescription)
        }
    }

    // MARK: - Load

    func hasRecoveryData() -> Bool {
        return UserDefaults.standard.dictionary(forKey: SessionRecoveryService.recoveryKey) != nil
    }

    func loadRecoveryData() -> [ScannedPage]? {
        guard let recoveryData = UserDefaults.standard.dictionary(forKey: SessionRecoveryService.recoveryKey),
              let pageInfos = recoveryData["pages"] as? [[String: Any]] else {
            return nil
        }

        var pages: [ScannedPage] = []

        for info in pageInfos {
            guard let originalPath = info["originalPath"] as? String,
                  let croppedPath = info["croppedPath"] as? String,
                  let colorModeRaw = info["colorMode"] as? String,
                  let colorMode = ColorMode(rawValue: colorModeRaw),
                  let pageNumber = info["pageNumber"] as? Int,
                  let originalImage = UIImage(contentsOfFile: originalPath),
                  let croppedImage = UIImage(contentsOfFile: croppedPath) else {
                continue
            }

            let page = ScannedPage(
                originalImage: originalImage,
                croppedImage: croppedImage,
                colorMode: colorMode,
                pageNumber: pageNumber
            )
            pages.append(page)
        }

        return pages.isEmpty ? nil : pages
    }

    // MARK: - Clear

    func clearRecoveryData() {
        UserDefaults.standard.removeObject(forKey: SessionRecoveryService.recoveryKey)

        try? fileManager.removeItem(at: recoveryCacheDirectory)
    }
}
