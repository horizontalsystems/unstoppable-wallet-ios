import SwiftUI
import UIKit

class HighlightedDescriptionBaseView: UIView {
    static let font: UIFont = .subhead2
    static let sidePadding: CGFloat = .margin16
    static let verticalPadding: CGFloat = .margin12

    let label = UILabel()

    public init() {
        super.init(frame: .zero)

        backgroundColor = .themeYellow20
        borderColor = .themeYellowD
        borderWidth = 1
        cornerRadius = .cornerRadius12
        layer.cornerCurve = .continuous

        label.setContentHuggingPriority(.required, for: .vertical)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
    }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(style: Style) {
        switch style {
        case .yellow:
            backgroundColor = .themeYellow20
            borderColor = .themeYellowD
        case .red:
            backgroundColor = UIColor(hex: 0xFF4820, alpha: 0.2)
            borderColor = .themeLucian
        }
    }

    var text: String? {
        get { label.text }
        set { label.text = newValue }
    }
}

extension HighlightedDescriptionBaseView {
    enum Style: String {
        case yellow
        case red

        var accentColor: Color {
            switch self {
            case .yellow: return .themeJacob
            case .red: return .themeLucian
            }
        }
    }
}
