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

    static func validate(account: String) throws {
        let regex = try! NSRegularExpression(pattern: "^[a-z1-5]{1,12}$")
        guard regex.firstMatch(in: account, range: NSRange(location: 0, length: account.count)) != nil else {
            throw RestoreEosValidationError.invalidAccount
        }
    }

    static func validate(privateKey: String) throws {
        try EosKit.validate(privateKey: privateKey)
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

    func sendSingle(params: [String : Any]) -> Single<Void> {
        guard let amount: Decimal = params[AdapterField.amount.rawValue] as? Decimal,
              let address: String = params[AdapterField.address.rawValue] as? String else {
            return Single.error(AdapterError.wrongParameters)
        }

        let memo = params[AdapterField.memo.rawValue] as? String
        return eosKit.sendSingle(asset: asset, to: address, amount: amount, memo: memo ?? "from Unstoppable Wallet")
                .map { _ in () }
    }

    func availableBalance(params: [String : Any]) -> Decimal {
        return asset.balance
    }

    func fee(params: [String : Any]) -> Decimal {
        return 0
    }

    func validate(address: String) throws {
    }

    func validate(params: [String : Any]) -> [SendStateError] {
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
