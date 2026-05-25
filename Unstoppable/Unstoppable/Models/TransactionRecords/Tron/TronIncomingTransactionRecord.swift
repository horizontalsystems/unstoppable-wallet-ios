import Foundation
import MarketKit
import TronKit
import WalletCore

class TronIncomingTransactionRecord: TronTransactionRecord, TransferEventsProvider {
    let from: String
    let value: AppValue

    init(source: WalletCore.TransactionSource, transaction: Transaction, baseToken: Token, from: String, value: AppValue, spam: Bool = false) {
        self.from = from
        self.value = value

        super.init(source: source, transaction: transaction, baseToken: baseToken, ownTransaction: false, spam: spam)
    }

    override var mainToken: MarketKit.Token? {
        value.token
    }

    override var mainValue: Decimal? {
        value.value
    }

    var transferEvents: TransferEvents {
        .init(incoming: [.init(address: from, value: value)])
    }
}
