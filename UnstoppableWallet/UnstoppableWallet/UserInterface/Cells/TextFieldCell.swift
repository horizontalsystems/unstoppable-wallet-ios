import UIKit
import ThemeKit
import SnapKit

class TextFieldCell: UITableViewCell {
    private let wrapperView = UIView()
    private let stackView = TextFieldStackView()

    init() {
        super.init(style: .default, reuseIdentifier: nil)

        backgroundColor = .clear
        selectionStyle = .none
        clipsToBounds = true

        wrapperView.backgroundColor = .themeLawrence
        wrapperView.layer.cornerRadius = .cornerRadius8
        wrapperView.layer.cornerCurve = .continuous
        wrapperView.layer.borderWidth = .heightOneDp
        wrapperView.layer.borderColor = UIColor.themeSteel20.cgColor

        contentView.addSubview(wrapperView)
        wrapperView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin16)
            maker.top.equalToSuperview()
            maker.height.equalTo(CGFloat.heightSingleLineCell)
        }

        wrapperView.addSubview(stackView)
        stackView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func becomeFirstResponder() -> Bool {
        stackView.becomeFirstResponder()
    }

    func prependSubview(_ view: UIView, customSpacing: CGFloat? = nil) {
        stackView.prependSubview(view, customSpacing: customSpacing)
    }

}

extension TextFieldCell {

    var inputPlaceholder: String? {
        get { stackView.placeholder }
        set { stackView.placeholder = newValue }
    }

    var inputText: String? {
        get { stackView.text }
        set { stackView.text = newValue }
    }

    var keyboardType: UIKeyboardType {
        get { stackView.keyboardType }
        set { stackView.keyboardType = newValue }
    }

    var autocapitalizationType: UITextAutocapitalizationType {
        get { stackView.autocapitalizationType }
        set { stackView.autocapitalizationType = newValue }
    }

    var returnKeyType: UIReturnKeyType {
        get { stackView.returnKeyType }
        set { stackView.returnKeyType = newValue }
    }

    var isSecureTextEntry: Bool {
        get { stackView.isSecureTextEntry }
        set { stackView.isSecureTextEntry = newValue }
    }

    func set(cautionType: CautionType?) {
        let borderColor: UIColor

        if let cautionType = cautionType {
            borderColor = cautionType.borderColor
        } else {
            borderColor = .themeSteel20
        }

        wrapperView.layer.borderColor = borderColor.cgColor
    }

    var onChangeText: ((String?) -> ())? {
        get { stackView.onChangeText }
        set { stackView.onChangeText = newValue }
    }

    var onReturn: (() -> ())? {
        get { stackView.onReturn }
        set { stackView.onReturn = newValue }
    }

    var isValidText: ((String?) -> Bool)? {
        get { stackView.isValidText }
        set { stackView.isValidText = newValue }
    }

}
