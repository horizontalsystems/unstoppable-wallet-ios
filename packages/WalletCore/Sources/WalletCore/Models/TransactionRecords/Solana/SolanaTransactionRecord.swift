import Foundation
import MarketKit
import SolanaKit

class SolanaTransactionRecord: TransactionRecord {
    let fee: AppValue?
    let pending: Bool

    init(transaction: SolanaKit.Transaction, baseToken: Token, source: TransactionSource) {
        pending = transaction.pending

        if let rawFee = transaction.decimalFee {
            let scaledFee = Decimal(sign: .plus, exponent: -baseToken.decimals, significand: rawFee)
            fee = AppValue(token: baseToken, value: scaledFee)
        } else {
            fee = nil
        }

        super.init(
            source: source,
            uid: transaction.hash,
            transactionHash: transaction.hash,
            transactionIndex: 0,
            blockHeight: transaction.pending ? nil : 0,
            confirmationsThreshold: 12,
            date: Date(timeIntervalSince1970: TimeInterval(transaction.timestamp)),
            failed: transaction.error != nil,
            paginationRaw: transaction.hash
        )
    }

    override func status(lastBlockHeight _: Int?) -> TransactionStatus {
        if failed { return .failed }
        return pending ? .pending : .completed
    }
}

extension SolanaTransactionRecord {
    struct Transfer {
        let address: String?
        let value: AppValue
    }
}

class SolanaIncomingTransactionRecord: SolanaTransactionRecord {
    let from: String?
    let value: AppValue

    init(transaction: SolanaKit.Transaction, baseToken: Token, source: TransactionSource, from: String?, value: AppValue) {
        self.from = from
        self.value = value
        super.init(transaction: transaction, baseToken: baseToken, source: source)
    }

    override var mainValue: AppValue? {
        value
    }
}

class SolanaOutgoingTransactionRecord: SolanaTransactionRecord {
    let to: String?
    let value: AppValue
    let sentToSelf: Bool

    init(transaction: SolanaKit.Transaction, baseToken: Token, source: TransactionSource, to: String?, value: AppValue, sentToSelf: Bool) {
        self.to = to
        self.value = value
        self.sentToSelf = sentToSelf
        super.init(transaction: transaction, baseToken: baseToken, source: source)
    }

    override var mainValue: AppValue? {
        value
    }
}

class SolanaUnknownTransactionRecord: SolanaTransactionRecord {
    let incomingTransfers: [Transfer]
    let outgoingTransfers: [Transfer]

    init(transaction: SolanaKit.Transaction, baseToken: Token, source: TransactionSource, incomingTransfers: [Transfer], outgoingTransfers: [Transfer]) {
        self.incomingTransfers = incomingTransfers
        self.outgoingTransfers = outgoingTransfers
        super.init(transaction: transaction, baseToken: baseToken, source: source)
    }
}

// A DEX swap detected via the transaction's recognized program ids (SolanaKit `KnownPrograms`,
// e.g. Jupiter) — the Solana counterpart of the EVM `SwapTransactionRecord`. `valueIn` (paid) /
// `valueOut` (received) are nil while the transaction is still pending: the kit's pending record
// carries no balance changes yet, but the program id is known at send time, so the row can already
// render as "Swapped / <exchange>" instead of an unknown transaction.
class SolanaSwapTransactionRecord: SolanaTransactionRecord {
    let exchangeName: String
    let valueIn: AppValue?
    let valueOut: AppValue?

    init(transaction: SolanaKit.Transaction, baseToken: Token, source: TransactionSource, exchangeName: String, valueIn: AppValue?, valueOut: AppValue?) {
        self.exchangeName = exchangeName
        self.valueIn = valueIn
        self.valueOut = valueOut
        super.init(transaction: transaction, baseToken: baseToken, source: source)
    }

    override var mainValue: AppValue? {
        valueOut
    }
}
