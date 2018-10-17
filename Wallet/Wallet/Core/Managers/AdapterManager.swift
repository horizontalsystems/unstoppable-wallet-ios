import RealmSwift
import RxSwift

class AdapterManager {
    private(set) var adapters: [IAdapter] = []

    var subject: PublishSubject<Void> = PublishSubject()

    private let wordsManager: IWordsManager

    init(wordsManager: IWordsManager) {
        self.wordsManager = wordsManager
    }

}

extension AdapterManager: IAdapterManager {

    func start() {
        if let words = wordsManager.words {
            adapters.append(BitcoinAdapter(words: words, networkType: .bitcoinRegTest))
            adapters.append(BitcoinAdapter(words: words, networkType: .bitcoinCashTestNet))
            adapters.append(EthereumAdapter(words: words, network: .kovan))

            for adapter in adapters {
                adapter.start()
            }
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
