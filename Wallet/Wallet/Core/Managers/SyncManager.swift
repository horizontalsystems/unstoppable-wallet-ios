import Foundation
import WalletKit
import RxSwift
import RealmSwift

class SyncManager {
    let disposeBag = DisposeBag()

    func check() {
        let realm = try! Realm()
        print("Balances: \(realm.objects(Balance.self).count)")
        print("Rates: \(realm.objects(ExchangeRate.self).count)")
        print("Transactions: \(realm.objects(TransactionRecord.self).count)")
    }

    func performInitialSync() {
//        guard let words = Factory.instance.userDefaultsStorage.savedWords else {
//            return
//        }
//
//        let seed = Mnemonic.seed(mnemonic: words)
//        let hdWallet = HDWallet(seed: seed, network: .testnet)
//
//        var addresses = [Address]()
//
//        for i in 0...20 {
//            if let address = try? hdWallet.receiveAddress(index: UInt32(i)) {
//                addresses.append(address)
//            }
//            if let address = try? hdWallet.changeAddress(index: UInt32(i)) {
//                addresses.append(address)
//            }
//        }
//
//        Factory.instance.testnetNetworkManager.getUnspentOutputs(addresses: addresses.map { "\($0)" }).subscribeAsync(disposeBag: disposeBag, onNext: { unspentOutputs in
//            let balance = Balance()
//            balance.coinCode = "BTC"
//            balance.amount = unspentOutputs.map { Double($0.value) / 100000000 }.reduce(0, { x, y in  x + y })
//
//            let realm = try! Realm()
//            try? realm.write {
//                realm.add(balance, update: true)
//            }
//        })
//
//        Factory.instance.testnetNetworkManager.getTransactions(addresses: addresses.map { "\($0)" }).subscribeAsync(disposeBag: disposeBag, onNext: { transactions in
//            let records = transactions.map { tx -> TransactionRecord in
//                let record = TransactionRecord()
//                record.transactionHash = tx.hash
//                record.coinCode = "BTC"
//                record.amount = 12300000
//                record.blockHeight = tx.blockHeight
//                record.timestamp = tx.time
//                return record
//            }
//
//            let realm = try! Realm()
//            try? realm.write {
//                for record in records {
//                    realm.add(record, update: true)
//                }
//            }
//        })
//
//        Factory.instance.networkManager.getExchangeRates().subscribeAsync(disposeBag: disposeBag, onNext: { rates in
//            let exchangeRate = ExchangeRate()
//            exchangeRate.code = "BTC"
//            exchangeRate.value = rates["USD"] ?? 0
//
//            let realm = try! Realm()
//            try? realm.write {
//                realm.add(exchangeRate, update: true)
//            }
//        })
    }

}
