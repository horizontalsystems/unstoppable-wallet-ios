import RealmSwift
import RxSwift

class AdapterManager {
    private(set) var adapters: [IAdapter] = []

    var subject: PublishSubject<Void> = PublishSubject()

    init(words: [String]) {
        adapters.append(BitcoinAdapter(words: words, networkType: .bitcoinRegTest))
        adapters.append(BitcoinAdapter(words: words, networkType: .bitcoinCashTestNet))
        adapters.append(EthereumAdapter(words: words, network: .kovan))
    }

}

extension AdapterManager: IAdapterManager {

    func start() {
        for adapter in adapters {
            adapter.start()
        }
    }

    func refresh() {
        for adapter in adapters {
            adapter.refresh()
        }
    }

    func clear() {
        for adapter in adapters {
            adapter.clear()
        }

        adapters = []
    }

}
