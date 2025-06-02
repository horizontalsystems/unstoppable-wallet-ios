import SnapKit
import ThemeKit
import UIKit

open class PrimaryCircleButton: UIButton {
    public static let size: CGFloat = .heightButton

    private var style: Style?

    public init() {
        super.init(frame: .zero)

        cornerRadius = Self.size / 2

        setBackgroundColor(.themeSteel20, for: .disabled)

        snp.makeConstraints { maker in
            maker.size.equalTo(Self.size)
        }
    }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func set(image: UIImage?) {
        if let style, case .yellow = style {
            setImage(image?.withTintColor(.themeDark), for: .normal)
            setImage(image?.withTintColor(.themeDark), for: .highlighted)
        } else {
            setImage(image?.withTintColor(.themeClaude), for: .normal)
            setImage(image?.withTintColor(.themeClaude), for: .highlighted)
        }
        setImage(image?.withTintColor(.themeSteel20), for: .disabled)
    }

    public func set(style: Style) {
        self.style = style

        switch style {
        case .yellow:
            setImage(imageView?.image?.withTintColor(.themeDark), for: .normal)
            setBackgroundColor(.themeYellowD, for: .normal)
            setBackgroundColor(.themeYellow50, for: .highlighted)
        case .red:
            setBackgroundColor(.themeLucian, for: .normal)
            setBackgroundColor(.themeRed50, for: .highlighted)
        case .gray:
            setBackgroundColor(.themeLeah, for: .normal)
            setBackgroundColor(.themeNina, for: .highlighted)
        }
    }

    public enum Style {
        case yellow
        case red
        case gray
    }
}
