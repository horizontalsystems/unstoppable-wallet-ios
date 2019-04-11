import UIKit
import GrouviActionSheet

class TransactionInfoViewController: ActionSheetController {
    private let delegate: ITransactionInfoViewDelegate

    init(delegate: ITransactionInfoViewDelegate) {
        self.delegate = delegate
        super.init(withModel: BaseAlertModel(), actionSheetThemeConfig: AppTheme.actionSheetConfig)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        backgroundColor = .crypto_Dark_Bars
        model.hideInBackground = false

        let item = delegate.viewItem

        let titleItem = TransactionTitleItem(item: item, tag: 0, onIdTap: { [weak self] in
            self?.delegate.onCopy(value: item.transactionHash)
        })
        model.addItemView(titleItem)

        let amountItem = TransactionAmountItem(item: item, tag: 1)
        model.addItemView(amountItem)

        if let value = item.rate, let formattedValue = ValueFormatter.instance.format(currencyValue: value, fractionPolicy: .threshold(threshold: 1000)) {
            let rateItem = TransactionValueItem(title: "tx_info.rate".localized, value: "balance.rate_per_coin".localized(formattedValue, item.coinValue.coinCode), tag: 2)
            model.addItemView(rateItem)
        }

        if let date = item.date {
            let timeItem = TransactionValueItem(title: "tx_info.time".localized, value: DateHelper.instance.formatTransactionInfoTime(from: date), tag: 3)
            model.addItemView(timeItem)
        }

        let statusItem = TransactionStatusItem(item: item, tag: 4)
        model.addItemView(statusItem)

        if let from = item.from {
            model.addItemView(TransactionFromToHashItem(title: "tx_info.from_hash".localized, value: from, tag: 5, required: true, onHashTap: { [weak self] in
                self?.delegate.onCopy(value: from)
            }))
        }

        if let to = item.to {
            model.addItemView(TransactionFromToHashItem(title: "tx_info.to_hash".localized, value: to, tag: 6, required: true, onHashTap: { [weak self] in
                self?.delegate.onCopy(value: to)
            }))
        }

        let openFullInfoItem = TransactionOpenFullInfoItem(tag: 7, required: true, onTap: { [weak self] in
            self?.delegate.openFullInfo()
        })
        model.addItemView(openFullInfoItem)
    }

}

extension TransactionInfoViewController: ITransactionInfoView {

    func showCopied() {
        HudHelper.instance.showSuccess(title: "alert.copied".localized)
    }

}
