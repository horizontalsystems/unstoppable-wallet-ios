import Foundation
import RealmSwift
import RxSwift

class AdapterManager {
    static let shared = AdapterManager()

    var adapters = [IAdapter]()

    var subject = PublishSubject<Void>()

    func initAdapters(words: [String]) {
//        adapters.append(BitcoinAdapter(words: words))
//        adapters.append(BitcoinAdapter(words: words, networkType: .testNet))
        adapters.append(BitcoinAdapter(words: words, networkType: .regTest))
//        adapters.append(BitcoinAdapter(words: ["black", "correct", "snap", "west", "clever", "knock", "honey", "head", "divide", "admit", "file", "swarm"], networkType: .regTest))

        start()
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
