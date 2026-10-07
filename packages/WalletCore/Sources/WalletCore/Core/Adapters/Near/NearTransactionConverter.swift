import BigInt
import Foundation
import MarketKit
import NearKit

/// Turns a kit transaction into a record from the account's point of view (Android
/// `NearTransactionConverter`). A token movement takes precedence over the NEAR attached to it
/// (the 1 yoctoNEAR of `ft_transfer`).
class NearTransactionConverter {
    // the kit's failure value for a transaction whose block hash expired before inclusion
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
        let fee = transaction.isSigner(accountId: accountId) ? transaction.fee.map { nearValue(yocto: $0, negate: false) } : nil

        return NearTransactionRecord(
            source: source,
            hash: transaction.hash,
            blockHeight: transaction.blockHeight,
            timestamp: transaction.timestamp,
            pending: transaction.isPending,
            failed: transaction.isFailed,
            expired: transaction.failure == Self.expiredFailure,
            type: type,
            fee: fee
        )
    }

    private func type(transaction: NearKit.Transaction, resolvesUnknownMetadata: Bool) async -> NearTransactionRecord.`Type` {
        if let transfer = transaction.ftTransfers.first(where: { $0.from == accountId || $0.to == accountId }) {
            return await ftType(transfer: transfer, resolvesUnknownMetadata: resolvesUnknownMetadata)
        }

        let netNear = transaction.nearNetChange(accountId: accountId)
        let onlyTransfers = !transaction.actions.isEmpty && transaction.actions.allSatisfy { $0.type == "Transfer" }
        let method = transaction.actions.first { $0.methodName != nil }?.methodName

        if transaction.isSigner(accountId: accountId) {
            if onlyTransfers {
                let sent = transaction.actions.reduce(BigUInt(0)) { $0 + ($1.deposit ?? 0) }
                return .send(
                    value: nearValue(yocto: sent, negate: true),
                    to: transaction.receiverId,
                    sentToSelf: transaction.receiverId == accountId,
                    memo: nil
                )
            }

            return .contractCall(
                contractId: transaction.receiverId,
                method: method ?? transaction.actions.first?.type,
                value: netNear == 0 ? nil : nearValue(yocto: netNear.magnitude, negate: netNear < 0)
            )
        }

        if netNear > 0 {
            let from = transaction.nearTransfers.first { $0.to == accountId && $0.success }?.from ?? transaction.signerId
            return .receive(value: nearValue(yocto: netNear.magnitude, negate: false), from: from, memo: nil)
        }

        return .contractCall(contractId: transaction.receiverId, method: method, value: nil)
    }

    private func ftType(transfer: FtTransfer, resolvesUnknownMetadata: Bool) async -> NearTransactionRecord.`Type` {
        let outgoing = transfer.from == accountId
        let value = await ftValue(transfer: transfer, negate: outgoing, resolvesUnknownMetadata: resolvesUnknownMetadata)

        if outgoing {
            return .send(value: value, to: transfer.to ?? transfer.contractId, sentToSelf: transfer.to == accountId, memo: transfer.memo)
        }

        return .receive(value: value, from: transfer.from ?? transfer.contractId, memo: transfer.memo)
    }

    private func nearValue(yocto: BigUInt, negate: Bool) -> AppValue {
        let value = NearAmount.toNear(yocto: yocto)
        return AppValue(token: baseToken, value: negate ? -value : value)
    }

    private func ftValue(transfer: FtTransfer, negate: Bool, resolvesUnknownMetadata: Bool) async -> AppValue {
        let query = TokenQuery(blockchainType: .near, tokenType: .nep141(contractId: transfer.contractId))

        if let token = try? coinManager.token(query: query) {
            let value = Decimal(bigUInt: transfer.amount, decimals: token.decimals) ?? 0
            return AppValue(token: token, value: negate ? -value : value)
        }

        // Not a known token: its metadata is read from the contract (cached by the kit) so the
        // amount has the right scale. Unreadable metadata shows the raw amount under the contract id.
        var metadata: FtMetadata?
        if resolvesUnknownMetadata {
            metadata = try? await ftMetadata(transfer.contractId)
        }
        let decimals = metadata?.decimals ?? 0
        let name = metadata.map(\.name).flatMap { $0.trimmingCharacters(in: .whitespaces).isEmpty ? nil : $0 } ?? transfer.contractId
        let code = metadata?.symbol ?? transfer.contractId
        let value = Decimal(bigUInt: transfer.amount, decimals: decimals) ?? 0

        return AppValue(tokenName: name, tokenCode: code, tokenDecimals: decimals, value: negate ? -value : value)
    }
}
