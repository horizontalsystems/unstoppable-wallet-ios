import UIKit

class SelectionButton: UIButton {
    private static let titleRightMargin = CGFloat.margin8

    override var contentEdgeInsets: UIEdgeInsets {
        get {
            super.contentEdgeInsets.add(UIEdgeInsets(top: 0, left: -Self.titleRightMargin, bottom: 0, right: 0))
        }
        set {
            super.contentEdgeInsets = newValue.add(UIEdgeInsets(top: 0, left: Self.titleRightMargin, bottom: 0, right: 0))
        }
    }

    public var action: (() -> ())?

    init() {
        super.init(frame: .zero)

        setContentHuggingPriority(.required, for: .horizontal)
        setContentCompressionResistancePriority(.required, for: .horizontal)

        semanticContentAttribute = .forceRightToLeft
        setImage(UIImage(named: "arrow_small_down_20"), for: .normal)
        setTitleColor(.themeLeah, for: .normal)
        titleLabel?.font = UIFont.subhead1
        addTarget(self, action: #selector(onTapTokenSelect), for: .touchUpInside)

        titleEdgeInsets = UIEdgeInsets(top: 0, left: -Self.titleRightMargin, bottom: 0, right: Self.titleRightMargin)
        contentEdgeInsets = UIEdgeInsets(top: 0, left: .margin16, bottom: 0, right: .margin16)
    }

    required init?(coder: Foundation.NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func onTapTokenSelect() {
        action?()
    }

}

extension SelectionButton {

    public func setTitle(color: UIColor) {
        setTitleColor(color, for: .normal)
    }

    public func set(title: String?) {
        setTitle(title, for: .normal)
    }

}
