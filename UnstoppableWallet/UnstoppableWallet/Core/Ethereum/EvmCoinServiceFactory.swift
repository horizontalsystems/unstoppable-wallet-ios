import CurrencyKit
import BigInt
import CoinKit
import EthereumKit

class EvmCoinServiceFactory {
    private let baseCoin: Coin
    private let coinKit: CoinKit.Kit
    private let currencyKit: CurrencyKit.Kit
    private let rateManager: IRateManager

    let baseCoinService: CoinService

    init(baseCoin: Coin, coinKit: CoinKit.Kit, currencyKit: CurrencyKit.Kit, rateManager: IRateManager) {
        self.baseCoin = baseCoin
        self.coinKit = coinKit
        self.currencyKit = currencyKit
        self.rateManager = rateManager

        baseCoinService = CoinService(coin: baseCoin, currencyKit: currencyKit, rateManager: rateManager)
    }

    func coinService(contractAddress: EthereumKit.Address) -> CoinService? {
        guard let coin = coin(contractAddress: contractAddress) else {
            return nil
        }

        return CoinService(coin: coin, currencyKit: currencyKit, rateManager: rateManager)
    }

    private func coin(contractAddress: EthereumKit.Address) -> Coin? {
        switch baseCoin.type {
        case .ethereum:
            return coinKit.coin(type: .erc20(address: contractAddress.hex))
        case .binanceSmartChain:
            return coinKit.coin(type: .bep20(address: contractAddress.hex))
        default:
            return nil
        }
    }

}
