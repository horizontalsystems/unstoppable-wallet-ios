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
                previousBlockHeaderReversedHex: "000000000000004b68d8b5453cf38c485b1b42d564b6a1d8487ec5ce662622ea",
                merkleRootReversedHex: "fde234b11907f3f6d45633ab11a1ba0db59f8aabecf5879d1ef301ef091f4f44",
                timestamp: 1532135309,
                bits: 425766046,
                nonce: 3687858789
        )
        let preCheckpointBlock = BlockCreator.shared.create(withHeader: preCheckPointHeader, height: 1354751)
        preCheckpointBlock.synced = true

        let checkPointHeader = BlockHeader(
                version: 536870912,
                previousBlockHeaderReversedHex: "0000000000000051bff2f64c9078fb346d6a2a209ba5c3ffa0048c6b7027e47f",
                merkleRootReversedHex: "992c07e1a7b9a53ae3b8764333324396570fce24c49b8de7ed87fb1346df62a7",
                timestamp: 1532137995,
                bits: 424253525,
                nonce: 1665657862
        )
        let checkpointBlock = BlockCreator.shared.create(withHeader: checkPointHeader, previousBlock: preCheckpointBlock)
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
//        if let address = realm.objects(Address.self).first {
//            print("First Address: \(address.index) --- \(address.external) --- \(address.base58)")
//        }
//        if let address = realm.objects(Address.self).last {
//            print("Last Address: \(address.index) --- \(address.external) --- \(address.base58)")
//        }
    }

    public func connectToPeer() {
        _ = BlockSyncer.shared
        PeerManager.shared.connect()
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
        let walletManager = self.walletManager

        return Observable.create { observer in
            var addresses = [Address]()

//            for i in 0...20 {
//                if let address = try? walletManager!.wallet.receiveAddress(index: UInt32(i)) {
//                    addresses.append(address)
//                }
//                if let address = try? walletManager.wallet.changeAddress(index: UInt32(i)) {
//                    addresses.append(address)
//                }
//            }

            observer.onNext(addresses)
            observer.onCompleted()

            return Disposables.create()
        }
    }

}
