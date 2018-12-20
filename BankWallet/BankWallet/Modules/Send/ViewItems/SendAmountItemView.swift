import UIKit
import GrouviExtensions
import GrouviActionSheet
import SnapKit
import RxSwift
import RxCocoa

class AmountTextField: UITextField {

    override func paste(_ sender: Any?) {
        text = ValueFormatter.instance.formattedInput(string: UIPasteboard.general.string)
        sendActions(for: .editingChanged)
    }

}

class SendAmountItemView: BaseActionItemView {
    private let disposeBag = DisposeBag()

    private let amountTypeLabel = UILabel()
    private let inputField = AmountTextField()
    private let lineView = UIView()
    private let hintLabel = UILabel()
    private let errorLabel = UILabel()
    private let switchButton = RespondButton()
    private let switchButtonIcon = UIImageView()

    override var item: SendAmountItem? { return _item as? SendAmountItem }

    override func initView() {
        super.initView()

        backgroundColor = SendTheme.itemBackground

        addSubview(amountTypeLabel)
        addSubview(lineView)
        addSubview(inputField)
        addSubview(switchButton)
        addSubview(hintLabel)
        addSubview(errorLabel)
        switchButton.addSubview(switchButtonIcon)

        amountTypeLabel.font = SendTheme.amountFont
        amountTypeLabel.textColor = SendTheme.amountColor
        amountTypeLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        amountTypeLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(SendTheme.margin)
        }

        lineView.backgroundColor = SendTheme.amountLineColor
        lineView.snp.makeConstraints { maker in
            maker.leading.equalTo(amountTypeLabel)
            maker.top.equalTo(inputField.snp.bottom).offset(SendTheme.amountLineTopMargin)
            maker.height.equalTo(SendTheme.amountLineHeight)
        }

        inputField.delegate = self
        inputField.font = SendTheme.amountFont
        inputField.textColor = SendTheme.amountColor
        inputField.attributedPlaceholder = NSAttributedString(string: "send.amount_placeholder".localized, attributes: [NSAttributedStringKey.foregroundColor: SendTheme.amountPlaceholderColor])
        inputField.keyboardAppearance = AppTheme.keyboardAppearance
        inputField.keyboardType = .decimalPad
        inputField.tintColor = SendTheme.amountInputTintColor
        inputField.snp.makeConstraints { maker in
            maker.centerY.equalTo(amountTypeLabel.snp.centerY)
            maker.leading.equalTo(amountTypeLabel.snp.trailing).offset(SendTheme.smallMargin)
            maker.top.equalToSuperview().offset(SendTheme.margin)
            maker.trailing.equalTo(lineView)
        }

        switchButton.borderWidth = 1 / UIScreen.main.scale
        switchButton.borderColor = SendTheme.buttonBorderColor
        switchButton.cornerRadius = SendTheme.buttonCornerRadius
        switchButton.backgrounds = SendTheme.buttonBackground
        switchButton.snp.makeConstraints { maker in
            maker.trailing.equalToSuperview().offset(-SendTheme.margin)
            maker.centerY.equalTo(lineView.snp.centerY)
            maker.leading.equalTo(lineView.snp.trailing).offset(SendTheme.margin)
            maker.size.equalTo(SendTheme.buttonSize)
        }

        switchButtonIcon.image = UIImage(named: "Send Switch Icon")
        switchButtonIcon.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
        }

        hintLabel.font = SendTheme.amountHintFont
        hintLabel.textColor = SendTheme.amountHintColor
        hintLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(SendTheme.margin)
            maker.top.equalTo(lineView).offset(SendTheme.smallMargin)
            maker.trailing.equalTo(lineView)
        }

        errorLabel.font = SendTheme.errorFont
        errorLabel.textColor = SendTheme.errorColor
        errorLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(SendTheme.margin)
            maker.top.equalTo(lineView).offset(SendTheme.smallMargin)
            maker.trailing.equalTo(lineView)
        }

        inputField.rx.controlEvent(.editingChanged)
                .subscribe(onNext: { [weak self] _ in
                    var amount: Double = 0
                    if let updatedString = ValueFormatter.instance.formattedInput(string: self?.inputField.text), let parsedAmount = ValueFormatter.instance.parseFormatter.number(from: updatedString) as? Double {
                        amount = parsedAmount
                    }
                    self?.item?.onAmountChanged?(amount)
                })
                .disposed(by: disposeBag)
        switchButton.onTap = item?.onSwitchClicked

        item?.showKeyboard = { [weak self] in
            DispatchQueue.main.async {
                self?.inputField.becomeFirstResponder()
            }
        }

        item?.bindAmountType = { [weak self] in
            self?.amountTypeLabel.text = $0
        }
        item?.bindAmount = { [weak self] in
            self?.inputField.text = $0.flatMap { $0 == 0 ? nil : ValueFormatter.instance.format(amount: $0)}
        }
        item?.bindHint = { [weak self] in
            self?.hintLabel.text = $0
        }
        item?.bindError = { [weak self] in
            self?.errorLabel.text = $0
        }
        item?.bindSwitchEnabled = { [weak self] enabled in
            self?.switchButton.state = enabled ? .active : .disabled
            self?.switchButtonIcon.tintColor = enabled ? SendTheme.buttonIconColor : SendTheme.buttonIconColorDisabled
        }
    }

}

extension SendAmountItemView: UITextFieldDelegate {

    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let updatedString = (textField.text as NSString?)?.replacingCharacters(in: range, with: string)

        if let updatedString = ValueFormatter.instance.formattedInput(string: updatedString) {
            return updatedString.isEmpty || ValueFormatter.instance.parseFormatter.number(from: updatedString) as? Double != nil
        }

        return false
    }

}
