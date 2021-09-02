import CurrencyKit
import BigInt
import MarketKit
import EthereumKit

class EvmCoinServiceFactory {
    private let basePlatformCoin: PlatformCoin
    private let marketKit: MarketKit.Kit
    private let currencyKit: CurrencyKit.Kit
    private let rateManager: RateManagerNew

    let baseCoinService: CoinService

    init(basePlatformCoin: PlatformCoin, marketKit: MarketKit.Kit, currencyKit: CurrencyKit.Kit, rateManager: RateManagerNew) {
        self.basePlatformCoin = basePlatformCoin
        self.marketKit = marketKit
        self.currencyKit = currencyKit
        self.rateManager = rateManager

        baseCoinService = CoinService(platformCoin: basePlatformCoin, currencyKit: currencyKit, rateManager: rateManager)
    }

    func coinService(contractAddress: EthereumKit.Address) -> CoinService? {
        guard let platformCoin = platformCoin(contractAddress: contractAddress) else {
            return nil
        }

        return CoinService(platformCoin: platformCoin, currencyKit: currencyKit, rateManager: rateManager)
    }

    private func platformCoin(contractAddress: EthereumKit.Address) -> PlatformCoin? {
        switch basePlatformCoin.coinType {
        case .ethereum:
            return try? marketKit.platformCoin(coinType: .erc20(address: contractAddress.hex))
        case .binanceSmartChain:
            return try? marketKit.platformCoin(coinType: .bep20(address: contractAddress.hex))
        default:
            return nil
        }
    }

}
