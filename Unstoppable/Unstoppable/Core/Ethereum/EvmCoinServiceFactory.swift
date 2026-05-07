import BigInt
import EvmKit
import MarketKit
import TronKit

class EvmCoinServiceFactory {
    private let blockchainType: BlockchainType
    private let marketKit: MarketKit.Kit
    private let currencyManager: CurrencyManager
    private let coinManager: CoinManager

    let baseCoinService: CoinService

    init?(blockchainType: BlockchainType, marketKit: MarketKit.Kit, currencyManager: CurrencyManager, coinManager: CoinManager) {
        self.blockchainType = blockchainType
        self.marketKit = marketKit
        self.currencyManager = currencyManager
        self.coinManager = coinManager

        let query = TokenQuery(blockchainType: blockchainType, tokenType: .native)

        guard let baseToken = try? marketKit.token(query: query) else {
            return nil
        }

        baseCoinService = CoinService(token: baseToken, currencyManager: currencyManager, marketKit: marketKit)
    }

    func coinService(contractAddress: EvmKit.Address) -> CoinService? {
        let query = TokenQuery(blockchainType: blockchainType, tokenType: .eip20(address: contractAddress.hex))

        guard let token = try? coinManager.token(query: query) else {
            return nil
        }

        return coinService(token: token)
    }

    func coinService(contractAddress: TronKit.Address) -> CoinService? {
        let query = TokenQuery(blockchainType: blockchainType, tokenType: .eip20(address: contractAddress.base58))

        guard let token = try? coinManager.token(query: query) else {
            return nil
        }

        return coinService(token: token)
    }

    func coinService(token: Token) -> CoinService {
        CoinService(token: token, currencyManager: currencyManager, marketKit: marketKit)
    }
}
