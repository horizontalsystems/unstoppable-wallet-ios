import UIKit
import SnapKit
import RxSwift
import HUD

class SendAmountView: UIView {
    private static let spinnerRadius: CGFloat = 8
    private static let spinnerLineWidth: CGFloat = 2
    private let sendSmallButtonMargin: CGFloat = 6

    private let delegate: ISendAmountViewDelegate

    private var disposeBag = DisposeBag()

    private let holderView = UIView()

    private let availableBalanceTitleLabel = UILabel()
    private let availableBalanceValueLabel = UILabel()
    private let processSpinner = HUDProgressView(
            strokeLineWidth: SendAmountView.spinnerLineWidth,
            radius: SendAmountView.spinnerRadius,
            strokeColor: .appOz
    )

    private let amountTypeLabel = UILabel()
    private let inputField = UITextField()
    private let lineView = UIView()
    private let maxButton = UIButton.appSecondary
    private let hintLabel = UILabel()
    private let errorLabel = UILabel()
    private let switchButton = UIButton.appSecondary

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
            maker.height.equalTo(112)
        }

        backgroundColor = .clear

        addSubview(availableBalanceTitleLabel)
        availableBalanceTitleLabel.text = "send.available_balance".localized
        availableBalanceTitleLabel.font = .appSubhead2
        availableBalanceTitleLabel.textColor = .appGray
        availableBalanceTitleLabel.snp.makeConstraints { maker in
            maker.top.equalToSuperview().offset(CGFloat.margin2x)
            maker.leading.equalToSuperview().offset(CGFloat.margin4x)
        }

        addSubview(availableBalanceValueLabel)
        availableBalanceValueLabel.font = .appSubhead1

        availableBalanceValueLabel.textColor = .appLeah
        availableBalanceValueLabel.snp.makeConstraints { maker in
            maker.centerY.equalTo(availableBalanceTitleLabel.snp.centerY)
            maker.trailing.equalToSuperview().inset(CGFloat.margin4x)
        }

        addSubview(processSpinner)
        processSpinner.snp.makeConstraints { maker in
            maker.centerY.equalTo(availableBalanceTitleLabel.snp.centerY)
            maker.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.width.height.equalTo(SendAmountView.spinnerRadius * 2 + SendAmountView.spinnerLineWidth)
        }
        processSpinner.isHidden = true

        addSubview(holderView)

        holderView.addSubview(amountTypeLabel)
        holderView.addSubview(lineView)
        holderView.addSubview(maxButton)
        holderView.addSubview(inputField)
        holderView.addSubview(switchButton)
        holderView.addSubview(hintLabel)
        holderView.addSubview(errorLabel)

        holderView.layer.cornerRadius = CGFloat.cornerRadius8
        holderView.layer.borderWidth = CGFloat.heightOneDp
        holderView.layer.borderColor = UIColor.appSteel20.cgColor
        holderView.backgroundColor = .appLawrence
        holderView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.height.equalTo(75)
            maker.top.equalTo(availableBalanceTitleLabel.snp.bottom).offset(CGFloat.margin3x)
            maker.bottom.equalToSuperview()
        }

        amountTypeLabel.font = .appBody
        amountTypeLabel.textColor = .appOz
        amountTypeLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        amountTypeLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        amountTypeLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(CGFloat.margin3x)
            maker.top.equalToSuperview().offset(CGFloat.margin3x)
        }

        lineView.backgroundColor = .appSteel20
        lineView.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(CGFloat.margin2x)
            maker.trailing.equalToSuperview().inset(CGFloat.margin2x)
            maker.top.equalTo(switchButton.snp.bottom).offset(sendSmallButtonMargin)
            maker.height.equalTo(CGFloat.heightOneDp)
        }

        maxButton.snp.makeConstraints { maker in //constraints need to be set on init
            maker.top.equalTo(switchButton.snp.top)
            maker.trailing.equalTo(switchButton.snp.leading).offset(-CGFloat.margin2x)
            maker.height.equalTo(CGFloat.heightButtonSecondary)
        }

        maxButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        maxButton.setTitle("send.max_button".localized, for: .normal)
        maxButton.addTarget(self, action: #selector(onTapMax), for: .touchUpInside)

        inputField.delegate = self
        inputField.font = .appBody
        inputField.textColor = .appOz
        inputField.attributedPlaceholder = NSAttributedString(string: "send.amount_placeholder".localized, attributes: [NSAttributedString.Key.foregroundColor: AppTheme.textPlaceholderColor])
        inputField.keyboardAppearance = App.theme.keyboardAppearance
        inputField.keyboardType = .decimalPad
        inputField.tintColor = AppTheme.textFieldTintColor
        inputField.snp.makeConstraints { maker in
            maker.centerY.equalTo(amountTypeLabel.snp.centerY).offset(CGFloat.heightOnePixel)
            maker.leading.equalTo(amountTypeLabel.snp.trailing).offset(CGFloat.margin1x)
            maker.trailing.equalTo(maxButton.snp.leading).offset(-CGFloat.margin1x)
        }

        switchButton.snp.makeConstraints { maker in
            maker.top.trailing.equalToSuperview().inset(sendSmallButtonMargin)
            maker.size.equalTo(CGFloat.heightButtonSecondary)
        }

        switchButton.setImage(UIImage(named: "Send Switch Icon")?.tinted(with: .appOz), for: .normal)
        switchButton.setImage(UIImage(named: "Send Switch Icon")?.tinted(with: .appGray50), for: .disabled)
        switchButton.addTarget(self, action: #selector(onTapSwitch), for: .touchUpInside)

        hintLabel.font = .appCaption
        hintLabel.textColor = .appGray
        hintLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(CGFloat.margin3x)
            maker.top.equalTo(lineView).offset(CGFloat.margin2x)
            maker.trailing.equalTo(lineView)
        }

        errorLabel.font = .appCaption
        errorLabel.textColor = .appLucian
        errorLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(CGFloat.margin3x)
            maker.top.equalTo(lineView).offset(CGFloat.margin2x)
            maker.trailing.equalTo(lineView)
        }

        inputField.rx.controlEvent(.editingChanged)
                .asObservable()
                .do(onNext: { [weak self] _ in
                    self?.delegate.willChangeAmount(text: self?.inputField.text)
                })
                .debounce(.milliseconds(500), scheduler: MainScheduler.instance)
                .subscribe(onNext: { [weak self] _ in
                    self?.delegate.didChangeAmount()
                })
                .disposed(by: disposeBag)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        delegate.viewDidLoad()
    }

    @objc private func onTapMax() {
        delegate.onMaxClicked()
    }

    @objc private func onTapSwitch() {
        delegate.onSwitchClicked()
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

    func set(loading: Bool) {
        availableBalanceValueLabel.isHidden = loading
        processSpinner.isHidden = !loading
        processSpinner.startAnimating()
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
        hintLabel.isHidden = error != nil
        errorLabel.text = error?.localizedDescription
    }

    func set(switchButtonEnabled: Bool) {
        switchButton.isEnabled = switchButtonEnabled
    }

    func set(maxButtonVisible: Bool) {
        maxButton.snp.remakeConstraints { maker in
            if maxButtonVisible {
                maker.trailing.equalTo(switchButton.snp.leading).offset(-CGFloat.margin2x)
            } else {
                maker.trailing.equalTo(switchButton.snp.leading)
                maker.width.equalTo(0)
            }
            maker.top.equalToSuperview().inset(sendSmallButtonMargin)
            maker.height.equalTo(CGFloat.heightButtonSecondary)
        }
    }

    func showKeyboard() {
        inputField.becomeFirstResponder()
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
