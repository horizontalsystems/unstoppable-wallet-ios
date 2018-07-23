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
        let header = BlockHeaderItem(
                version: 536870912,
                prevBlock: "0000000000000015868cb68ade5875a83c92d3efb7afc140e98e17abf6343dee".reversedData!,
                merkleRoot: "5fdc2a9c73000341987e8db5df903dad4f04dba5f5feedf62d00cb378c23682f".reversedData!,
                timestamp: 1532325895,
                bits: 424253525,
                nonce: 1376325361
        )

        let block = Block(blockHeader: header, height: 1355061)
        block.synced = true

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
            realm.add(block, update: true)
            realm.add(addresses, update: true)
        }
    }

    public func showRealmInfo() {
        let realm = try! Realm()
        let blockCount = realm.objects(Block.self).count
        let addressCount = realm.objects(Address.self).count

        print("BLOCK COUNT: \(blockCount)")
        print("ADDRESS COUNT: \(addressCount)")

        for block in realm.objects(Block.self) {
            print("\(block.height) --- \(block.reversedHeaderHashHex)")
        }
        for address in realm.objects(Address.self) {
            print("\(address.index) --- \(address.external) --- \(address.base58)")
        }
    }

    public func connectToPeer() {
        BlockSyncer.shared
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
