//
//  DocumentScannerApp.swift
//  DocumentScanner
//
//  Created by Ray Xie on 1/28/26.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var coordinator: AppCoordinator?
    private let recoveryService = SessionRecoveryService()

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let navigationController = UINavigationController()
        navigationController.navigationBar.prefersLargeTitles = true

        coordinator = AppCoordinator(navigationController: navigationController)
        coordinator?.start()

        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()

        // Check for session recovery after UI is set up
        if recoveryService.hasRecoveryData() {
            coordinator?.offerSessionRecovery()
        }

        return true
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Save session recovery data if there's an active session with pages
        if ScanSessionManager.shared.hasPages(),
           let session = ScanSessionManager.shared.currentSession {
            recoveryService.saveRecoveryData(from: session)
        }
    }
}
