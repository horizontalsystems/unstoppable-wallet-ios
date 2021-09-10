import RxSwift
import HsToolKit
import Alamofire
import ObjectMapper
import MarketKit

class AddBep2TokenBlockchainService {
    private let appConfigProvider: IAppConfigProvider
    private let networkManager: NetworkManager

    init(appConfigProvider: IAppConfigProvider, networkManager: NetworkManager) {
        self.appConfigProvider = appConfigProvider
        self.networkManager = networkManager
    }

}

extension AddBep2TokenBlockchainService: IAddTokenBlockchainService {

    func isValid(reference: String) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: "\\w+-\\w+") else {
            return false
        }

        return regex.firstMatch(in: reference, range: NSRange(location: 0, length: reference.count)) != nil
    }

    func coinType(reference: String) -> CoinType {
        .bep2(symbol: reference.uppercased())
    }

    func customTokenSingle(reference: String) -> Single<CustomToken> {
        let parameters: Parameters = [
            "limit": 10000
        ]

        let apiUrl = appConfigProvider.testMode ? "https://testnet-dex-atlantic.binance.org/api/v1/tokens/" : "https://dex.binance.org/api/v1/tokens/"
        let request = networkManager.session.request(apiUrl, parameters: parameters)

        let tokensSingle: Single<[Token]> = networkManager.single(request: request)

        return tokensSingle.flatMap { tokens -> Single<CustomToken> in
            if let token = tokens.first(where: { $0.symbol.lowercased() == reference.lowercased() }) {
                let customCoin = CustomToken(
                        coinName: token.name,
                        coinCode: token.originalSymbol,
                        coinType: .bep2(symbol: token.symbol),
                        decimal: 8
                )

                return Single.just(customCoin)
            } else {
                return Single.error(ApiError.tokenDoesNotExist)
            }
        }
    }

}

extension AddBep2TokenBlockchainService {

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
            case .tokenDoesNotExist: return "add_token.symbol_not_found".localized
            }
        }

    }

}
