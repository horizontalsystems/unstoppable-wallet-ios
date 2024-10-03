import EvmKit
import Foundation
import MarketKit

class SwapTransactionRecord: EvmTransactionRecord {
    let exchangeAddress: String
    let amountIn: Amount
    let amountOut: Amount?
    let recipient: String?

    init(source: TransactionSource, transaction: Transaction, baseToken: Token, exchangeAddress: String, amountIn: Amount, amountOut: Amount?, recipient: String?) {
        self.exchangeAddress = exchangeAddress
        self.amountIn = amountIn
        self.amountOut = amountOut

        self.recipient = recipient

        super.init(source: source, transaction: transaction, baseToken: baseToken, ownTransaction: true)
    }

    var valueIn: AppValue {
        amountIn.value
    }

    var valueOut: AppValue? {
        amountOut?.value
    }

    override var rateTokens: [Token?] {
        super.rateTokens + [valueIn.token, valueOut?.token]
    }

    override func internalSections(status: TransactionStatus, lastBlockInfo _: LastBlockInfo?, rates: [Coin: CurrencyValue], nftMetadata _: [NftUid: NftAssetBriefMetadata], hidden: Bool) -> [Section] {
        swapSections(exchangeAddress: exchangeAddress, valueIn: valueIn, valueOut: valueOut, recipient: recipient, status: status, rates: rates, hidden: hidden)
    }
}

extension SwapTransactionRecord {
    enum Amount {
        case exact(value: AppValue)
        case extremum(value: AppValue)

        var value: AppValue {
            switch self {
            case let .exact(value): return value
            case let .extremum(value): return value
            }
        }
    }
}
