import Foundation
import RealmSwift
import RxSwift

class AdapterManager {
    var adapters: [IAdapter] = []

    var subject: PublishSubject<Void> = PublishSubject()

    init(words: [String]) {
        adapters.append(BitcoinAdapter(words: words, networkType: .bitcoinRegTest))
        adapters.append(BitcoinAdapter(words: words, networkType: .bitcoinCashTestNet))
    }

    func start() {
        for adapter in adapters {
            do {
                try adapter.start()
            } catch {
                print("Could not start \(adapter.coin.name): \(error)")
            }
        }
    }

    func clear() {
        for adapter in adapters {
            try? adapter.clear()
        }

        adapters = []
    }

}
