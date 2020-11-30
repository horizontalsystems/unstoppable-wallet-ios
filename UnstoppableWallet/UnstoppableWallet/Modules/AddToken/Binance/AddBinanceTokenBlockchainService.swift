import RxSwift
import HsToolKit
import Alamofire
import ObjectMapper

class AddBinanceTokenBlockchainService {
    private let appConfigProvider: IAppConfigProvider
    private let networkManager: NetworkManager

    init(appConfigProvider: IAppConfigProvider, networkManager: NetworkManager) {
        self.appConfigProvider = appConfigProvider
        self.networkManager = networkManager
    }

}

extension AddBinanceTokenBlockchainService: IAddTokenBlockchainService {

    func validate(reference: String) throws {
        // todo
    }

    func existingCoin(reference: String, coins: [Coin]) -> Coin? {
        coins.first { coin in
            if case .binance(let symbol) = coin.type, symbol.lowercased() == reference.lowercased() {
                return true
            }

            return false
        }
    }

    func coinSingle(reference: String) -> Single<Coin> {
        let parameters: Parameters = [
            "limit": 10000
        ]

        let apiUrl = appConfigProvider.testMode ? "https://testnet-dex-atlantic.binance.org/api/v1/tokens/" : "https://dex.binance.org/api/v1/tokens/"
        let request = networkManager.session.request(apiUrl, parameters: parameters)

        let tokensSingle: Single<[Token]> = networkManager.single(request: request)

        return tokensSingle.flatMap { tokens -> Single<Coin> in
            if let token = tokens.first(where: { $0.symbol.lowercased() == reference.lowercased() }) {
                let coin = Coin(
                        id: token.symbol,
                        title: token.name,
                        code: token.originalSymbol,
                        decimal: 8,
                        type: .binance(symbol: token.symbol)
                )
                return Single.just(coin)
            } else {
                return Single.error(ApiError.tokenDoesNotExist)
            }
        }
    }

}

extension AddBinanceTokenBlockchainService {

    struct Token: ImmutableMappable {
        let name: String
        let originalSymbol: String
        let symbol: String

        init(map: Map) throws {
            name = try map.value("name")
            originalSymbol = try map.value("original_symbol")
            symbol = try map.value("symbol")
        }
    }

    enum ApiError: LocalizedError {
        case tokenDoesNotExist

        var errorDescription: String? {
            switch self {
            case .tokenDoesNotExist: return "add_bep2_token.token_not_exist".localized
            }
        }

    }

}
