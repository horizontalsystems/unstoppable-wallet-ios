import Foundation
import CurrencyKit

protocol ITransactionInfoView: AnyObject {
    func set(date: Date, primaryAmountInfo: AmountInfo, secondaryAmountInfo: AmountInfo?, type: TransactionType, locked: Bool?)
    func set(viewItems: [TransactionInfoModule.ViewItem])
    func showCopied()
}

protocol ITransactionInfoViewDelegate: class {
    func onLoad()
    func onTapFrom()
    func onTapTo()
    func onTapRecipient()
    func onTapTransactionId()
    func onTapShareTransactionId()
    func onTapVerify()
    func onTapLockInfo()
    func onTapDoubleSpendInfo()
}

protocol ITransactionInfoInteractor {
    func copy(value: String)
}

protocol ITransactionInfoRouter {
    func showFullInfo(transactionHash: String, wallet: Wallet)
    func showLockInfo()
    func showShare(value: String)
    func showDoubleSpendInfo(txHash: String, conflictingTxHash: String?)
}

class TransactionInfoModule {

    enum ViewItem {
        case status(status: TransactionStatus, incoming: Bool)
        case from(value: String)
        case to(value: String)
        case recipient(value: String)
        case id(value: String)
        case rate(currencyValue: CurrencyValue, coinCode: String)
        case fee(coinValue: CoinValue, currencyValue: CurrencyValue?)
        case doubleSpend
        case lockInfo(lockedUntil: Date, unlocked: Bool)
        case sentToSelf
    }

}
