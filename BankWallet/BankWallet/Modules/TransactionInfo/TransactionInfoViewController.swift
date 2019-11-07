import UIKit
import ActionSheet

class TransactionInfoViewController: ActionSheetController {
    private let delegate: ITransactionInfoViewDelegate

    init(delegate: ITransactionInfoViewDelegate) {
        self.delegate = delegate
        super.init(withModel: BaseAlertModel(), actionSheetThemeConfig: AppTheme.actionSheetConfig)

        initItems()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func initItems() {
        let item = delegate.viewItem

        let iconImage = item.incoming ? UIImage(named: "Transaction In Icon") : UIImage(named: "Transaction Out Icon")
        let iconTintColor: UIColor = item.incoming ? .appRemus : .appJacob

        let titleItem = AlertTitleItem(
                title: "tx_info.title".localized,
                subtitle: DateHelper.instance.formatFullTime(from: item.date),
                icon: iconImage,
                iconTintColor: iconTintColor,
                tag: 0,
                onClose: { [weak self] in
                    self?.dismiss(byFade: false)
                }
        )
        model.addItemView(titleItem)

        let amountItem = TransactionAmountItem(item: item, tag: 1)
        model.addItemView(amountItem)

        if let lockInfo = item.lockInfo {
            let lockedDate = DateHelper.instance.formatFullDateOnly(from: lockInfo.lockedUntil)
            let lockDateItem = TransactionValueActionItem(title: "tx_info.locked_until".localized, value: lockedDate, tag: 2, iconName: "Transaction Info Icon") { [weak self] in
                self?.delegate.openLockInfo()
            }
            model.addItemView(lockDateItem)
        }

        if let value = item.rate, let formattedValue = ValueFormatter.instance.format(currencyValue: value, fractionPolicy: .threshold(high: 1000, low: 0.1), trimmable: false) {
            let rateItem = TransactionValueActionItem(title: "tx_info.rate".localized, value: "balance.rate_per_coin".localized(formattedValue, item.coinValue.coin.code), tag: 3)
            model.addItemView(rateItem)
        }

        if let feeCoinValue = item.feeCoinValue, let formattedValue = ValueFormatter.instance.format(coinValue: feeCoinValue) {
            let feeItem = TransactionValueActionItem(title: "tx_info.fee".localized, value: formattedValue, tag: 4)
            model.addItemView(feeItem)
        }

        let statusItem = TransactionStatusItem(item: item, tag: 5)
        model.addItemView(statusItem)

        if item.showFromAddress, let from = item.from {
            model.addItemView(TransactionFromToHashItem(title: "tx_info.from_hash".localized, value: from, tag: 6, required: true, onHashTap: { [weak self] in
                self?.delegate.onCopy(value: from)
            }))
        }

        if let to = item.to {
            model.addItemView(TransactionFromToHashItem(title: "tx_info.to_hash".localized, value: to, tag: 7, required: true, onHashTap: { [weak self] in
                self?.delegate.onCopy(value: to)
            }))
        }

        if !item.incoming, let recipientAddress = item.lockInfo?.originalAddress {
            model.addItemView(TransactionFromToHashItem(title: "tx_info.recipient_hash".localized, value: recipientAddress, tag: 8, required: true, onHashTap: { [weak self] in
                self?.delegate.onCopy(value: recipientAddress)
            }))
        }

        model.addItemView(TransactionIdItem(value: item.transactionHash, tag: 9, onHashTap: { [weak self] in
            self?.delegate.onCopy(value: item.transactionHash)
        }))

        if item.sentToSelf {
            let infoItem = TransactionNoteItem(note: "* " + "tx_info.note".localized, tag: 10)
            model.addItemView(infoItem)
        }

        let openFullInfoItem = TransactionOpenFullInfoItem(tag: 11, required: true, onTap: { [weak self] in
            self?.delegate.openFullInfo()
        })
        model.addItemView(openFullInfoItem)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        backgroundColor = .crypto_Dark_Bars
        model.hideInBackground = false
    }

}

extension TransactionInfoViewController: ITransactionInfoView {

    func showCopied() {
        HudHelper.instance.showSuccess(title: "alert.copied".localized)
    }

}
