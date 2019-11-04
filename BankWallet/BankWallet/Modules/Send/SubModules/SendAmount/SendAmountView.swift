import UIKit
import SnapKit
import RxSwift

class SendAmountView: UIView {
    private let delegate: ISendAmountViewDelegate

    private var disposeBag = DisposeBag()

    private let holderView = UIView()

    private let availableBalanceTitleLabel = UILabel()
    private let availableBalanceValueLabel = UILabel()
    private let amountTypeLabel = UILabel()
    private let inputField = UITextField()
    private let lineView = UIView()
    private let maxButton = RespondButton()
    private let hintLabel = UILabel()
    private let errorLabel = UILabel()
    private let switchButton = RespondButton()
    private let switchButtonIcon = UIImageView()

    private let decimalFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ""
        return formatter
    }()

    public init(delegate: ISendAmountViewDelegate) {
        self.delegate = delegate
        super.init(frame: .zero)

        self.snp.makeConstraints { maker in
            maker.height.equalTo(SendTheme.amountHeight)
        }

        backgroundColor = .clear

        addSubview(availableBalanceTitleLabel)
        availableBalanceTitleLabel.text = "send.available_balance".localized
        availableBalanceTitleLabel.font = SendTheme.availableAmountTitleFont
        availableBalanceTitleLabel.textColor = SendTheme.availableAmountTitleColor
        availableBalanceTitleLabel.snp.makeConstraints { maker in
            maker.top.equalToSuperview().offset(CGFloat.margin2x)
            maker.leading.equalToSuperview().offset(SendTheme.margin)
        }
        
        addSubview(availableBalanceValueLabel)
        availableBalanceValueLabel.font = SendTheme.availableAmountValueFont
        availableBalanceValueLabel.textColor = SendTheme.availableAmountValueColor
        availableBalanceValueLabel.snp.makeConstraints { maker in
            maker.centerY.equalTo(availableBalanceTitleLabel.snp.centerY)
            maker.trailing.equalToSuperview().offset(-SendTheme.margin)
        }

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
            maker.height.equalTo(SendTheme.amountHolderHeight)
            maker.top.equalTo(availableBalanceTitleLabel.snp.bottom).offset(CGFloat.margin3x)
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
        inputField.keyboardAppearance = App.theme.keyboardAppearance
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

    private func format(coinValue: CoinValue) -> String? {
        decimalFormatter.maximumFractionDigits = min(coinValue.coin.decimal, 8)
        return decimalFormatter.string(from: coinValue.value as NSNumber)
    }

    private func format(currencyValue: CurrencyValue) -> String? {
        decimalFormatter.maximumFractionDigits = currencyValue.currency.decimal
        return decimalFormatter.string(from: currencyValue.value as NSNumber)
    }

}

extension SendAmountView: ISendAmountView {

    func set(amountType: String) {
        amountTypeLabel.text = amountType
    }

    func set(amount: AmountInfo?) {
        guard let amount = amount else {
            inputField.text = nil
            return
        }

        switch amount {
        case .coinValue(let coinValue):
            inputField.text = format(coinValue: coinValue)
        case .currencyValue(let currencyValue):
            inputField.text = format(currencyValue: currencyValue)
        }
    }

    func set(availableBalance: AmountInfo?) {
        guard let availableBalance = availableBalance else {
            availableBalanceValueLabel.text = nil
            return
        }

        switch availableBalance {
        case .coinValue(let coinValue):
            availableBalanceValueLabel.text = ValueFormatter.instance.format(coinValue: coinValue)
        case .currencyValue(let currencyValue):
            availableBalanceValueLabel.text = ValueFormatter.instance.format(currencyValue: currencyValue)
        }
    }

    func set(hint: AmountInfo?) {
        hintLabel.text = hint?.formattedString
    }

    func set(error: Error?) {
        errorLabel.isHidden = error == nil
        errorLabel.text = error?.localizedDescription
    }

    func set(switchButtonEnabled: Bool) {
        switchButton.state = switchButtonEnabled ? .active : .disabled
        switchButtonIcon.tintColor = switchButtonEnabled ? SendTheme.buttonIconColor : SendTheme.buttonIconColorDisabled
    }

    func set(maxButtonVisible: Bool) {
        maxButton.snp.remakeConstraints { maker in
            if maxButtonVisible {
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
                if maxButtonVisible {
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
        if delegate.isValid(text: text) {
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
