import UIKit
import GrouviActionSheet

class SendAlertModel: BaseAlertModel {
    private let delegate: ISendViewDelegate

    private let titleItem: SendTitleItem
    private let amountItem: SendAmountItem
    private let addressItem: SendAddressItem
    private let feeItem: SendFeeItem
    private let sendButtonItem: SendButtonItem
    private let keyboardItem: SendKeyboardItem

    var onScanClicked: (() -> ())?
    var onShowConfirmation: ((SendConfirmationViewItem) -> ())?
    var onCopyAddress: (() -> ())?

    init(delegate: ISendViewDelegate) {
        self.delegate = delegate

        titleItem = SendTitleItem(tag: 0)
        amountItem = SendAmountItem(tag: 1)
        addressItem = SendAddressItem(tag: 2)
        feeItem = SendFeeItem(tag: 3)
        sendButtonItem = SendButtonItem(buttonTitle: "send.send_button".localized, tag: 4)
        keyboardItem = SendKeyboardItem(tag: 5)

        super.init()

        hideInBackground = false

        addItemView(titleItem)
        addItemView(amountItem)
        addItemView(addressItem)
        addItemView(feeItem)
        addItemView(sendButtonItem)
        addItemView(keyboardItem)

        amountItem.onAmountChanged = { [weak self] in
            self?.delegate.onAmountChanged(amount: $0)
        }
        amountItem.onSwitchClicked = { [weak self] in
            self?.delegate.onSwitchClicked()
        }
        amountItem.onMaxClicked = { [weak self] in
            self?.delegate.onMaxClicked()
        }
        amountItem.onPasteClicked = { [weak self] in
            self?.delegate.onPasteAmountClicked()
        }

        addressItem.onPasteClicked = { [weak self] in
            self?.delegate.onPasteAddressClicked()
        }
        addressItem.onScanClicked = { [weak self] in
            self?.onScanClicked?()
        }
        addressItem.onDeleteClicked = { [weak self] in
            self?.delegate.onDeleteClicked()
        }

        sendButtonItem.onClicked = { [weak self] in
            self?.delegate.onSendClicked()
        }
        onCopyAddress = { [weak self] in
            self?.delegate.onCopyAddress()
        }
        keyboardItem.addLetter = { [weak self] text in
            self?.amountItem.addLetter?(text)
        }
        keyboardItem.removeLetter = { [weak self] in
            self?.amountItem.removeLetter?()
        }
    }

    override func viewDidLoad() {
    }

    override func viewWillAppear(_ animated: Bool) {
        delegate.onViewDidLoad()
        amountItem.showKeyboard?()
    }

    func onScan(address: String) {
        delegate.onScan(address: address)
    }

    func onConfirm() {
        delegate.onConfirmClicked()
    }

    private func set(primaryFeeInfo: AmountInfo?) {
        guard let primaryFeeInfo = primaryFeeInfo else {
            feeItem.bindFee?(nil)
            return
        }

        switch primaryFeeInfo {
        case .coinValue(let coinValue):
            feeItem.bindFee?(ValueFormatter.instance.format(coinValue: coinValue))
        case .currencyValue(let currencyValue):
            feeItem.bindFee?(ValueFormatter.instance.format(currencyValue: currencyValue, roundingMode: .ceiling).map { return "~\($0)" })
        }
    }

    private func set(secondaryFeeInfo: AmountInfo?) {
        guard let secondaryFeeInfo = secondaryFeeInfo else {
            feeItem.bindConvertedFee?(nil)
            return
        }

        switch secondaryFeeInfo {
        case .coinValue(let coinValue):
            feeItem.bindConvertedFee?(ValueFormatter.instance.format(coinValue: coinValue))
        case .currencyValue(let currencyValue):
            feeItem.bindConvertedFee?(ValueFormatter.instance.format(currencyValue: currencyValue, roundingMode: .ceiling).map { return "~\($0)" })
        }
    }

    private func set(feeError: FeeError?) {
        guard let error = feeError, case .erc20error(let erc20CoinCode, let fee) = error, let amount = ValueFormatter.instance.format(coinValue: fee) else {
            feeItem.bindError?(nil)
            return
        }

        feeItem.bindError?("send_erc.alert".localized(erc20CoinCode, amount))
    }

}

extension SendAlertModel: ISendView {

    func set(coin: Coin) {
        titleItem.bindCoin?(coin)
    }

    func set(amountInfo: AmountInfo?) {
        guard let amountInfo = amountInfo else {
            amountItem.bindAmountType?(nil)
            amountItem.bindAmount?(nil)
            return
        }

        switch amountInfo {
        case .coinValue(let coinValue):
            amountItem.bindAmountType?(coinValue.coinCode)
            amountItem.bindAmount?(coinValue.value)
        case .currencyValue(let currencyValue):
            amountItem.bindAmountType?(currencyValue.currency.symbol)
            amountItem.bindAmount?(currencyValue.value)
        }
    }

    func set(switchButtonEnabled: Bool) {
        amountItem.bindSwitchEnabled?(switchButtonEnabled)
    }

    func set(hintInfo: HintInfo?) {
        amountItem.bindHint?(nil)
        amountItem.bindError?(nil)

        if let hintInfo = hintInfo {
            switch hintInfo {
            case .amount(let amountInfo):
                switch amountInfo {
                case .coinValue(let coinValue):
                    amountItem.bindHint?(ValueFormatter.instance.format(coinValue: coinValue))
                case .currencyValue(let currencyValue):
                    amountItem.bindHint?(ValueFormatter.instance.format(currencyValue: currencyValue))
                }
            case .error(let error):
                switch error {
                case .coinValue(let coinValue):
                    amountItem.bindError?("send.amount_error.balance".localized(ValueFormatter.instance.format(coinValue: coinValue) ?? ""))
                case .currencyValue(let currencyValue):
                    amountItem.bindError?("send.amount_error.balance".localized(ValueFormatter.instance.format(currencyValue: currencyValue) ?? ""))
                }
            }
        }
    }

    func set(addressInfo: AddressInfo?) {
        if let addressInfo = addressInfo {
            switch addressInfo {
            case .address(let address):
                addressItem.bindAddress?(address, nil)
            case .invalidAddress(let address, _):
                addressItem.bindAddress?(address, "Invalid address")
            }
        } else {
            addressItem.bindAddress?(nil, nil)
        }
    }

    func set(feeInfo: FeeInfo?) {
        if let error = feeInfo?.error {
            set(primaryFeeInfo: nil)
            set(secondaryFeeInfo: nil)

            set(feeError: error)
        } else {
            set(feeError: nil)

            set(primaryFeeInfo: feeInfo?.primaryFeeInfo)
            set(secondaryFeeInfo: feeInfo?.secondaryFeeInfo)
        }
    }

    func set(sendButtonEnabled: Bool) {
        sendButtonItem.isActive = sendButtonEnabled
        reload?()
    }

    func showConfirmation(viewItem: SendConfirmationViewItem) {
        onShowConfirmation?(viewItem)
    }

    func showCopied() {
        HudHelper.instance.showSuccess(title: "alert.copied".localized)
    }

    func show(error: Error) {
        HudHelper.instance.showError(title: error.localizedDescription)
    }

    func dismissWithSuccess() {
        dismiss?(true)
        HudHelper.instance.showSuccess()
    }

    func set(decimal: Int) {
        amountItem.decimal = decimal
    }

}
