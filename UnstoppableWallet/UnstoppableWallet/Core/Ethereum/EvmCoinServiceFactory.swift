import CurrencyKit
import BigInt
import MarketKit
import EvmKit
import TronKit

class EvmCoinServiceFactory {
    private let blockchainType: BlockchainType
    private let marketKit: MarketKit.Kit
    private let currencyKit: CurrencyKit.Kit
    private let coinManager: CoinManager

    let baseCoinService: CoinService

    init?(blockchainType: BlockchainType, marketKit: MarketKit.Kit, currencyKit: CurrencyKit.Kit, coinManager: CoinManager) {
        self.blockchainType = blockchainType
        self.marketKit = marketKit
        self.currencyKit = currencyKit
        self.coinManager = coinManager

        let query = TokenQuery(blockchainType: blockchainType, tokenType: .native)

        guard let baseToken = try? marketKit.token(query: query) else {
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

    func coinService(contractAddress: TronKit.Address) -> CoinService? {
        let query = TokenQuery(blockchainType: blockchainType, tokenType: .eip20(address: contractAddress.base58))

        guard let token = try? coinManager.token(query: query) else {
            return nil
        }

        return coinService(token: token)
    }

    func coinService(token: Token) -> CoinService {
        CoinService(token: token, currencyKit: currencyKit, marketKit: marketKit)
    }

}
