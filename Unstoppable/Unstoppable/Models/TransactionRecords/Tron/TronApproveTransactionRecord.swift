import Foundation
import MarketKit
import TronKit
import WalletCore

class TronApproveTransactionRecord: TronTransactionRecord, IApproveTransaction {
    let spender: String
    let value: AppValue

    init(source: WalletCore.TransactionSource, transaction: Transaction, baseToken: Token, spender: String, value: AppValue) {
        self.spender = spender
        self.value = value

        super.init(source: source, transaction: transaction, baseToken: baseToken, ownTransaction: true)
    }

    override var mainToken: MarketKit.Token? {
        value.token
    }

    override var mainValue: Decimal? {
        value.value
    }
}
