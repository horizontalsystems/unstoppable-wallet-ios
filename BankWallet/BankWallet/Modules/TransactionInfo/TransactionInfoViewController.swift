import UIKit
import ActionSheet

class TransactionInfoViewController: WalletActionSheetController {
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

        let iconImage = item.type == .incoming ? UIImage(named: "Transaction In Icon") : UIImage(named: "Transaction Out Icon")
        let iconTintColor: UIColor = item.type == .incoming ? .themeRemus : .themeJacob

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

        if let value = item.rate, let formattedValue = ValueFormatter.instance.format(currencyValue: value, fractionPolicy: .threshold(high: 1000, low: 0.1), trimmable: false) {
            let rateItem = TransactionValueActionItem(title: "tx_info.rate".localized, value: "balance.rate_per_coin".localized(formattedValue, item.coinValue.coin.code), tag: 2)
            model.addItemView(rateItem)
        }

        if let feeCoinValue = item.feeCoinValue, let formattedCoinValue = ValueFormatter.instance.format(coinValue: feeCoinValue) {
            let formattedCurrencyValue = item.rate.flatMap { ValueFormatter.instance.format(currencyValue: CurrencyValue(currency: $0.currency, value: $0.value * feeCoinValue.value)) }
            let joinedValues = [formattedCoinValue, formattedCurrencyValue != nil ? "|" : nil, formattedCurrencyValue].compactMap { $0 }.joined(separator: " ")

            let feeItem = TransactionValueActionItem(title: "tx_info.fee".localized, value: joinedValues, tag: 3)
            model.addItemView(feeItem)
        }

        let statusItem = TransactionStatusItem(item: item, tag: 4)
        model.addItemView(statusItem)

        if item.showFromAddress, let from = item.from {
            model.addItemView(TransactionFromToHashItem(title: "tx_info.from_hash".localized, value: from, tag: 5, required: true, onHashTap: { [weak self] in
                self?.delegate.onCopy(value: from)
            }))
        }

        if let to = item.to {
            model.addItemView(TransactionFromToHashItem(title: "tx_info.to_hash".localized, value: to, tag: 6, required: true, onHashTap: { [weak self] in
                self?.delegate.onCopy(value: to)
            }))
        }

        if item.type == .outgoing, let recipientAddress = item.lockInfo?.originalAddress {
            model.addItemView(TransactionFromToHashItem(title: "tx_info.recipient_hash".localized, value: recipientAddress, tag: 7, required: true, onHashTap: { [weak self] in
                self?.delegate.onCopy(value: recipientAddress)
            }))
        }

        model.addItemView(TransactionIdItem(value: item.transactionHash, tag: 8, onHashTap: { [weak self] in
            self?.delegate.onCopy(value: item.transactionHash)
        }))

        if let lockInfo = item.lockInfo {
            let lockedDate = DateHelper.instance.formatFullTime(from: lockInfo.lockedUntil)
            let lockedIconName = item.unlocked ? "Transaction Unlock Icon" : "Transaction Lock Icon"
            let lockDateItem = TransactionNoteItem(note: "tx_info.locked_until".localized(lockedDate), imageName: lockedIconName, tag: 9, iconName: "Transaction Info Icon") { [weak self] in
                self?.delegate.openLockInfo()
            }
            model.addItemView(lockDateItem)
        }

        if item.type == .sentToSelf {
            let infoItem = TransactionNoteItem(note: "tx_info.to_self_note".localized, imageName: "Transaction In Icon", tag: 10)
            model.addItemView(infoItem)
        }

        if item.conflictingTxHash != nil {
            let doubleSpendItem = TransactionNoteItem(note: "tx_info.double_spent_note".localized, imageName: "Transaction Double Spend Icon", tag: 11, iconName: "Transaction Info Icon") { [weak self] in
                self?.delegate.openDoubleSpendInfo()
            }
            model.addItemView(doubleSpendItem)
        }

        let openFullInfoItem = TransactionOpenFullInfoItem(tag: 12, required: true, onTap: { [weak self] in
            self?.delegate.openFullInfo()
        })
        model.addItemView(openFullInfoItem)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        backgroundColor = AppTheme.actionSheetBackgroundColor
        model.hideInBackground = false

        model.reload?()
    }

}

extension TransactionInfoViewController: ITransactionInfoView {

    func showCopied() {
        HudHelper.instance.showSuccess(title: "alert.copied".localized)
    }

}
