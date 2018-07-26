import UIKit
import GrouviActionSheet

class SendAlertModel: BaseAlertModel {

    let delegate: ISendViewDelegate

    let coin: Coin

    init(viewDelegate: ISendViewDelegate, coin: Coin) {
        self.delegate = viewDelegate
        self.coin = coin

        super.init()
        delegate.onViewDidLoad()
        ignoreKeyboard = false

        let titleItem = SendTitleItem(coinCode: coin.code, tag: 0, required: true, onQRScan: { [weak self] in
            self?.delegate.onScanClick()
        })
        addItemView(titleItem)

        var sendConfigItem: BaseTwinItem?
        let sendAmountItem = SendAmountItem(onMore: { [weak self] in
            sendConfigItem?.showFirstItem = false
            self?.reload?()
        })
        let sendReferenceItem = SendReferenceItem(onBack: { [weak self] in
            sendConfigItem?.showFirstItem = true
            self?.reload?()
        })
        sendConfigItem = BaseTwinItem(cellType: SendConfigTwinItemView.self, first: sendAmountItem, second: sendReferenceItem, height: SendTheme.twinHeight, tag: 1, required: true)
        sendConfigItem?.showSeparator = false

        addItemView(sendConfigItem!)

        let sendButtonItem = SendButtonItem(tag: 2, required: true, onTap: {
            print("on send")
        })
        addItemView(sendButtonItem)
    }

}

extension SendAlertModel: ISendView {

    func setAddress(address: String) {
        print("setAddress")
    }

    func setCurrency(code: String) {
        print("setCurrency")
    }

    func setAmount(amount: String?) {
        print("setAmount")
    }

    func setAmountHint(hint: String) {
        print("setAmountHint")
    }

    func closeView() {
        print("closeView")
    }

    func showError(error: Error) {
        print("showError")
    }

    func showSuccess() {
        print("showSuccess")
    }

}
