import UIKit
import ThemeKit
import SnapKit
import ComponentKit

class PasswordInputView: UIView {
    private let formValidatedView: FormValidatedView
    private let inputStackView = InputStackView(singleLine: true)

    private let secureButtonView = InputSecondaryCircleButtonWrapperView()
    private let insecureButtonView = InputSecondaryCircleButtonWrapperView()

    var onTextSecurityChange: ((Bool) -> ())?

    init() {
        formValidatedView = FormValidatedView(contentView: inputStackView, padding: UIEdgeInsets(top: 0, left: .margin16, bottom: 0, right: .margin16))

        super.init(frame: .zero)

        backgroundColor = .clear
        clipsToBounds = true

        addSubview(formValidatedView)
        formValidatedView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        secureButtonView.button.set(image: UIImage(named: "eye_2_off_24"))
        insecureButtonView.button.set(image: UIImage(named: "eye_2_24"))

        secureButtonView.onTapButton = { [weak self] in self?.onTextSecurityChange?(true) }
        insecureButtonView.onTapButton = { [weak self] in self?.onTextSecurityChange?(false) }

        inputStackView.autocapitalizationType = .none
        inputStackView.autocorrectionType = .no

        inputStackView.appendSubview(secureButtonView)
        inputStackView.appendSubview(insecureButtonView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

extension PasswordInputView {

    var inputPlaceholder: String? {
        get { inputStackView.placeholder }
        set { inputStackView.placeholder = newValue }
    }

    var inputText: String? {
        get { inputStackView.text }
        set { inputStackView.text = newValue }
    }

    var onChangeText: ((String?) -> ())? {
        get { inputStackView.onChangeText }
        set { inputStackView.onChangeText = newValue }
    }

    var isValidText: ((String) -> Bool)? {
        get { inputStackView.isValidText }
        set { inputStackView.isValidText = newValue }
    }

    func set(cautionType: CautionType?) {
        formValidatedView.set(cautionType: cautionType)
    }

    func set(textSecure: Bool) {
        secureButtonView.isHidden = textSecure
        insecureButtonView.isHidden = !textSecure
        inputStackView.isSecureTextEntry = textSecure
    }

    func height(containerWidth: CGFloat) -> CGFloat {
        formValidatedView.height(containerWidth: containerWidth)
    }

}
