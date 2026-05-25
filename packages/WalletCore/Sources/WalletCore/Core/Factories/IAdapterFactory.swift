import Foundation
import MarketKit

public protocol IAdapterFactory: AnyObject {
    func adapter(wallet: Wallet) -> IAdapter?
    func transactionsAdapter(transactionSource: TransactionSource) -> ITransactionsAdapter?
}
