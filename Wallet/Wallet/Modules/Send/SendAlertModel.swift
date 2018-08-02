import UIKit
import GrouviActionSheet

class SendAlertModel: BaseAlertModel {

    let delegate: ISendViewDelegate

    let coin: Coin

    var sendConfigItem: BaseTwinItem?
    let sendAmountItem: SendAmountItem

    init(viewDelegate: ISendViewDelegate, coin: Coin) {
        self.delegate = viewDelegate
        self.coin = coin

        sendAmountItem = SendAmountItem()
        let sendReferenceItem = SendReferenceItem()
        sendConfigItem = BaseTwinItem(cellType: SendConfigTwinItemView.self, first: sendAmountItem, second: sendReferenceItem, height: SendTheme.twinHeight, tag: 1, required: true)
        sendConfigItem?.showSeparator = false

        super.init()

        ignoreKeyboard = false

        let titleItem = SendTitleItem(coinCode: coin.code, tag: 0, required: true, onQRScan: { [weak self] in
            self?.delegate.onScanClick()
        })
        addItemView(titleItem)


        sendAmountItem.onMore = { [weak self] in
            self?.sendConfigItem?.showFirstItem = false
            self?.reload?()
        }
        sendAmountItem.onPaste = { [weak self] in
            self?.delegate.onPasteClick()
        }
        sendAmountItem.onCurrencyChange = { [weak self] in
            self?.delegate.onCurrencyButtonClick()
        }
        sendAmountItem.onAmountEntered = { [weak self] in
            self?.delegate.onAmountEntered(amount: $0)
        }
        sendAmountItem.onAddressEntered = { [weak self] in
            self?.delegate.onAddressEntered(address: $0)
        }
        sendReferenceItem.onBack = { [weak self] in
            self?.sendConfigItem?.showFirstItem = true
            self?.reload?()
        }
        addItemView(sendConfigItem!)

        let sendButtonItem = SendButtonItem(tag: 2, required: true, onTap: { [weak self] in
            self?.onSend()
        })
        addItemView(sendButtonItem)
    }

    override func viewDidLoad() {
        delegate.onViewDidLoad()
    }

    override func viewDidAppear(_ animated: Bool) {
        delegate.onViewDidAppear()
    }

    func onSend() {
        delegate.onSendClick(address: sendAmountItem.address)
    }

}

extension SendAlertModel: ISendView {

    func setAddress(_ address: String?) {
        sendAmountItem.address = address
        sendConfigItem?.updateItems?(false)
    }

    func setCurrency(code: String) {
        sendAmountItem.currencyCode = code
        sendConfigItem?.updateItems?(false)
    }

    func setAmount(amount: String?) {
        sendAmountItem.amount = amount
        sendConfigItem?.updateItems?(false)
    }

    func setAmountHint(hint: String, error: SendError?) {
        sendAmountItem.hint = hint
        sendAmountItem.error = error
        sendConfigItem?.updateItems?(false)
    }

    func closeView() {
        print("closeView")
    }

    func showError(error: String) {
        print("showError")
    }

    func showSuccess() {
        print("showSuccess")
    }

    func showKeyboard() {
        sendAmountItem.showKeyboardOnLoad?()
    }

    func showAddressWarning(_ valid: Bool) {
        sendAmountItem.addressValid = valid
        sendConfigItem?.updateItems?(false)
    }

}
