import CurrencyKit
import BigInt
import MarketKit
import EvmKit

class EvmCoinServiceFactory {
    private let blockchainType: BlockchainType
    private let marketKit: MarketKit.Kit
    private let currencyKit: CurrencyKit.Kit
    private let evmBlockchainManager: EvmBlockchainManager
    private let coinManager: CoinManager

    let baseCoinService: CoinService

    init?(blockchainType: BlockchainType, marketKit: MarketKit.Kit, currencyKit: CurrencyKit.Kit, evmBlockchainManager: EvmBlockchainManager, coinManager: CoinManager) {
        self.blockchainType = blockchainType
        self.marketKit = marketKit
        self.currencyKit = currencyKit
        self.evmBlockchainManager = evmBlockchainManager
        self.coinManager = coinManager

        guard let baseToken = evmBlockchainManager.baseToken(blockchainType: blockchainType) else {
            return nil
        }

        baseCoinService = CoinService(token: baseToken, currencyKit: currencyKit, marketKit: marketKit)
    }

    func coinService(contractAddress: EvmKit.Address) -> CoinService? {
        let query = TokenQuery(blockchainType: blockchainType, tokenType: .eip20(address: contractAddress.hex))

        guard let token = try? coinManager.token(query: query) else {
            return nil
        }

        return coinService(token: token)
    }

    func coinService(token: Token) -> CoinService {
        CoinService(token: token, currencyKit: currencyKit, marketKit: marketKit)
    }

}
