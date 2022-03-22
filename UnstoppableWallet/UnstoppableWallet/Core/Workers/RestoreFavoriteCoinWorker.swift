import MarketKit
import StorageKit

class RestoreFavoriteCoinWorker {
    private let localStorageKey = "restore-favorite-coin-worker-run"

    private let marketKit: MarketKit.Kit
    private let favoritesManager: FavoritesManager
    private let localStorage: StorageKit.ILocalStorage
    private let storage: FavoriteCoinRecordStorage

    init(marketKit: MarketKit.Kit, favoritesManager: FavoritesManager, localStorage: StorageKit.ILocalStorage, storage: FavoriteCoinRecordStorage) {
        self.marketKit = marketKit
        self.favoritesManager = favoritesManager
        self.localStorage = localStorage
        self.storage = storage
    }

}

extension RestoreFavoriteCoinWorker {

    func run() throws {
        let alreadyRun: Bool = localStorage.value(for: localStorageKey) ?? false

        guard !alreadyRun else {
            return
        }

        localStorage.set(value: true, for: localStorageKey)

        let oldRecords = storage.favoriteCoinRecords_v_0_22
        let oldCoinTypes = oldRecords.map { $0.coinType }

        var coinsUids = Set<String>()

        for oldCoinType in oldCoinTypes {
            switch oldCoinType {
            case .bitcoin: coinsUids.insert("bitcoin")
            case .bitcoinCash: coinsUids.insert("bitcoin-cash")
            case .litecoin: coinsUids.insert("litecoin")
            case .dash: coinsUids.insert("dash")
            case .zcash: coinsUids.insert("zcash")
            case .ethereum: coinsUids.insert("ethereum")
            case .binanceSmartChain: coinsUids.insert("binancecoin")
            case .erc20, .bep20, .bep2:
                if let platformCoin = try marketKit.platformCoin(coinType: oldCoinType) {
                    coinsUids.insert(platformCoin.coin.uid)
                }
            case .unsupported(let type):
                if let fullCoin = try marketKit.fullCoins(coinUids: [type]).first {
                    coinsUids.insert(fullCoin.coin.uid)
                }
            default: ()
            }
        }

        favoritesManager.add(coinUids: Array(coinsUids))
    }

}
