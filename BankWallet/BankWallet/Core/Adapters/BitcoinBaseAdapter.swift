import BitcoinCore
import RxSwift

class BitcoinBaseAdapter {
    let decimal = 8
    var receiveAddressScriptType: ScriptType { return .p2pkh }
    var changeAddressScriptType: ScriptType { return .p2pkh }

    let wallet: Wallet

    private let abstractKit: AbstractKit
    private let coinRate: Decimal

    private let lastBlockHeightUpdatedSignal = Signal()
    private let stateUpdatedSignal = Signal()
    private let balanceUpdatedSignal = Signal()
    let transactionRecordsSubject = PublishSubject<[TransactionRecord]>()

    private(set) var state: AdapterState

    var receiveAddress: String {
        return abstractKit.receiveAddress(for: receiveAddressScriptType)
    }

    init(wallet: Wallet, abstractKit: AbstractKit) {
        self.wallet = wallet
        self.abstractKit = abstractKit

        coinRate = pow(10, decimal)

        state = .syncing(progress: 0, lastBlockDate: nil)
    }

    func transactionRecord(fromTransaction transaction: TransactionInfo) -> TransactionRecord {
        // for Bitcoin based adapters "from" addresses should be hidden
        let fromAddresses: [TransactionAddress] = []

        let toAddresses = transaction.to.map {
            TransactionAddress(address: $0.address, mine: $0.mine)
        }

        return TransactionRecord(
                transactionHash: transaction.transactionHash,
                transactionIndex: transaction.transactionIndex,
                interTransactionIndex: 0,
                blockHeight: transaction.blockHeight,
                amount: Decimal(transaction.amount) / coinRate,
                date: Date(timeIntervalSince1970: Double(transaction.timestamp)),
                from: fromAddresses,
                to: toAddresses
        )
    }

    func createSendError(from: Error) -> Error {
        return SendTransactionError.connection
    }

    class func kitMode(from syncMode: SyncMode) -> BitcoinCore.SyncMode {
        switch syncMode {
        case .fast: return .api
        case .slow: return .full
        case .new: return .newWallet
        }
    }

}

extension BitcoinBaseAdapter: IAdapter {

    var lastBlockHeightUpdatedObservable: Observable<Void> {
        return lastBlockHeightUpdatedSignal.asObservable()
    }

    var stateUpdatedObservable: Observable<Void> {
        return stateUpdatedSignal.asObservable()
    }

    var balanceUpdatedObservable: Observable<Void> {
        return balanceUpdatedSignal.asObservable()
    }

    var transactionRecordsObservable: Observable<[TransactionRecord]> {
        return transactionRecordsSubject.asObservable()
    }

    var balance: Decimal {
        return Decimal(abstractKit.balance) / coinRate
    }

    var confirmationsThreshold: Int {
        return 6
    }

    var lastBlockHeight: Int? {
        return abstractKit.lastBlockInfo?.height
    }

    var debugInfo: String {
        return abstractKit.debugInfo
    }

    func start() {
        abstractKit.start()
    }

    func stop() {
        abstractKit.stop()
    }

    func refresh() {
        // not called
    }

    private func convertToSatoshi(value: Decimal) -> Int {
        let coinValue: Decimal = value * coinRate
        return NSDecimalNumber(decimal: ValueFormatter.instance.round(value: coinValue, scale: 0, roundingMode: .plain)).intValue
    }

    func validate(address: String) throws {
        try abstractKit.validate(address: address)
    }

    func sendSingle(amount: Decimal, address: String, feeRate: Int) -> Single<Void> {
        let satoshiAmount = convertToSatoshi(value: amount)

        return Single.create { [weak self] observer in
            do {
                if let adapter = self {
                    _ = try adapter.abstractKit.send(to: address, value: satoshiAmount, feeRate: feeRate, changeScriptType: adapter.changeAddressScriptType)
                }
                observer(.success(()))
            } catch {
                observer(.error(self?.createSendError(from: error) ?? error))
            }

            return Disposables.create()
        }
    }

    func availableBalance(feeRate: Int, address: String?) -> Decimal {
        return max(0, balance - fee(amount: balance, feeRate: feeRate, address: address))
    }

    func fee(amount: Decimal, feeRate: Int, address: String?) -> Decimal {
        do {
            let amount = convertToSatoshi(value: amount)
            let fee = try abstractKit.fee(for: amount, toAddress: address, senderPay: true, feeRate: feeRate, changeScriptType: changeAddressScriptType)
            return Decimal(fee) / coinRate
        } catch BitcoinCoreErrors.UnspentOutputSelection.notEnough(let maxFee) {
            return Decimal(maxFee) / coinRate
        } catch {
            return 0
        }
    }

    func transactionsSingle(from: (hash: String, interTransactionIndex: Int)?, limit: Int) -> Single<[TransactionRecord]> {
        return abstractKit.transactions(fromHash: from?.hash, limit: limit)
                .map { [weak self] transactions -> [TransactionRecord] in
                    return transactions.compactMap {
                        self?.transactionRecord(fromTransaction: $0)
                    }
                }
    }

}

extension BitcoinBaseAdapter: BitcoinCoreDelegate {

    func transactionsUpdated(inserted: [TransactionInfo], updated: [TransactionInfo]) {
        var records = [TransactionRecord]()

        for info in inserted {
            records.append(transactionRecord(fromTransaction: info))
        }
        for info in updated {
            records.append(transactionRecord(fromTransaction: info))
        }

        transactionRecordsSubject.onNext(records)
    }

    func transactionsDeleted(hashes: [String]) {
    }

    func balanceUpdated(balance: Int) {
        balanceUpdatedSignal.notify()
    }

    func lastBlockInfoUpdated(lastBlockInfo: BlockInfo) {
        lastBlockHeightUpdatedSignal.notify()
    }

    public func kitStateUpdated(state: BitcoinCore.KitState) {
        switch state {
        case .synced:
            if case .synced = self.state {
                return
            }

            self.state = .synced
            stateUpdatedSignal.notify()
        case .notSynced:
            if case .notSynced = self.state {
                return
            }

            self.state = .notSynced
            stateUpdatedSignal.notify()
        case .syncing(let progress):
            let newProgress = Int(progress * 100)
            let newDate = abstractKit.lastBlockInfo?.timestamp.map { Date(timeIntervalSince1970: Double($0)) }

            if case let .syncing(currentProgress, currentDate) = self.state, newProgress == currentProgress {
                if let currentDate = currentDate, let newDate = newDate, currentDate.isSameDay(as: newDate) {
                    return
                }
            }

            self.state = .syncing(progress: newProgress, lastBlockDate: newDate)
            stateUpdatedSignal.notify()
        }
    }

}
