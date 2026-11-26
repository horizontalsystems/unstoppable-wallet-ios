import BigInt
import Foundation
import MarketKit
import NearKit

/// Turns a kit transaction into a record from the account's point of view (Android
/// `NearTransactionConverter`): the net change of each asset across the whole transaction. One
/// asset moving is a send or a receive; several (a swap, a wrap) are one contract call listing each,
/// so every wallet the transaction appears in sees the same row.
class NearTransactionConverter {
    /// the kit's failure value for a transaction whose block hash expired before inclusion
    static let expiredFailure = "expired"

    private let accountId: String
    private let source: TransactionSource
    private let baseToken: Token
    private let coinManager: ICoinManager
    private let ftMetadata: (String) async throws -> FtMetadata

    init(accountId: String, source: TransactionSource, baseToken: Token, coinManager: ICoinManager, ftMetadata: @escaping (String) async throws -> FtMetadata) {
        self.accountId = accountId
        self.source = source
        self.baseToken = baseToken
        self.coinManager = coinManager
        self.ftMetadata = ftMetadata
    }

    /// `resolvesUnknownMetadata: false` skips the contract metadata read for tokens missing from
    /// MarketKit: the spam scan needs only the kind of value, and a network round trip per unknown
    /// contract would hold up the first history page behind it.
    func transactionRecord(transaction: NearKit.Transaction, resolvesUnknownMetadata: Bool = true) async -> NearTransactionRecord {
        let type = await type(transaction: transaction, resolvesUnknownMetadata: resolvesUnknownMetadata)
        let signed = transaction.isSigner(accountId: accountId)
        let fee = signed ? transaction.fee.map { nearValue(yocto: $0, negate: false) } : nil

        return NearTransactionRecord(
            source: source,
            hash: transaction.hash,
            blockHeight: transaction.blockHeight,
            timestamp: transaction.timestamp,
            pending: transaction.isPending,
            failed: transaction.isFailed,
            expired: transaction.failure == Self.expiredFailure,
            signed: signed,
            type: type,
            fee: fee
        )
    }

    private func type(transaction tx: NearKit.Transaction, resolvesUnknownMetadata: Bool) async -> NearTransactionRecord.`Type` {
        let signed = tx.isSigner(accountId: accountId)
        let onlyTransfers = !tx.actions.isEmpty && tx.actions.allSatisfy { $0.type == "Transfer" }
        let method = tx.actions.first { $0.methodName != nil }?.methodName ?? tx.actions.first?.type

        let moves = netMoves(transaction: tx)

        if moves.isEmpty {
            if let transfer = tx.ftTransfers.first(where: { $0.from == accountId && $0.to == accountId }) {
                let value = await ftValue(contractId: transfer.contractId, amount: transfer.amount, negate: true, resolvesUnknownMetadata: resolvesUnknownMetadata)
                return .send(value: value, to: accountId, sentToSelf: true, memo: transfer.memo)
            }
            // a failed send moved nothing; it shows what was sent, marked failed
            if signed, onlyTransfers {
                let sent = tx.actions.reduce(BigUInt(0)) { $0 + ($1.deposit ?? 0) }
                return .send(value: nearValue(yocto: sent, negate: true), to: tx.receiverId, sentToSelf: tx.receiverId == accountId, memo: nil)
            }
            return .contractCall(contractId: tx.receiverId, method: method, incoming: [], outgoing: [])
        }

        var incoming = [TransferEvent]()
        var outgoing = [TransferEvent]()
        for move in moves {
            let gained = move.change > 0
            let value: AppValue
            if let contractId = move.contractId {
                value = await ftValue(contractId: contractId, amount: move.change.magnitude, negate: !gained, resolvesUnknownMetadata: resolvesUnknownMetadata)
            } else {
                value = nearValue(yocto: move.change.magnitude, negate: !gained)
            }
            let event = TransferEvent(address: counterparty(transaction: tx, contractId: move.contractId, gained: gained), value: value)
            if gained {
                incoming.append(event)
            } else {
                outgoing.append(event)
            }
        }

        guard moves.count == 1, let move = moves.first, let event = (incoming + outgoing).first else {
            return .contractCall(contractId: tx.receiverId, method: method, incoming: incoming, outgoing: outgoing)
        }

        // NEAR paid into a contract call (a deposit, a fee for a service) is not a send to someone
        if move.contractId == nil, signed, !onlyTransfers {
            return .contractCall(contractId: tx.receiverId, method: method, incoming: incoming, outgoing: outgoing)
        }

        if move.change > 0 {
            return .receive(value: event.value, from: event.address, memo: memo(transaction: tx, contractId: move.contractId, gained: true))
        }
        return .send(value: event.value, to: event.address, sentToSelf: false, memo: memo(transaction: tx, contractId: move.contractId, gained: false))
    }

    /// Net change of each asset the transaction moved for the account, NEAR first (contract id nil).
    private func netMoves(transaction tx: NearKit.Transaction) -> [(contractId: String?, change: BigInt)] {
        var moves = [(contractId: String?, change: BigInt)]()
        let near = tx.nearMoved(accountId: accountId)
        if near != 0 {
            moves.append((nil, near))
        }
        for transfer in tx.ftTransfers {
            let change: BigInt
            if transfer.to == accountId {
                change = transfer.from == accountId ? 0 : BigInt(transfer.amount)
            } else if transfer.from == accountId {
                change = -BigInt(transfer.amount)
            } else {
                change = 0
            }
            if let index = moves.firstIndex(where: { $0.contractId == transfer.contractId }) {
                moves[index].change += change
            } else {
                moves.append((transfer.contractId, change))
            }
        }
        return moves.filter { $0.change != 0 }
    }

    /// The other side of the account's largest movement of one asset in the given direction.
    private func counterparty(transaction tx: NearKit.Transaction, contractId: String?, gained: Bool) -> String {
        guard let contractId else {
            let transfers = tx.nearTransfers.filter { $0.success && $0.kind == .transfer }
            let other: String?
            if gained {
                other = transfers.filter { $0.to == accountId && $0.from != accountId }.max { $0.amount < $1.amount }?.from
            } else {
                other = transfers.filter { $0.from == accountId && $0.to != accountId }.max { $0.amount < $1.amount }?.to
            }
            return other ?? (gained ? tx.signerId : tx.receiverId)
        }

        let transfers = tx.ftTransfers.filter { $0.contractId == contractId }
        let other: String?
        if gained {
            other = transfers.filter { $0.to == accountId }.max { $0.amount < $1.amount }?.from
        } else {
            other = transfers.filter { $0.from == accountId }.max { $0.amount < $1.amount }?.to
        }
        // nil for a mint or a burn: the contract is the other side
        return other ?? contractId
    }

    private func memo(transaction tx: NearKit.Transaction, contractId: String?, gained: Bool) -> String? {
        guard let contractId else {
            return nil
        }
        return tx.ftTransfers
            .filter { $0.contractId == contractId && (gained ? $0.to == accountId : $0.from == accountId) }
            .max { $0.amount < $1.amount }?
            .memo
    }

    private func nearValue(yocto: BigUInt, negate: Bool) -> AppValue {
        let value = NearAmount.toNear(yocto: yocto)
        return AppValue(token: baseToken, value: negate ? -value : value)
    }

    private func ftValue(contractId: String, amount: BigUInt, negate: Bool, resolvesUnknownMetadata: Bool) async -> AppValue {
        let query = TokenQuery(blockchainType: .near, tokenType: .nep141(contractId: contractId))

        if let token = try? coinManager.token(query: query) {
            let value = Decimal(bigUInt: amount, decimals: token.decimals) ?? 0
            return AppValue(token: token, value: negate ? -value : value)
        }

        // Not a known token: its metadata is read from the contract (cached by the kit) so the
        // amount has the right scale. Unreadable metadata shows the raw amount under the contract id.
        var metadata: FtMetadata?
        if resolvesUnknownMetadata {
            metadata = try? await ftMetadata(contractId)
        }
        let decimals = metadata?.decimals ?? 0
        let name = metadata.map(\.name).flatMap { $0.trimmingCharacters(in: .whitespaces).isEmpty ? nil : $0 } ?? contractId
        let code = metadata?.symbol ?? contractId
        let value = Decimal(bigUInt: amount, decimals: decimals) ?? 0

        return AppValue(tokenName: name, tokenCode: code, tokenDecimals: decimals, value: negate ? -value : value)
    }
}
