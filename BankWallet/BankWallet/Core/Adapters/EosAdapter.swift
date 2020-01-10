import EosKit
import RxSwift

class EosAdapter {
    private let irreversibleThreshold = 330

    private let eosKit: EosKit
    private let asset: Asset

    init(eosKit: EosKit, token: String, symbol: String, decimal: Int) {
        self.eosKit = eosKit

        asset = eosKit.register(token: token, symbol: symbol, decimalCount: decimal)
    }

    private func transactionRecord(fromTransaction transaction: Transaction) -> TransactionRecord {
        var type: TransactionType

        if transaction.from == eosKit.account {
            type = .outgoing
        } else if transaction.to == eosKit.account {
            type = .incoming
        } else {
            // EOS funds cannot be sent to self, so this is practically impossible
            type = .sentToSelf
        }

        return TransactionRecord(
                uid: transaction.id,
                transactionHash: transaction.id,
                transactionIndex: 0,
                interTransactionIndex: transaction.actionSequence,
                type: type,
                blockHeight: transaction.blockNumber,
                amount: transaction.quantity.amount,
                fee: nil,
                date: transaction.date,
                failed: false,
                from: transaction.from,
                to: transaction.to,
                lockInfo: nil,
                conflictingHash: nil
        )
    }

    static func validate(account: String) throws {
        //regex taken from here: https://github.com/EOSIO/eos/issues/955#issuecomment-351866599
        let regex = try! NSRegularExpression(pattern: "^[a-z][a-z1-5\\.]{0,10}([a-z1-5]|^\\.)[a-j1-5]?$")
        guard regex.firstMatch(in: account, range: NSRange(location: 0, length: account.count)) != nil else {
            throw ValidationError.invalidAccount
        }
    }

    static func validate(privateKey: String) throws {
        try EosKit.validate(privateKey: privateKey)
    }

}

extension EosAdapter {
    enum ValidationError: Error {
        case invalidAccount
    }

    static func clear(except excludedWalletIds: [String]) throws {
        try EosKit.clear(exceptFor: excludedWalletIds)
    }

}

extension EosAdapter: IAdapter {

    func start() {
        // started via EosKitManager
    }

    func stop() {
        // stopped via EosKitManager
    }

    func refresh() {
        // refreshed via EosKitManager
    }

    var debugInfo: String {
        return ""
    }

}

extension EosAdapter: IBalanceAdapter {

    var state: AdapterState {
        switch asset.syncState {
        case .synced: return .synced
        case .notSynced: return .notSynced
        case .syncing: return .syncing(progress: 50, lastBlockDate: nil)
        }
    }

    var stateUpdatedObservable: Observable<Void> {
        asset.syncStateObservable.map { _ in () }
    }

    var balance: Decimal {
        asset.balance
    }

    var balanceUpdatedObservable: Observable<Void> {
        asset.balanceObservable.map { _ in () }
    }

}

extension EosAdapter: ISendEosAdapter {

    var availableBalance: Decimal {
        asset.balance
    }

    func validate(account: String) throws {
        try EosAdapter.validate(account: account)
    }

    func sendSingle(amount: Decimal, account: String, memo: String?) -> Single<Void> {
        eosKit.sendSingle(asset: asset, to: account, amount: amount, memo: memo ?? "")
                .map { _ in () }
    }

}

extension EosAdapter: ITransactionsAdapter {

    var confirmationsThreshold: Int {
        irreversibleThreshold
    }

    var lastBlockInfo: LastBlockInfo? {
        eosKit.irreversibleBlockHeight.map { LastBlockInfo(height: $0 + irreversibleThreshold, timestamp: nil) }
    }

    var lastBlockUpdatedObservable: Observable<Void> {
        eosKit.irreversibleBlockHeightObservable.map { _ in () }
    }

    var transactionRecordsObservable: Observable<[TransactionRecord]> {
        asset.transactionsObservable.map { [weak self] in
            $0.compactMap { self?.transactionRecord(fromTransaction: $0) }
        }
    }

    func transactionsSingle(from: TransactionRecord?, limit: Int) -> Single<[TransactionRecord]> {
        eosKit.transactionsSingle(asset: asset, fromActionSequence: from?.interTransactionIndex, limit: limit)
                .map { [weak self] transactions -> [TransactionRecord] in
                    transactions.compactMap { self?.transactionRecord(fromTransaction: $0) }
                }
    }

}

extension EosAdapter: IDepositAdapter {

    var receiveAddress: String {
        eosKit.account
    }

}
