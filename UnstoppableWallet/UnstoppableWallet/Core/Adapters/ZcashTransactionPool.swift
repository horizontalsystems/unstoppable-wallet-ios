import Foundation
import RxSwift
import ZcashLightClientKit

class ZcashTransactionPool {
    private var confirmedTransactions = Set<ZcashTransactionWrapper>()
    private var pendingTransactions = Set<ZcashTransactionWrapper>()

    private let accountId: AccountUUID
    private let synchronizer: Synchronizer
    private let receiveAddress: SaplingAddress

    init(accountId: AccountUUID, receiveAddress: SaplingAddress, synchronizer: Synchronizer) {
        self.accountId = accountId
        self.receiveAddress = receiveAddress
        self.synchronizer = synchronizer
    }

    private func transactions(filter: TransactionTypeFilter, address: String?) -> [ZcashTransactionWrapper] {
        var confirmedTransactions = confirmedTransactions
        var pendingTransactions = pendingTransactions
        switch filter {
        case .all: ()
        case .incoming:
            confirmedTransactions = confirmedTransactions.filter { !$0.isSentTransaction }
            pendingTransactions = pendingTransactions.filter { !$0.isSentTransaction }
        case .outgoing:
            confirmedTransactions = confirmedTransactions.filter(\.isSentTransaction)
            pendingTransactions = pendingTransactions.filter { !$0.isSentTransaction }
        default:
            confirmedTransactions = []
            pendingTransactions = []
        }

        var allTransactions = confirmedTransactions.union(pendingTransactions)
        if let address {
            allTransactions = allTransactions.filter { tx in
                tx.recipientAddress?.lowercased() == address.lowercased()
            }
        }

        return Array(allTransactions).sorted()
    }

    private func zcashTransactions(_ transactions: [ZcashTransaction.Overview], lastBlockHeight: Int) async -> [ZcashTransactionWrapper] {
        var wrapped = [ZcashTransactionWrapper]()
        for tx in transactions {
            if let tx = try? await transactionWithAdditional(tx: tx, lastBlockHeight: lastBlockHeight) {
                wrapped.append(tx)
            }
        }
        return wrapped
    }

    private func transactionWithAdditional(tx: ZcashTransaction.Overview, lastBlockHeight: Int) async throws -> ZcashTransactionWrapper? {
        let memos: [Memo] = await (try? synchronizer.getMemos(for: tx)) ?? []
        let firstMemo = memos
            .compactMap { $0.toString() }
            .first

        let recipients = await synchronizer.getRecipients(for: tx)

        return ZcashTransactionWrapper(accountId: accountId, tx: tx, memo: firstMemo, recipients: recipients, lastBlockHeight: lastBlockHeight)
    }

    private func sync(own: inout Set<ZcashTransactionWrapper>, incoming: [ZcashTransactionWrapper]) {
        incoming.forEach { transaction in own.insert(transaction) }
    }

    func initTransactions() async {
        let overviews = await synchronizer.transactions
//        let pending = await synchronizer.pendingTransactions

//        pendingTransactions = await Set(zcashTransactions(pending, lastBlockHeight: 0))
        confirmedTransactions = await Set(zcashTransactions(overviews, lastBlockHeight: 0))
    }

    func sync(transactions: [ZcashTransaction.Overview], lastBlockHeight: Int) async -> [ZcashTransactionWrapper] {
        let txs = await zcashTransactions(transactions, lastBlockHeight: lastBlockHeight)
        // TODO: sync pending and confirmed but How?
        sync(own: &confirmedTransactions, incoming: txs)
        return txs
    }

    func transaction(by hash: String) -> ZcashTransactionWrapper? {
        transactions(filter: .all, address: nil).first { $0.transactionHash == hash }
    }
}

extension ZcashTransactionPool {
    var all: [ZcashTransactionWrapper] {
        transactions(filter: .all, address: nil)
    }

    func transactionsSingle(paginationData: String?, filter: TransactionTypeFilter, descending: Bool, address: String? = nil, limit: Int?) -> RxSwift.Single<[ZcashTransactionWrapper]> {
        let transactions = transactions(filter: filter, address: address).sorted(by: descending ? (<) : (>))

        var limited: [ZcashTransactionWrapper]
        if let data = paginationData, let index = transactions.firstIndex(where: { $0.transactionHash == data }) {
            limited = Array(transactions.suffix(from: index + 1))
        } else {
            limited = transactions
        }

        if let limit {
            limited = Array(limited.prefix(limit))
        }

        return .just(limited)
    }
}

extension TransactionRecipient {
    var hasAddress: Bool {
        switch self {
        case .address: return true
        case .internalAccount: return false
        }
    }

    var address: String? {
        switch self {
        case let .address(recipient): return recipient.stringEncoded
        default: return nil
        }
    }
}
