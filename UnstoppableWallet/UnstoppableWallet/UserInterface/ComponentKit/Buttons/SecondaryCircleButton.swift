import SnapKit
import UIKit

open class SecondaryCircleButton: UIButton {
    public static let size: CGFloat = 28

    public init() {
        super.init(frame: .zero)

        cornerRadius = Self.size / 2

        snp.makeConstraints { maker in
            maker.size.equalTo(Self.size)
        }
    }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func set(image: UIImage?, style: Style = .default) {
        switch style {
        case .default, .red:
            setBackgroundColor(.themeBlade, for: .normal)
            setBackgroundColor(.themeBlade, for: .highlighted)
            setBackgroundColor(.themeBlade, for: .disabled)
        case .transparent:
            setBackgroundColor(.clear, for: .normal)
            setBackgroundColor(.clear, for: .highlighted)
            setBackgroundColor(.clear, for: .disabled)
        }

        switch style {
        case .default:
            setImage(image?.withTintColor(.themeLeah), for: .normal)
            setImage(image?.withTintColor(.themeGray), for: .highlighted)
            setImage(image?.withTintColor(.themeAndy), for: .disabled)
            setImage(image?.withTintColor(.themeJacob), for: .selected)
            setImage(image?.withTintColor(.themeYellow50), for: [.selected, .highlighted])
        case .transparent:
            setImage(image?.withTintColor(.themeGray), for: .normal)
            setImage(image?.withTintColor(.themeGray50), for: .highlighted)
            setImage(image?.withTintColor(.themeAndy), for: .disabled)
            setImage(image?.withTintColor(.themeLeah), for: .selected)
            setImage(image?.withTintColor(.themeGray), for: [.selected, .highlighted])
        case .red:
            setImage(image?.withTintColor(.themeLucian), for: .normal)
            setImage(image?.withTintColor(.themeRed50), for: .highlighted)
            setImage(image?.withTintColor(.themeAndy), for: .disabled)
            setImage(image?.withTintColor(.themeJacob), for: .selected)
            setImage(image?.withTintColor(.themeYellow50), for: [.selected, .highlighted])
        }
    }
}

public extension SecondaryCircleButton {
    enum Style {
        case `default`
        case transparent
        case red
    }
}
