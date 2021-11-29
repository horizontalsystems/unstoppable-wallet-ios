import UIKit
import SnapKit
import ThemeKit
import ComponentKit

class FormField: UIView {
    private let label = UILabel()
    private let copyButton = ThemeButton()

    var onTapCopy: (() -> ())?

    init() {
        super.init(frame: .zero)

        backgroundColor = .themeLawrence
        layer.cornerRadius = .cornerRadius2x
        layer.borderWidth = 1
        layer.borderColor = UIColor.themeSteel20.cgColor

        addSubview(label)
        label.snp.makeConstraints { maker in
            maker.leading.top.bottom.equalToSuperview().inset(CGFloat.margin3x)
        }

        label.lineBreakMode = .byTruncatingMiddle
        label.font = .body
        label.textColor = .themeOz

        addSubview(copyButton)
        copyButton.snp.makeConstraints { maker in
            maker.leading.equalTo(label.snp.trailing).offset(CGFloat.margin3x)
            maker.trailing.equalToSuperview().inset(CGFloat.margin2x)
            maker.centerY.equalToSuperview()
        }

        copyButton.apply(style: .secondaryIcon)
        copyButton.setImage(UIImage(named: "copy_20"), for: .normal)
        copyButton.addTarget(self, action: #selector(_onTapCopy), for: .touchUpInside)
    }

    @objc private func _onTapCopy() {
        onTapCopy?()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var text: String? {
        get {
            label.text
        }
        set {
            label.text = newValue
        }
    }

}
