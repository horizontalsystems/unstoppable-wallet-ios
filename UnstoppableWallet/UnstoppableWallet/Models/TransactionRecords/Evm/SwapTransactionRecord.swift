import Foundation
import EthereumKit
import MarketKit

class SwapTransactionRecord: EvmTransactionRecord {
    let exchangeAddress: String
    let amountIn: Amount
    let amountOut: Amount?
    let recipient: String?

    init(source: TransactionSource, transaction: Transaction, baseCoin: PlatformCoin, exchangeAddress: String, amountIn: Amount, amountOut: Amount?, recipient: String?) {
        self.exchangeAddress = exchangeAddress
        self.amountIn = amountIn
        self.amountOut = amountOut

        self.recipient = recipient

        super.init(source: source, transaction: transaction, baseCoin: baseCoin, ownTransaction: true)
    }

    var valueIn: TransactionValue {
        amountIn.value
    }

    var valueOut: TransactionValue? {
        amountOut?.value
    }

}

extension SwapTransactionRecord {

    enum Amount {
        case exact(value: TransactionValue)
        case extremum(value: TransactionValue)

        var value: TransactionValue {
            switch self {
            case .exact(let value): return value
            case .extremum(let value): return value
            }
        }
    }

}
