//
//  ScannerTheme.swift
//  DocumentScanner
//
//  Centralized design system for Snapchat-style UI
//

import UIKit

struct ScannerTheme {

    // MARK: - Colors

    enum Colors {
        static let background = UIColor.black
        static let textPrimary = UIColor.white
        static let textSecondary = UIColor.white.withAlphaComponent(0.6)
        static let accent = UIColor.systemGreen
        static let overlayDark = UIColor.black.withAlphaComponent(0.5)
        static let cardBackground = UIColor(white: 0.12, alpha: 1.0)
        static let handleHighlight = UIColor.systemGreen
    }

    // MARK: - Fonts

    enum Fonts {
        static let headline = UIFont.preferredFont(forTextStyle: .headline)
        static let body = UIFont.preferredFont(forTextStyle: .body)
        static let caption = UIFont.preferredFont(forTextStyle: .caption1)
        static let button = UIFont.preferredFont(forTextStyle: .headline)
    }

    // MARK: - Spacing

    enum Spacing {
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
        static let screenMargin: CGFloat = 20
    }

    // MARK: - Corner Radii

    enum Corner {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let card: CGFloat = 16
    }

    // MARK: - Animation

    enum Animation {
        static let springDamping: CGFloat = 0.7
        static let springVelocity: CGFloat = 0.5
        static let duration: TimeInterval = 0.3
        static let quickDuration: TimeInterval = 0.2
    }

    // MARK: - Button Style

    enum ButtonStyle {
        case primary
        case secondary
    }

    // MARK: - Factory Methods

    static func makePillButton(title: String, style: ButtonStyle, iconName: String? = nil) -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = Fonts.button
        button.titleLabel?.adjustsFontForContentSizeCategory = true

        if let iconName = iconName {
            let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
            button.setImage(UIImage(systemName: iconName, withConfiguration: config), for: .normal)
            button.semanticContentAttribute = .forceLeftToRight
            button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -4, bottom: 0, right: 4)
        }

        button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 24, bottom: 12, right: 24)

        switch style {
        case .primary:
            button.backgroundColor = Colors.accent
            button.tintColor = Colors.textPrimary
            button.setTitleColor(Colors.textPrimary, for: .normal)
        case .secondary:
            button.tintColor = Colors.textPrimary
            button.setTitleColor(Colors.textPrimary, for: .normal)
        }

        // Make pill-shaped after layout
        button.layer.masksToBounds = true
        button.addAction(UIAction { [weak button] _ in
            button?.layoutIfNeeded()
            button?.layer.cornerRadius = (button?.bounds.height ?? 40) / 2
        }, for: .allEvents)

        // Set initial corner radius
        button.layer.cornerRadius = 20

        return button
    }

    static func applyFrostedBackground(to button: UIButton) {
        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        blur.isUserInteractionEnabled = false
        blur.translatesAutoresizingMaskIntoConstraints = false
        blur.layer.cornerRadius = 20
        blur.clipsToBounds = true
        button.insertSubview(blur, at: 0)
        NSLayoutConstraint.activate([
            blur.topAnchor.constraint(equalTo: button.topAnchor),
            blur.leadingAnchor.constraint(equalTo: button.leadingAnchor),
            blur.trailingAnchor.constraint(equalTo: button.trailingAnchor),
            blur.bottomAnchor.constraint(equalTo: button.bottomAnchor)
        ])
        button.backgroundColor = .clear

        // Ensure the button's title and image stay above the blur view
        if let titleLabel = button.titleLabel {
            button.bringSubviewToFront(titleLabel)
        }
        if let imageView = button.imageView {
            button.bringSubviewToFront(imageView)
        }
    }

    static func makeFrostedToolbar() -> UIVisualEffectView {
        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        blur.translatesAutoresizingMaskIntoConstraints = false
        blur.layer.cornerRadius = Corner.large
        blur.clipsToBounds = true
        return blur
    }

    static func makeCardContainer() -> UIView {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = Colors.cardBackground
        view.layer.cornerRadius = Corner.card
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.3
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 8
        view.layer.masksToBounds = false
        return view
    }
}
