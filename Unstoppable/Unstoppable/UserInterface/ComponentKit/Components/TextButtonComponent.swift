import SnapKit
import UIKit

public class TextButtonComponent: UIButton {
    public var onTap: (() -> Void)?

    public init() {
        super.init(frame: .zero)

        addTarget(self, action: #selector(_onTap), for: .touchUpInside)
    }

    @available(*, unavailable)
    public required init(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public var intrinsicContentSize: CGSize {
        titleLabel?.intrinsicContentSize ?? super.intrinsicContentSize
    }

    @objc private func _onTap() {
        onTap?()
    }

    public var font: UIFont? {
        get { titleLabel?.font }
        set { titleLabel?.font = newValue }
    }

    public var textColor: UIColor? {
        get { titleColor(for: .normal) }
        set { setTitleColor(newValue, for: .normal) }
    }

    public var text: String? {
        get { title(for: .normal) }
        set { setTitle(newValue, for: .normal) }
    }
}

public extension TextButtonComponent {
    static func height(width: CGFloat, font: UIFont, text: String) -> CGFloat {
        text.height(forContainerWidth: width, font: font)
    }

    static func width(font: UIFont, text: String) -> CGFloat {
        text.size(containerWidth: CGFloat.greatestFiniteMagnitude, font: font).width
    }
}
