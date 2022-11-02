import Foundation
import EvmKit
import MarketKit

class EvmTransactionRecord: TransactionRecord {
    let transaction: Transaction
    let ownTransaction: Bool
    let fee: TransactionValue?

    init(source: TransactionSource, transaction: Transaction, baseToken: Token, ownTransaction: Bool, spam: Bool = false) {
        self.transaction = transaction
        let txHash = transaction.hash.hs.hexString
        self.ownTransaction = ownTransaction

        if let feeAmount = transaction.gasUsed ?? transaction.gasLimit, let gasPrice = transaction.gasPrice {
            let feeDecimal = Decimal(sign: .plus, exponent: -baseToken.decimals, significand: Decimal(feeAmount) * Decimal(gasPrice))
            fee = .coinValue(token: baseToken, value: feeDecimal)
        } else {
            fee = nil
        }

        super.init(
                source: source,
                uid: txHash,
                transactionHash: txHash,
                transactionIndex: transaction.transactionIndex ?? 0,
                blockHeight: transaction.blockNumber,
                confirmationsThreshold: BaseEvmAdapter.confirmationsThreshold,
                date: Date(timeIntervalSince1970: Double(transaction.timestamp)),
                failed: transaction.isFailed,
                spam: spam
        )
    }

    private func sameType(_ value: TransactionValue, _ value2: TransactionValue) -> Bool {
        switch (value, value2) {
        case let (.coinValue(lhsToken, _), .coinValue(rhsToken, _)): return lhsToken == rhsToken
        case let (.tokenValue(lhsTokenName, lhsTokenCode, lhsTokenDecimals, _), .tokenValue(rhsTokenName, rhsTokenCode, rhsTokenDecimals, _)): return lhsTokenName == rhsTokenName && lhsTokenCode == rhsTokenCode && lhsTokenDecimals == rhsTokenDecimals
        case let (.nftValue(lhsNftUid, _, _, _), .nftValue(rhsNftUid, _, _, _)): return lhsNftUid == rhsNftUid
        default: return false
        }
    }

    func combined(incomingEvents: [TransferEvent], outgoingEvents: [TransferEvent]) -> ([TransactionValue], [TransactionValue]) {
        let values = (incomingEvents + outgoingEvents).map { $0.value }
        var resultIncoming = [TransactionValue]()
        var resultOutgoing = [TransactionValue]()

        for value in values {
            if (resultIncoming + resultOutgoing).contains(where: { sameType(value, $0) }) {
                continue
            }

            let sameTypeValues = values.filter { sameType(value, $0) }
            let totalValue = sameTypeValues.map { $0.decimalValue ?? 0 }.reduce(0, +)
            let resultValue: TransactionValue

            switch value {
            case let .coinValue(token, _):
                resultValue = .coinValue(token: token, value: totalValue)
            case let .tokenValue(tokenName, tokenCode, tokenDecimals, _):
                resultValue = .tokenValue(tokenName: tokenName, tokenCode: tokenCode, tokenDecimals: tokenDecimals, value: totalValue)
            case let .nftValue(nftUid, _, tokenName, tokenSymbol):
                resultValue = .nftValue(nftUid: nftUid, value: totalValue, tokenName: tokenName, tokenSymbol: tokenSymbol)
            case let .rawValue(value):
                resultValue = .rawValue(value: value)
            }

            if totalValue > 0 {
                resultIncoming.append(resultValue)
            } else {
                resultOutgoing.append(resultValue)
            }
        }

        return (resultIncoming, resultOutgoing)
    }

}

extension EvmTransactionRecord {

    struct TransferEvent {
        let address: String
        let value: TransactionValue
    }

}
