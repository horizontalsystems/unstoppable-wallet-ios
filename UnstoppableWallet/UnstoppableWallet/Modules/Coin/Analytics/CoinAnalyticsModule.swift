import MarketKit
import SwiftUI
import ThemeKit
import UIKit

enum Previewable<T> {
    case preview
    case regular(value: T)

    var isPreview: Bool {
        switch self {
        case .preview: return true
        case .regular: return false
        }
    }

    func previewableValue<P>(mapper: (T) -> P) -> Previewable<P> {
        switch self {
        case .preview: return .preview
        case let .regular(value): return .regular(value: mapper(value))
        }
    }

    func value<P>(mapper: (T) -> P) -> P? {
        switch self {
        case .preview: return nil
        case let .regular(value): return mapper(value)
        }
    }
}

enum CoinAnalyticsModule {
    enum Rating: String, CaseIterable, Identifiable {
        case excellent
        case good
        case fair
        case poor

        var id: Self {
            self
        }

        var title: String {
            "coin_analytics.overall_score.\(rawValue)".localized
        }

        var image: UIImage? {
            UIImage(named: "rating_\(rawValue)_24")
        }

        var imageNew: Image? {
            Image("rating_\(rawValue)_24")
        }

        var color: UIColor {
            switch self {
            case .excellent: return .themeGreenD
            case .good: return .themeYellowD
            case .fair: return UIColor(hex: 0xFF7A00)
            case .poor: return .themeRedD
            }
        }

        var colorNew: Color {
            switch self {
            case .excellent: return .themeGreen
            case .good: return .themeYellow
            case .fair: return Color(hex: 0xFF7A00)
            case .poor: return .themeRed
            }
        }
    }
}
