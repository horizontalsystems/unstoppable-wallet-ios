import UIKit
import GrouviActionSheet

class SendConfirmationAlertModel: BaseAlertModel {
    private let viewItem: SendConfirmationViewItem

    private let titleItem: SendTitleItem
    private let amountItem: SendConfirmationAmounItem
    private let addressItem: SendConfirmationAddressItem
    private let feeItem: SendConfirmationValueItem
    private let sendButtonItem: SendButtonItem

    var onCopyAddress: (() -> ())?

    init(viewItem: SendConfirmationViewItem) {
        self.viewItem = viewItem

        titleItem = SendTitleItem(tag: 0)
        amountItem = SendConfirmationAmounItem(viewItem: viewItem, tag: 1)
        addressItem = SendConfirmationAddressItem(address: viewItem.address, tag: 2)
        feeItem = SendConfirmationValueItem(title: "send.fee".localized, amountInfo: viewItem.feeInfo, tag: 3)
        sendButtonItem = SendButtonItem(buttonTitle: "alert.confirm".localized, tag: 5)

        super.init()

        hideInBackground = false

        addItemView(titleItem)
        addItemView(amountItem)

        addressItem.onHashTap = { [weak self] in
            self?.onCopyAddress?()
        }
        addItemView(addressItem)

        addItemView(feeItem)
        if let totalInfo = viewItem.totalInfo {
            let totalItem = SendConfirmationValueItem(title: "send.total".localized, amountInfo: totalInfo, tag: 4)
            addItemView(totalItem)
        }

        sendButtonItem.onClicked = { [weak self] in
            self?.dismiss?(true)
        }
        addItemView(sendButtonItem)
    }

    override func viewWillAppear(_ animated: Bool) {
        titleItem.bindCoin?(viewItem.coin)
    }

}
