import BigInt
import Foundation
import MarketKit
import ThorChainKit

class ThorChainTransactionConverter {
    private let source: TransactionSource
    private let baseToken: Token
    private let ownAddress: String

    init(source: TransactionSource, baseToken: Token, thorChainKitWrapper: ThorChainKitWrapper) {
        self.source = source
        self.baseToken = baseToken
        ownAddress = thorChainKitWrapper.thorChainKit.address.raw
    }

    private func appValue(amount: BigUInt, sign: FloatingPointSign) -> AppValue {
        let value = Decimal(sign: sign, exponent: -baseToken.decimals, significand: Decimal(string: amount.description) ?? 0)
        return AppValue(token: baseToken, value: value)
    }

    private func runeTransfer(in transfers: [ThorChainKit.CoinTransfer]) -> ThorChainKit.CoinTransfer? {
        transfers.first { $0.asset.caseInsensitiveCompare("THOR.RUNE") == .orderedSame }
    }
}

extension ThorChainTransactionConverter {
    func transactionRecord(from transaction: ThorChainKit.Transaction) -> ThorChainTransactionRecord {
        let incoming = runeTransfer(in: transaction.incoming)
        let outgoing = runeTransfer(in: transaction.outgoing)

        if transaction.type.caseInsensitiveCompare("send") == .orderedSame,
           let incoming,
           let outgoing
        {
            if incoming.address == ownAddress {
                return ThorChainOutgoingTransactionRecord(
                    source: source,
                    transaction: transaction,
                    to: outgoing.address,
                    value: appValue(amount: incoming.amount, sign: .minus),
                    sentToSelf: outgoing.address == ownAddress
                )
            }

            if outgoing.address == ownAddress {
                return ThorChainIncomingTransactionRecord(
                    source: source,
                    transaction: transaction,
                    from: incoming.address,
                    value: appValue(amount: outgoing.amount, sign: .plus)
                )
            }
        }

        return ThorChainTransactionRecord(source: source, transaction: transaction)
    }
}
