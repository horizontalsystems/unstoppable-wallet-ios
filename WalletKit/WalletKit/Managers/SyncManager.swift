import Foundation
import RxSwift
import RealmSwift

public class SyncManager {
    public static let shared = SyncManager()

    public enum SyncStatus {
        case syncing
        case synced
        case error
    }

    private let disposeBag = DisposeBag()

    weak var walletManager: WalletManager?
    weak var apiManager: ApiManager?
    weak var exchangeRatesApiManager: ApiManager?

    public let syncSubject = BehaviorSubject<SyncStatus>(value: .synced)

    private var status: SyncStatus = .synced {
        didSet {
            syncSubject.onNext(status)
        }
    }

    init() {
        let preCheckPointHeader = BlockHeader(
                version: 536870912,
                previousBlockHeaderReversedHex: "00000000000000c6721126859c1f2d289eb3f9beff79388f596f332ae8d3e3a8",
                merkleRootReversedHex: "77bb66cd8075995f05ef82c727cfa407769ee70607f16c589f594e0dbb23f881",
                timestamp: 1531213571,
                bits: 436273151,
                nonce: 3537712057
        )
        let preCheckpointBlock = BlockFactory.shared.block(withHeader: preCheckPointHeader, height: 1352735)
        preCheckpointBlock.synced = true

        let checkPointHeader = BlockHeader(
                version: 536870912,
                previousBlockHeaderReversedHex: "00000000000000c9a91d8277c58eab3bfda59d3068142dd54216129e5597ccbd",
                merkleRootReversedHex: "076c5847dbde99ed49cd75d7dbe63c3d3bb9399b135d1639d6169b8a5510913b",
                timestamp: 1531214479,
                bits: 425766046,
                nonce: 1076882637
        )
        let checkpointBlock = BlockFactory.shared.block(withHeader: checkPointHeader, previousBlock: preCheckpointBlock)
        checkpointBlock.synced = true

        let walletManager = WalletManager.shared
        var addresses = [Address]()

        for i in 0...4 {
            if let address = try? walletManager.wallet.receiveAddress(index: i) {
                addresses.append(address)
            }
            if let address = try? walletManager.wallet.changeAddress(index: i) {
                addresses.append(address)
            }
        }

        let realm = try! Realm()
        try? realm.write {
            realm.add(preCheckpointBlock, update: true)
            realm.add(checkpointBlock, update: true)
            realm.add(addresses, update: true)
        }

        WalletKitProvider.shared.add(transactionListener: self)



        let unspentOutputs = realm.objects(TransactionOutput.self)
                .filter("isMine = %@", true)
                .filter("inputs.@count == %@", 0)

        var balance = 0

        for output in unspentOutputs {
            balance += output.value
            print("OUTPUT: \(output.value) -- \(output.transaction.reversedHashHex)")
        }

        print("Balance: \(Double(balance) / 100000000)")
    }

    public func showRealmInfo() {
        let realm = try! Realm()
        let blockCount = realm.objects(Block.self).count
        let addressCount = realm.objects(Address.self).count

        print("BLOCK COUNT: \(blockCount)")
        if let block = realm.objects(Block.self).first {
            print("First Block: \(block.height) --- \(block.reversedHeaderHashHex)")
        }
        if let block = realm.objects(Block.self).last {
            print("Last Block: \(block.height) --- \(block.reversedHeaderHashHex)")
        }

        print("ADDRESS COUNT: \(addressCount)")
        if let address = realm.objects(Address.self).first {
            print("First Address: \(address.index) --- \(address.external) --- \(address.base58)")
        }
        if let address = realm.objects(Address.self).last {
            print("Last Address: \(address.index) --- \(address.external) --- \(address.base58)")
        }
    }

    public func connectToPeer() {
        _ = BlockSyncer.shared
        PeerGroup.shared.connect()
    }

    private func initialSync() {
        status = .syncing

        Observable.merge(unspentOutputsObservable(), exchangeRatesObservable(), transactionsObservable())
                .subscribeInBackground(disposeBag: disposeBag, onError: { [weak self] error in
                    print("SYNC ERROR: \(error)")
                    self?.status = .error
                }, onCompleted: { [weak self] in
                    self?.status = .synced
                })
    }

    private func unspentOutputsObservable() -> Observable<Void> {
        guard let apiManager = self.apiManager else {
            return Observable.empty()
        }

        return addressesObservable().flatMap { addresses in
            return apiManager.getUnspentOutputs(addresses: addresses.map { "\($0)" })
                    .do(onNext: { unspentOutputs in
                        let balance = Balance()
                        balance.coinCode = "BTC"
                        balance.amount = unspentOutputs.map { Double($0.value) / 100000000 }.reduce(0, { x, y in  x + y })

                        let realm = try! Realm()
                        try? realm.write {
                            realm.add(balance, update: true)
                        }
                    })
                    .map { _ in Void() }
        }
    }

    private func exchangeRatesObservable() -> Observable<Void> {
        guard let exchangeRatesApiManager = self.exchangeRatesApiManager else {
            return Observable.empty()
        }

        return exchangeRatesApiManager.getExchangeRates()
                .do(onNext: { rates in
                    let exchangeRate = ExchangeRate()
                    exchangeRate.code = "BTC"
                    exchangeRate.value = rates["USD"] ?? 0

                    let realm = try! Realm()
                    try? realm.write {
                        realm.add(exchangeRate, update: true)
                    }
                })
                .map { _ in Void() }
    }

    private func transactionsObservable() -> Observable<Void> {
        guard let apiManager = self.apiManager else {
            return Observable.empty()
        }

        return addressesObservable().flatMap { addresses in
            return apiManager.getTransactions(addresses: addresses.map { "\($0)" })
                    .do(onNext: { transactions in
                        let records = transactions.map { tx -> TransactionRecord in
                            let record = TransactionRecord()
                            record.transactionHash = tx.hash
                            record.coinCode = "BTC"
                            record.amount = 12300000
                            record.blockHeight = tx.blockHeight
                            record.timestamp = tx.time
                            return record
                        }

                        let realm = try! Realm()
                        try? realm.write {
                            for record in records {
                                realm.add(record, update: true)
                            }
                        }
                    })
                    .map { _ in Void() }
        }
    }

    private func addressesObservable() -> Observable<[Address]> {
//        let walletManager = self.walletManager

        return Observable.create { observer in
//            var addresses = [Address]()

//            for i in 0...20 {
//                if let address = try? walletManager!.wallet.receiveAddress(index: UInt32(i)) {
//                    addresses.append(address)
//                }
//                if let address = try? walletManager.wallet.changeAddress(index: UInt32(i)) {
//                    addresses.append(address)
//                }
//            }

//            observer.onNext(addresses)
            observer.onCompleted()

            return Disposables.create()
        }
    }

}

extension SyncManager: TransactionListener {
    public func inserted(transactions: [Transaction]) {
        handle(transactions: transactions)
    }

    public func modified(transactions: [Transaction]) {
        handle(transactions: transactions)
    }

    private func handle(transactions: [Transaction]) {
        let records = transactions.map { tx -> TransactionRecord in
            var totalInput: Int = 0
            var totalOutput: Int = 0

            for output in tx.inputs.flatMap({ $0.previousOutput }).filter({ $0.isMine }) {
                totalInput += output.value
            }

            for output in tx.outputs.filter({ $0.isMine }) {
                totalOutput += output.value
            }

            let record = TransactionRecord()
            record.transactionHash = tx.reversedHashHex
            record.coinCode = "BTC"
            record.amount = Int(totalOutput - totalInput)
            record.blockHeight = tx.block?.height ?? 0
            record.timestamp = tx.block?.header.timestamp ?? 0
            record.incoming = record.amount > 0
            return record
        }

        let realm = try! Realm()
        try? realm.write {
            for record in records {
                realm.add(record, update: true)
            }
        }
    }

}
