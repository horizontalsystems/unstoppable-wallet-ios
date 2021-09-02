import UIKit
import SnapKit
import RxSwift
import HUD
import CurrencyKit
import ThemeKit

class SendAmountView: UIView {
    private let delegate: ISendAmountViewDelegate

    private var disposeBag = DisposeBag()

    private let availableAmountTitleLabel = UILabel()
    private let availableAmountValueLabel = UILabel()
    private let spinner = HUDActivityView.create(with: .small20)

    private let amountInput = AmountInputView()
    private let amountInputWrapper: FormValidatedView
    private let cautionView = FormCautionView()

    private let decimalFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ""
        return formatter
    }()

    public init(delegate: ISendAmountViewDelegate) {
        self.delegate = delegate
        amountInputWrapper = FormValidatedView(contentView: amountInput)

        super.init(frame: .zero)

        backgroundColor = .clear

        addSubview(availableAmountTitleLabel)
        availableAmountTitleLabel.text = "send.available_balance".localized
        availableAmountTitleLabel.font = .subhead2
        availableAmountTitleLabel.textColor = .themeGray
        availableAmountTitleLabel.snp.makeConstraints { maker in
            maker.top.equalToSuperview().offset(CGFloat.margin2x)
            maker.leading.equalToSuperview().offset(CGFloat.margin4x)
        }

        addSubview(availableAmountValueLabel)
        availableAmountValueLabel.font = .subhead1

        availableAmountValueLabel.textColor = .themeOz
        availableAmountValueLabel.snp.makeConstraints { maker in
            maker.centerY.equalTo(availableAmountTitleLabel.snp.centerY)
            maker.trailing.equalToSuperview().inset(CGFloat.margin4x)
        }

        addSubview(spinner)
        spinner.snp.makeConstraints { maker in
            maker.centerY.equalTo(availableAmountTitleLabel.snp.centerY)
            maker.trailing.equalToSuperview().inset(CGFloat.margin4x)
        }
        spinner.isHidden = true

        addSubview(amountInputWrapper)
        amountInputWrapper.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(availableAmountTitleLabel.snp.bottom).offset(CGFloat.margin3x)
            maker.height.equalTo(amountInput.viewHeight)
        }

        amountInput.inputPlaceholder = "0"

        amountInput.isValidText = { [weak self] text in
            self?.delegate.isValid(text: text) ?? true
        }
        amountInput.onChangeText = { [weak self] text in
            self?.delegate.willChangeAmount(text: text)
            self?.delegate.didChangeAmount()
        }
        amountInput.onTapMax = { [weak self] in
            self?.delegate.onMaxClicked()
        }
        amountInput.onTapSecondary = { [weak self] in
            self?.delegate.onSwitchClicked()
        }

        addSubview(cautionView)
        cautionView.snp.makeConstraints { maker in
            maker.top.equalTo(amountInputWrapper.snp.bottom)
            maker.leading.trailing.equalToSuperview()
            maker.bottom.equalToSuperview()
            maker.height.equalTo(cautionView.height(containerWidth: width))
        }

        cautionView.onChangeHeight = { [weak self] in
            self?.updateCautionHeight()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        delegate.viewDidLoad()
    }

    private func format(coinValue: CoinValueNew) -> String? {
        decimalFormatter.maximumFractionDigits = min(coinValue.decimal, 8)
        return decimalFormatter.string(from: coinValue.value as NSNumber)
    }

    private func format(currencyValue: CurrencyValue) -> String? {
        decimalFormatter.maximumFractionDigits = currencyValue.currency.decimal
        return decimalFormatter.string(from: currencyValue.value as NSNumber)
    }

    private func updateCautionHeight() {
        cautionView.snp.updateConstraints { maker in
            maker.height.equalTo(cautionView.height(containerWidth: width))
        }
    }

}

extension SendAmountView: ISendAmountView {

    func set(prefix: String?) {
        amountInput.prefix = prefix
    }

    func set(amount: AmountInfo?) {
         guard let amount = amount else {
            amountInput.inputText = nil
            return
        }

        switch amount {
        case .coinValue(let coinValue):
            amountInput.inputText = format(coinValue: coinValue)
        case .currencyValue(let currencyValue):
            amountInput.inputText = format(currencyValue: currencyValue)
        }
    }

    func setAmountColor(inputType: SendInputType) {
        switch inputType {
        case .currency:
            amountInput.textColor = .themeJacob
            amountInput.prefixColor = .themeJacob
        case .coin:
            amountInput.textColor = .themeOz
            amountInput.prefixColor = .themeOz
        }
    }

    func set(loading: Bool) {
        availableAmountValueLabel.isHidden = loading
        spinner.isHidden = !loading
        spinner.startAnimating()
    }

    func set(availableAmount: AmountInfo?) {
        guard let availableAmount = availableAmount else {
            availableAmountValueLabel.text = nil
            return
        }

        switch availableAmount {
        case .coinValue(let coinValue):
            availableAmountValueLabel.text = ValueFormatter.instance.format(coinValueNew: coinValue)
        case .currencyValue(let currencyValue):
            availableAmountValueLabel.text = ValueFormatter.instance.format(currencyValue: currencyValue)
        }
    }

    func set(hint: AmountInfo?) {
        amountInput.secondaryButtonText = hint?.formattedString ?? "n/a".localized
    }


    func setHintColor(inputType: SendInputType) {
        switch inputType {
        case .currency:
            amountInput.secondaryButtonTextColor = .themeJacob
        case .coin:
            amountInput.secondaryButtonTextColor = .themeOz
        }
    }

    func set(error: Error?) {
        let caution = error.map { Caution(text: $0.smartDescription, type: .error) }

        amountInputWrapper.set(cautionType: caution?.type)
        cautionView.set(caution: caution)
    }

    func set(switchButtonEnabled: Bool) {
        amountInput.secondaryButtonEnabled = switchButtonEnabled
    }

    func set(maxButtonVisible: Bool) {
        amountInput.maxButtonVisible = maxButtonVisible
    }

    func showKeyboard() {
        _ = amountInput.becomeFirstResponder()
    }

}
