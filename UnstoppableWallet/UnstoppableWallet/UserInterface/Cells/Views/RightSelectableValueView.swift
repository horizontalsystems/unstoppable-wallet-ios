import UIKit
import SnapKit

class RightSelectableValueView: UIView {

    private let button = UIButton()
    public var action: (() -> ())?

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(button)
        button.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        button.semanticContentAttribute = .forceRightToLeft
        button.setImage(UIImage(named: "Down")?.tinted(with: .themeGray), for: .normal)
        button.setTitleColor(.themeLeah, for: .normal)
        button.titleLabel?.font = UIFont.subhead1
        button.addTarget(self, action: #selector(onTap), for: .touchUpInside)
        button.contentEdgeInsets = UIEdgeInsets(top: .zero, left: .margin4x, bottom: .zero, right: .margin4x)
        button.imageEdgeInsets = UIEdgeInsets(top: .zero, left: .margin2x, bottom: .zero, right: .zero)

        button.setContentHuggingPriority(.required, for: .horizontal)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)

    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    @objc private func onTap() {
        action?()
    }

    public func set(title: String?) {
        button.setTitle(title, for: .normal)
    }

    public func set(titleColor: UIColor?) {
        button.setTitleColor(titleColor, for: .normal)
    }

}
