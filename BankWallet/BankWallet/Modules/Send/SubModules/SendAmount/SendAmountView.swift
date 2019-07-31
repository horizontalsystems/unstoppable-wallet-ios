import UIKit
import SnapKit
import RxSwift

class SendAmountView: UIView {
    private let delegate: ISendAmountViewDelegate

    private var disposeBag = DisposeBag()

    private let holderView = UIView()

    private let amountTypeLabel = UILabel()
    private let inputField = UITextField()
    private let lineView = UIView()
    private let maxButton = RespondButton()
    private let hintLabel = UILabel()
    private let errorLabel = UILabel()
    private let switchButton = RespondButton()
    private let switchButtonIcon = UIImageView()

    public init(delegate: ISendAmountViewDelegate) {
        self.delegate = delegate
        super.init(frame: .zero)

        self.snp.makeConstraints { maker in
            maker.height.equalTo(SendTheme.amountHeight)
        }

        backgroundColor = .clear


        addSubview(holderView)

        holderView.addSubview(amountTypeLabel)
        holderView.addSubview(lineView)
        holderView.addSubview(maxButton)
        holderView.addSubview(inputField)
        holderView.addSubview(switchButton)
        holderView.addSubview(hintLabel)
        holderView.addSubview(errorLabel)
        switchButton.addSubview(switchButtonIcon)

        holderView.layer.cornerRadius = SendTheme.holderCornerRadius
        holderView.layer.borderWidth = SendTheme.holderBorderWidth
        holderView.layer.borderColor = SendTheme.holderBorderColor.cgColor
        holderView.backgroundColor = SendTheme.holderBackground
        holderView.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(SendTheme.margin)
            maker.trailing.equalToSuperview().offset(-SendTheme.margin)
            maker.top.equalToSuperview().offset(SendTheme.holderTopMargin)
            maker.bottom.equalToSuperview()
        }

        amountTypeLabel.font = SendTheme.amountFont
        amountTypeLabel.textColor = SendTheme.amountColor
        amountTypeLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        amountTypeLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(SendTheme.holderLeadingPadding)
        }

        lineView.backgroundColor = SendTheme.amountLineColor
        lineView.snp.makeConstraints { maker in
            maker.leading.equalTo(amountTypeLabel)
            maker.top.equalTo(inputField.snp.bottom).offset(SendTheme.amountLineTopMargin)
            maker.height.equalTo(SendTheme.amountLineHeight)
        }

        maxButton.titleLabel.text = "send.max_button".localized
        maxButton.borderWidth = 1 / UIScreen.main.scale
        maxButton.borderColor = SendTheme.buttonBorderColor
        maxButton.cornerRadius = SendTheme.buttonCornerRadius
        maxButton.backgrounds = SendTheme.buttonBackground
        maxButton.textColors = [.active: SendTheme.buttonIconColor, .selected: SendTheme.buttonIconColor]
        maxButton.titleLabel.font = SendTheme.buttonFont
        maxButton.titleLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        maxButton.wrapperView.snp.remakeConstraints { maker in
            maker.leading.equalToSuperview().offset(SendTheme.smallMargin)
            maker.top.bottom.equalToSuperview()
            maker.trailing.equalToSuperview().offset(-SendTheme.smallMargin)
        }
        maxButton.snp.makeConstraints { maker in //constraints need to be set on init
            maker.leading.equalTo(lineView.snp.trailing).offset(SendTheme.smallMargin)
            maker.centerY.equalToSuperview()
            maker.height.equalTo(SendTheme.buttonSize)
            maker.trailing.equalTo(switchButton.snp.leading).offset(-SendTheme.smallMargin)
        }

        inputField.delegate = self
        inputField.font = SendTheme.amountFont
        inputField.textColor = SendTheme.amountColor
        inputField.attributedPlaceholder = NSAttributedString(string: "send.amount_placeholder".localized, attributes: [NSAttributedString.Key.foregroundColor: SendTheme.amountPlaceholderColor])
        inputField.keyboardAppearance = AppTheme.keyboardAppearance
        inputField.keyboardType = .decimalPad
        inputField.tintColor = SendTheme.amountInputTintColor
        inputField.snp.makeConstraints { maker in
            maker.centerY.equalTo(amountTypeLabel.snp.centerY).offset(1 / UIScreen.main.scale)
            maker.leading.equalTo(amountTypeLabel.snp.trailing).offset(SendTheme.tinyMargin)
            maker.top.equalToSuperview().offset(SendTheme.holderTopPadding)
            maker.trailing.equalTo(lineView)
        }

        switchButton.borderWidth = 1 / UIScreen.main.scale
        switchButton.borderColor = SendTheme.buttonBorderColor
        switchButton.cornerRadius = SendTheme.buttonCornerRadius
        switchButton.backgrounds = SendTheme.buttonBackground
        switchButton.snp.makeConstraints { maker in
            maker.trailing.equalToSuperview().offset(-SendTheme.switchRightMargin)
            maker.centerY.equalToSuperview()
            maker.size.equalTo(SendTheme.buttonSize)
        }

        switchButtonIcon.image = UIImage(named: "Send Switch Icon")
        switchButtonIcon.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
        }

        hintLabel.font = SendTheme.amountHintFont
        hintLabel.textColor = SendTheme.amountHintColor
        hintLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(SendTheme.holderLeadingPadding)
            maker.top.equalTo(lineView).offset(SendTheme.amountTopMargin)
            maker.trailing.equalTo(lineView)
        }

        errorLabel.font = SendTheme.errorFont
        errorLabel.textColor = SendTheme.errorColor
        errorLabel.backgroundColor = SendTheme.holderBackground
        errorLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(SendTheme.holderLeadingPadding)
            maker.top.equalTo(lineView).offset(SendTheme.amountErrorLabelTopMargin)
            maker.trailing.equalTo(lineView)
        }

        inputField.rx.controlEvent(.editingChanged)
                .subscribe(onNext: { [weak self] _ in
                    self?.delegate.onChanged(amountText: self?.inputField.text)
                })
                .disposed(by: disposeBag)

        switchButton.onTap = { [weak self] in
            self?.delegate.onSwitchClicked()
        }
        maxButton.onTap = { [weak self] in
            self?.delegate.onMaxClicked()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        delegate.viewDidLoad()
    }
}

extension SendAmountView: ISendAmountView {

    func set(hint: String?) {
        hintLabel.text = hint
    }

    func set(error: String?) {
        errorLabel.isHidden = error == nil
        errorLabel.text = error
    }

    func set(type: String?, amount: String?) {
        amountTypeLabel.text = type
        inputField.text = amount
    }

    func set(switchButtonEnabled: Bool) {
        switchButton.state = switchButtonEnabled ? .active : .disabled
        switchButtonIcon.tintColor = switchButtonEnabled ? SendTheme.buttonIconColor : SendTheme.buttonIconColorDisabled
    }

    func maxButton(show: Bool) {
        maxButton.snp.remakeConstraints { maker in
            if show {
                maker.leading.equalTo(lineView.snp.trailing).offset(SendTheme.smallMargin)
                maker.centerY.equalToSuperview()
                maker.height.equalTo(SendTheme.buttonSize)
            } else {
                maker.leading.equalTo(lineView.snp.trailing).offset(0)
                maker.centerY.equalToSuperview()
                maker.height.equalTo(SendTheme.buttonSize)
                maker.width.equalTo(0)
            }
            maker.trailing.equalTo(switchButton.snp.leading).offset(-SendTheme.smallMargin)

            maxButton.wrapperView.snp.remakeConstraints { maker in
                if show {
                    maker.leading.equalToSuperview().offset(SendTheme.smallMargin)
                    maker.trailing.equalToSuperview().offset(-SendTheme.smallMargin)
                } else {
                    maker.leading.equalToSuperview().offset(0)
                }
                maker.top.bottom.equalToSuperview()
            }
        }

    }

    func showKeyboard() {
        DispatchQueue.main.async {
            self.inputField.becomeFirstResponder()
        }
    }

}

extension SendAmountView: UITextFieldDelegate {

    private func validate(text: String) -> Bool {
        if delegate.validateInputText(text: text) {
            return true
        } else {
            inputField.shakeView()
            return false
        }
    }

    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let text = inputField.text, let textRange = Range(range, in: text) {
            let text = text.replacingCharacters(in: textRange, with: string)
            guard !text.isEmpty else {
                return true
            }
            return validate(text: text)
        }
        return validate(text: string)
    }

}
