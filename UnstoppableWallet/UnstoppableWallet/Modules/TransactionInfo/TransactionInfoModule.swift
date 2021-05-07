import Foundation
import CurrencyKit
import CoinKit

protocol ITransactionInfoView: AnyObject {
    func set(date: Date, primaryAmountInfo: AmountInfo, secondaryAmountInfo: AmountInfo?, type: TransactionType, lockState: TransactionLockState?)
    func set(viewItems: [TransactionInfoModule.ViewItem])
    func set(explorerTitle: String, enabled: Bool)
    func showCopied()
}

protocol ITransactionInfoViewDelegate: AnyObject {
    func onLoad()
    func onTapFrom()
    func onTapTo()
    func onTapRecipient()
    func onTapTransactionId()
    func onTapShareTransactionId()
    func onTapShareRawTransaction()
    func onTapVerify()
    func onTapLockInfo()
    func onTapDoubleSpendInfo()
}

protocol ITransactionInfoInteractor {
    var baseCurrency: Currency { get }
    var lastBlockInfo: LastBlockInfo? { get }
    var testMode: Bool { get }
    func rate(coinType: CoinType, currencyCode: String, timestamp: TimeInterval) -> Decimal?
    func rawTransaction(hash: String) -> String?
    func feeCoin(coin: Coin) -> Coin?
    func copy(value: String)
}

protocol ITransactionInfoRouter {
    func open(url: String)
    func showLockInfo()
    func showShare(value: String)
    func showDoubleSpendInfo(txHash: String, conflictingTxHash: String)
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
        case lockInfo(lockState: TransactionLockState)
        case sentToSelf
        case rawTransaction
        case memo(text: String)
    }

    struct ExplorerData {
        let title: String
        let url: String?
    }

}
