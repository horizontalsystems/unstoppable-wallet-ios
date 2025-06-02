import SnapKit
import ThemeKit
import UIKit

open class SecondaryButton: UIButton {
    public init() {
        super.init(frame: .zero)

        layer.cornerCurve = .continuous
        semanticContentAttribute = .forceRightToLeft

        setContentCompressionResistancePriority(.required, for: .horizontal)
        setContentHuggingPriority(.required, for: .horizontal)

        snp.makeConstraints { maker in
            maker.height.equalTo(Self.height(style: .default))
        }
    }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func set(style: Style, image: UIImage? = nil) {
        let height = Self.height(style: style)

        snp.updateConstraints { maker in
            maker.height.equalTo(height)
        }

        switch style {
        case .default, .transparent, .tab: cornerRadius = height / 2
        case .transparent2: cornerRadius = 0
        }

        titleLabel?.font = Self.font(style: style)

        switch style {
        case .default:
            setBackgroundColor(.themeSteel20, for: .normal)
            setBackgroundColor(.themeSteel10, for: .highlighted)
            setBackgroundColor(.themeSteel20, for: .disabled)
            setBackgroundColor(.themeYellowD, for: .selected)
            setBackgroundColor(.themeYellow50, for: [.selected, .highlighted])
        case .transparent:
            setBackgroundColor(.clear, for: .normal)
            setBackgroundColor(.clear, for: .highlighted)
            setBackgroundColor(.clear, for: .disabled)
            setBackgroundColor(.themeYellowD, for: .selected)
            setBackgroundColor(.themeYellow50, for: [.selected, .highlighted])
        case .transparent2, .tab:
            setBackgroundColor(.clear, for: .normal)
            setBackgroundColor(.clear, for: .highlighted)
            setBackgroundColor(.clear, for: .disabled)
            setBackgroundColor(.clear, for: .selected)
            setBackgroundColor(.clear, for: [.selected, .highlighted])
        }

        switch style {
        case .default, .transparent:
            setTitleColor(.themeLeah, for: .normal)
            setTitleColor(.themeGray, for: .highlighted)
            setTitleColor(.themeGray50, for: .disabled)
            setTitleColor(.themeDark, for: .selected)
            setTitleColor(.themeDark, for: [.selected, .highlighted])
        case .transparent2:
            setTitleColor(.themeGray, for: .normal)
            setTitleColor(.themeGray50, for: .highlighted)
            setTitleColor(.themeGray50, for: .disabled)
            setTitleColor(.themeLeah, for: .selected)
            setTitleColor(.themeGray, for: [.selected, .highlighted])
        case .tab:
            setTitleColor(.themeGray, for: .normal)
            setTitleColor(.themeGray, for: .highlighted)
            setTitleColor(.themeGray50, for: .disabled)
            setTitleColor(.themeLeah, for: .selected)
            setTitleColor(.themeLeah, for: [.selected, .highlighted])
        }

        let leftPadding = Self.leftPadding(style: style)
        let rightPadding = Self.rightPadding(style: style, hasImage: image != nil)
        let imagePadding = Self.imagePadding(style: style)

        if let image {
            switch style {
            case .default, .transparent, .tab:
                setImage(image.withTintColor(.themeGray), for: .normal)
                setImage(image.withTintColor(.themeGray), for: .highlighted)
                setImage(image.withTintColor(.themeGray50), for: .disabled)
                setImage(image.withTintColor(.themeDark), for: .selected)
                setImage(image.withTintColor(.themeDark), for: [.selected, .highlighted])
            case .transparent2:
                setImage(image.withTintColor(.themeGray), for: .normal)
                setImage(image.withTintColor(.themeGray50), for: .highlighted)
                setImage(image.withTintColor(.themeGray50), for: .disabled)
                setImage(image.withTintColor(.themeGray), for: .selected)
                setImage(image.withTintColor(.themeGray50), for: [.selected, .highlighted])
            }

            let verticalPadding = (height - CGFloat.iconSize20) / 2
            titleEdgeInsets = UIEdgeInsets(top: 0, left: -imagePadding, bottom: 0, right: imagePadding)
            contentEdgeInsets = UIEdgeInsets(top: verticalPadding, left: leftPadding + imagePadding, bottom: verticalPadding, right: rightPadding)
        } else {
            titleEdgeInsets = .zero
            contentEdgeInsets = UIEdgeInsets(top: 0, left: leftPadding, bottom: 0, right: rightPadding)
        }
    }

    public enum Style {
        case `default`
        case transparent
        case transparent2
        case tab
    }
}

extension SecondaryButton {
    private static func font(style: Style) -> UIFont {
        switch style {
        case .default, .transparent: return .captionSB
        case .tab: return .subhead1
        case .transparent2: return .subhead2
        }
    }

    private static func leftPadding(style: Style) -> CGFloat {
        switch style {
        case .default, .transparent, .tab: return .margin16
        case .transparent2: return 0
        }
    }

    private static func rightPadding(style: Style, hasImage: Bool) -> CGFloat {
        switch style {
        case .default, .transparent: return hasImage ? .margin8 : .margin16
        case .tab: return .margin16
        case .transparent2: return 0
        }
    }

    private static func imagePadding(style: Style) -> CGFloat {
        switch style {
        case .default, .transparent, .tab: return .margin2
        case .transparent2: return .margin8
        }
    }

    public static func height(style: Style) -> CGFloat {
        switch style {
        case .default, .transparent, .tab: return 28
        case .transparent2: return 20
        }
    }

    public static func width(title: String, style: Style, hasImage: Bool) -> CGFloat {
        var width = title.size(containerWidth: .greatestFiniteMagnitude, font: font(style: style)).width

        if hasImage {
            width += CGFloat.iconSize20 + imagePadding(style: style)
        }

        return width + leftPadding(style: style) + rightPadding(style: style, hasImage: hasImage)
    }
}
