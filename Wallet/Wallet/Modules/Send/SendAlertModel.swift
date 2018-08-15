import UIKit
import GrouviActionSheet

class SendAlertModel: BaseAlertModel {

    let delegate: ISendViewDelegate

    let coin: Coin

//    var sendConfigItem: BaseTwinItem?
    let sendAmountItem: SendAmountItem

    init(viewDelegate: ISendViewDelegate, coin: Coin) {
        self.delegate = viewDelegate
        self.coin = coin

//        let sendReferenceItem = SendReferenceItem()
//        sendConfigItem = BaseTwinItem(cellType: SendConfigTwinItemView.self, first: sendAmountItem, second: sendReferenceItem, height: SendTheme.twinHeight, tag: 1, required: true)
//        sendConfigItem?.showSeparator = false
        sendAmountItem = SendAmountItem(tag: 1, required: true)

        super.init()

        ignoreKeyboard = false

        let titleItem = SendTitleItem(coinCode: coin.code, tag: 0, required: true, onQRScan: { [weak self] in
            self?.delegate.onScanClick()
        })
        addItemView(titleItem)


//        sendAmountItem.onMore = { [weak self] in
//            self?.sendConfigItem?.showFirstItem = false
//            self?.reload?()
//        }
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
//        sendReferenceItem.onBack = { [weak self] in
//            self?.sendConfigItem?.showFirstItem = true
//            self?.reload?()
//        }
//        addItemView(sendConfigItem!)
        addItemView(sendAmountItem)

        let sendButtonItem = SendButtonItem(tag: 2, required: true, onTap: { [weak self] in
            self?.onSend()
        })
        addItemView(sendButtonItem)
    }

    override func viewDidLoad() {
        delegate.onViewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        delegate.onViewDidAppear()
    }

    func onSend() {
        delegate.onSendClick(address: sendAmountItem.address)
    }

}

extension SendAlertModel: ISendView {

    func setAddress(_ address: String?) {
        sendAmountItem.address = address
        sendAmountItem.reload?()
//        sendConfigItem?.updateItems?(false)
    }

    func setCurrency(code: String) {
        sendAmountItem.currencyCode = code
        sendAmountItem.reload?()
//        sendConfigItem?.updateItems?(false)
    }

    func setAmount(amount: String?) {
        sendAmountItem.amount = amount
        sendAmountItem.reload?()
//        sendConfigItem?.updateItems?(false)
    }

    func setAmountHint(hint: String, color: UIColor, error: SendError?) {
        sendAmountItem.hint = hint
        sendAmountItem.hintColor = color
        sendAmountItem.error = error
        sendAmountItem.reload?()
//        sendConfigItem?.updateItems?(false)
    }

    func closeView() {
        print("closeView")
    }

    func showError(error: String) {
        print("\(error) showError")
    }

    func showSuccess() {
        print("showSuccess")
    }

    func showKeyboard() {
        sendAmountItem.showKeyboardOnLoad?()
    }

    func showAddressWarning(_ valid: Bool) {
        sendAmountItem.addressValid = valid
        sendAmountItem.reload?()
//        sendConfigItem?.updateItems?(false)
    }

}
