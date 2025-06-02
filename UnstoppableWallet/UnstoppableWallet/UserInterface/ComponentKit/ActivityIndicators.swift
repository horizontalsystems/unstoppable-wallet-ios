import HUD
import ThemeKit
import UIKit

public enum ActivityIndicatorStyle {
    case small20
    case medium24
    case large48

    var dashHeight: CGFloat {
        switch self {
        case .small20:
            return 4
        case .medium24:
            return 5
        case .large48:
            return 10
        }
    }

    var dashStrokeWidth: CGFloat {
        switch self {
        case .small20:
            return 1 + .heightOnePixel
        case .medium24:
            return 2
        case .large48:
            return 4
        }
    }

    var radius: CGFloat {
        switch self {
        case .small20:
            return 8
        case .medium24:
            return 10
        case .large48:
            return 20
        }
    }

    var edgeInsets: UIEdgeInsets {
        switch self {
        case .small20:
            return UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
        case .medium24:
            return UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
        case .large48:
            return UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
        }
    }

    var size: CGFloat {
        switch self {
        case .small20:
            return 20
        case .medium24:
            return 24
        case .large48:
            return 48
        }
    }
}

public extension HUDActivityView {
    static func create(with style: ActivityIndicatorStyle) -> HUDActivityView {
        let activityView = HUDActivityView(
            dashHeight: style.dashHeight,
            dashStrokeWidth: style.dashStrokeWidth,
            radius: style.radius,
            strokeColor: .gray,
            duration: 0.834
        )
        activityView.edgeInsets = style.edgeInsets

        activityView.snp.makeConstraints { maker in
            maker.size.equalTo(style.size)
        }

        return activityView
    }
}
