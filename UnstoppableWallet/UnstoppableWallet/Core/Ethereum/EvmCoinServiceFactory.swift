import CurrencyKit
import BigInt
import MarketKit
import EthereumKit

class EvmCoinServiceFactory {
    private let basePlatformCoin: PlatformCoin
    private let marketKit: MarketKit.Kit
    private let currencyKit: CurrencyKit.Kit

    let baseCoinService: CoinService

    init(basePlatformCoin: PlatformCoin, marketKit: MarketKit.Kit, currencyKit: CurrencyKit.Kit) {
        self.basePlatformCoin = basePlatformCoin
        self.marketKit = marketKit
        self.currencyKit = currencyKit

        baseCoinService = CoinService(platformCoin: basePlatformCoin, currencyKit: currencyKit, marketKit: marketKit)
    }

    func coinService(contractAddress: EthereumKit.Address) -> CoinService? {
        guard let platformCoin = platformCoin(contractAddress: contractAddress) else {
            return nil
        }

        return CoinService(platformCoin: platformCoin, currencyKit: currencyKit, marketKit: marketKit)
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
