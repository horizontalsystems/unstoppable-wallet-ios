import CurrencyKit
import BigInt
import MarketKit
import EthereumKit

class EvmCoinServiceFactory {
    private let evmBlockchain: EvmBlockchain
    private let marketKit: MarketKit.Kit
    private let currencyKit: CurrencyKit.Kit

    let baseCoinService: CoinService

    init?(evmBlockchain: EvmBlockchain, marketKit: MarketKit.Kit, currencyKit: CurrencyKit.Kit) {
        self.evmBlockchain = evmBlockchain
        self.marketKit = marketKit
        self.currencyKit = currencyKit

        guard let basePlatformCoin = try? marketKit.platformCoin(coinType: evmBlockchain.baseCoinType) else {
            return nil
        }

        baseCoinService = CoinService(platformCoin: basePlatformCoin, currencyKit: currencyKit, marketKit: marketKit)
    }

    func coinService(contractAddress: EthereumKit.Address) -> CoinService? {
        guard let platformCoin = try? marketKit.platformCoin(coinType: evmBlockchain.evm20CoinType(address: contractAddress.hex)) else {
            return nil
        }

        return CoinService(platformCoin: platformCoin, currencyKit: currencyKit, marketKit: marketKit)
    }

}
