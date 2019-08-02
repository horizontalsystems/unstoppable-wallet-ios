import UIKit
import ActionSheet

class SendConfirmationViewController: ActionSheetController {
    private let delegate: ISendViewDelegate
    private let viewItem: SendConfirmationViewItem

    private let titleItem: ActionTitleItem
    private let amountItem: SendConfirmationAmounItem
    private let addressItem: SendConfirmationAddressItem
    private let feeItem: SendConfirmationValueItem
    private let sendButtonItem: SendButtonItem

    init(delegate: ISendViewDelegate, viewItem: SendConfirmationViewItem) {
        self.delegate = delegate
        self.viewItem = viewItem

        titleItem = ActionTitleItem(tag: 0)
        amountItem = SendConfirmationAmounItem(viewItem: viewItem, tag: 1)
        addressItem = SendConfirmationAddressItem(address: viewItem.address, tag: 2)
        feeItem = SendConfirmationValueItem(title: "send.fee".localized, amountInfo: viewItem.feeInfo, tag: 3)
        sendButtonItem = SendButtonItem(buttonTitle: "button.confirm".localized, tag: 5)

        super.init(withModel: BaseAlertModel(), actionSheetThemeConfig: SendTheme.confirmationSheetConfig)

        initItems()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func initItems() {
        model.addItemView(titleItem)
        model.addItemView(amountItem)

        addressItem.onHashTap = { [weak self] in
            self?.delegate.onCopyAddress()
        }
        model.addItemView(addressItem)

        model.addItemView(feeItem)
        if let totalInfo = viewItem.totalInfo {
            let totalItem = SendConfirmationValueItem(title: "send.confirmation.total".localized, amountInfo: totalInfo, isFee: false, tag: 4)
            model.addItemView(totalItem)
        }

        sendButtonItem.onClicked = { [weak self] in
            self?.delegate.onConfirmClicked()
        }
        model.addItemView(sendButtonItem)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        backgroundColor = .crypto_Dark_Bars
        model.hideInBackground = false
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        titleItem.bindTitle?("send.title".localized(viewItem.coin.title), viewItem.coin)
    }

}
