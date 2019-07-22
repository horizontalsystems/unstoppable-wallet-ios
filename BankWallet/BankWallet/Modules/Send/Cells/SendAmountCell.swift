import UIKit
import RxSwift

//class AmountTextField: UITextField {
//    var onPaste: (() -> ())?
//
//    override func paste(_ sender: Any?) {
//        onPaste?()
//    }
//
//}

class SendAmountCell: UITableViewCell {
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

    private var item: AmountItem?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none

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
        errorLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(SendTheme.holderLeadingPadding)
            maker.top.equalTo(lineView).offset(SendTheme.amountErrorLabelTopMargin)
            maker.trailing.equalTo(lineView)
        }

//        inputField.onPaste = { [weak self] in
//            self?.item?.delegate?.onPasteClicked()
//        }

        inputField.rx.controlEvent(.editingChanged)
                .subscribe(onNext: { [weak self] _ in
                    self?.updateUI()

                    let amount: Decimal = ValueFormatter.instance.parseAnyDecimal(from: self?.inputField.text) ?? 0
                    self?.item?.delegate?.onChanged(amount: amount)
                })
                .disposed(by: disposeBag)

        switchButton.onTap = { [weak self] in
            self?.item?.delegate?.onSwitchClicked()
        }
        maxButton.onTap = { [weak self] in
            self?.item?.delegate?.onMaxClicked()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }


    func bind(item: AmountItem) {
        self.item = item
        item.bind = { [weak self] in
            self?.bind()
        }
        item.bindHint = { [weak self] in
            self?.set(hintInfo: self?.item?.hintInfo)
        }
        item.bindAmount = { [weak self] in
            self?.set(amountInfo: self?.item?.amountInfo)
        }
        item.bindSwitchButtonEnabled = { [weak self] in
            self?.set(switchButtonEnabled: self?.item?.switchButtonEnabled ?? false)
        }
        item.showKeyboard = { [weak self] in
            self?.showKeyboard()
        }

        bind()
    }

    private func updateUI() {
        let text = inputField.text ?? ""
        maxButton.snp.remakeConstraints { maker in
            if text.count == 0 {
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
                if text.count == 0 {
                    maker.leading.equalToSuperview().offset(SendTheme.smallMargin)
                    maker.trailing.equalToSuperview().offset(-SendTheme.smallMargin)
                } else {
                    maker.leading.equalToSuperview().offset(0)
                }
                maker.top.bottom.equalToSuperview()
            }
        }
    }

    private func bind(amount: Decimal?) {
        let amount = amount ?? 0
        let formattedAmount = ValueFormatter.instance.format(amount: amount)
        inputField.text = amount == 0 ? nil : formattedAmount
//        inputField.sendActions(for: .editingChanged)
    }

    private func set(hintInfo: HintInfo?) {
        hintLabel.text = nil
        errorLabel.text = nil

        if let hintInfo = hintInfo {
            switch hintInfo {
            case .amount(let amountInfo):
                switch amountInfo {
                case .coinValue(let coinValue):
                    hintLabel.text = ValueFormatter.instance.format(coinValue: coinValue)
                case .currencyValue(let currencyValue):
                    hintLabel.text = ValueFormatter.instance.format(currencyValue: currencyValue)
                }
            case .error(let error):
                switch error {
                case .coinValue(let coinValue):
                    errorLabel.text = "send.amount_error.balance".localized(ValueFormatter.instance.format(coinValue: coinValue) ?? "")
                case .currencyValue(let currencyValue):
                    errorLabel.text = "send.amount_error.balance".localized(ValueFormatter.instance.format(currencyValue: currencyValue) ?? "")
                }
            }
        }
    }

    private func set(amountInfo: AmountInfo?) {
        guard let amountInfo = amountInfo else {
            amountTypeLabel.text = nil
            bind(amount: nil)
            return
        }

        switch amountInfo {
        case .coinValue(let coinValue):
            amountTypeLabel.text = coinValue.coinCode
            bind(amount: coinValue.value)
        case .currencyValue(let currencyValue):
            amountTypeLabel.text = currencyValue.currency.symbol
            bind(amount: currencyValue.value)
        }
    }

    private func set(switchButtonEnabled: Bool) {
        switchButton.state = switchButtonEnabled ? .active : .disabled
        switchButtonIcon.tintColor = switchButtonEnabled ? SendTheme.buttonIconColor : SendTheme.buttonIconColorDisabled
    }

    private func bind() {
        set(amountInfo: item?.amountInfo)
        set(switchButtonEnabled: item?.switchButtonEnabled ?? false)
        set(hintInfo: item?.hintInfo)
    }

}

extension SendAmountCell: UITextFieldDelegate {

    private func validate(text: String) -> Bool {
        if let value = ValueFormatter.instance.parseAnyDecimal(from: text), value.decimalCount <= (item?.decimal ?? 0) {
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

extension SendAmountCell: ISendAmountListener {


    func showKeyboard() {
        DispatchQueue.main.async {
            self.inputField.becomeFirstResponder()
        }
    }

}