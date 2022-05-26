import RxSwift
import RxRelay
import StorageKit
import MarketKit

class BalanceConversionManager {
    private let coinTypes: [CoinType] = [.bitcoin, .ethereum, .binanceSmartChain]
    private let keyCoinTypeId = "conversion-coin-type-id"

    private let marketKit: MarketKit.Kit
    private let localStorage: StorageKit.ILocalStorage

    let conversionPlatformCoins: [PlatformCoin]

    private let conversionCoinRelay = PublishRelay<PlatformCoin?>()
    private(set) var conversionCoin: PlatformCoin? {
        didSet {
            conversionCoinRelay.accept(conversionCoin)
            localStorage.set(value: conversionCoin?.coinType.id, for: keyCoinTypeId)
        }
    }

    init(marketKit: MarketKit.Kit, localStorage: StorageKit.ILocalStorage) {
        self.localStorage = localStorage
        self.marketKit = marketKit

        do {
            let platformCoins = try marketKit.platformCoins(coinTypes: coinTypes)
            conversionPlatformCoins = coinTypes.compactMap { coinType in
                platformCoins.first { $0.coinType == coinType }
            }
        } catch {
            conversionPlatformCoins = []
        }

        let coinTypeId: String? = localStorage.value(for: keyCoinTypeId)

        if let coinType = coinTypeId.map({ CoinType(id: $0) }), let platformCoin = conversionPlatformCoins.first(where: { $0.coinType == coinType }) {
            conversionCoin = platformCoin
        } else {
            conversionCoin = conversionPlatformCoins.first
        }
    }

}

extension BalanceConversionManager {

    var conversionCoinObservable: Observable<PlatformCoin?> {
        conversionCoinRelay.asObservable()
    }

    func toggleConversionCoin() {
        guard conversionPlatformCoins.count > 1, let conversionCoin = conversionCoin else {
            return
        }

        let currentIndex = conversionPlatformCoins.firstIndex(of: conversionCoin) ?? 0
        let newIndex = (currentIndex + 1) % conversionPlatformCoins.count
        self.conversionCoin = conversionPlatformCoins[newIndex]
    }

    func setConversionCoin(index: Int) {
        guard index < conversionPlatformCoins.count else {
            return
        }

        conversionCoin = conversionPlatformCoins[index]
    }

}
