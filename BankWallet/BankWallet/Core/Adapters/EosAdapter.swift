import EosKit
import RxSwift

class EosAdapter {
    private let irreversibleThreshold = 330

    private let eosKit: EosKit
    private let asset: Asset

    let wallet: Wallet
    let decimal: Int = 4

    init(wallet: Wallet, eosKit: EosKit, token: String, symbol: String) {
        self.wallet = wallet
        self.eosKit = eosKit

        asset = eosKit.register(token: token, symbol: symbol)
    }

    private func transactionRecord(fromTransaction transaction: Transaction) -> TransactionRecord {
        let from = TransactionAddress(
                address: transaction.from,
                mine: transaction.from == eosKit.account
        )

        let to = TransactionAddress(
                address: transaction.to,
                mine: transaction.to == eosKit.account
        )

        return TransactionRecord(
                transactionHash: transaction.id,
                transactionIndex: 0,
                interTransactionIndex: transaction.actionSequence,
                blockHeight: transaction.blockNumber,
                amount: transaction.quantity.amount * (from.mine ? -1 : 1),
                date: transaction.date,
                from: [from],
                to: [to]
        )
    }

}

extension EosAdapter: IAdapter {

    var confirmationsThreshold: Int {
        return irreversibleThreshold
    }

    var refreshable: Bool {
        return true
    }

    func start() {
        // started via EosKitManager
    }

    func stop() {
        // stopped via EosKitManager
    }

    func refresh() {
        // refreshed via EosKitManager
    }

    var lastBlockHeight: Int? {
        return eosKit.irreversibleBlockHeight.map { $0 + irreversibleThreshold }
    }

    var lastBlockHeightUpdatedObservable: Observable<Void> {
        return eosKit.irreversibleBlockHeightObservable.map { _ in () }
    }

    var state: AdapterState {
        switch asset.syncState {
        case .synced: return .synced
        case .notSynced: return .notSynced
        case .syncing: return .syncing(progress: 50, lastBlockDate: nil)
        }
    }

    var stateUpdatedObservable: Observable<Void> {
        return asset.syncStateObservable.map { _ in () }
    }

    var balance: Decimal {
        return asset.balance
    }

    var balanceUpdatedObservable: Observable<Void> {
        return asset.balanceObservable.map { _ in () }
    }

    var transactionRecordsObservable: Observable<[TransactionRecord]> {
        return asset.transactionsObservable.map { [weak self] in
            $0.compactMap { self?.transactionRecord(fromTransaction: $0) }
        }
    }

    func transactionsSingle(from: (hash: String, interTransactionIndex: Int)?, limit: Int) -> Single<[TransactionRecord]> {
        return eosKit.transactionsSingle(asset: asset, fromActionSequence: from?.interTransactionIndex, limit: limit)
                .map { [weak self] transactions -> [TransactionRecord] in
                    return transactions.compactMap { self?.transactionRecord(fromTransaction: $0) }
                }
    }

    func sendSingle(to address: String, amount: Decimal, feeRatePriority: FeeRatePriority) -> Single<Void> {
        return eosKit.sendSingle(asset: asset, to: address, amount: amount, memo: "from Unstoppable Wallet")
                .map { _ in () }
    }

    func availableBalance(for address: String?, feeRatePriority: FeeRatePriority) -> Decimal {
        return asset.balance
    }

    func fee(for value: Decimal, address: String?, feeRatePriority: FeeRatePriority) -> Decimal {
        return 0
    }

    func validate(address: String) throws {
    }

    func validate(amount: Decimal, address: String?, feeRatePriority: FeeRatePriority) -> [SendStateError] {
        return []
    }

    func parse(paymentAddress: String) -> PaymentRequestAddress {
        return PaymentRequestAddress(address: paymentAddress, amount: nil)
    }

    var receiveAddress: String {
        return eosKit.account
    }

    var debugInfo: String {
        return ""
    }

}
