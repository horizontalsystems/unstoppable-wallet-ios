import RxSwift
import HsToolKit
import Alamofire
import ObjectMapper
import MarketKit

class AddBep2TokenBlockchainService {
    private let apiUrl = "https://markets-dev.horizontalsystems.xyz"

    private let networkManager: NetworkManager

    init(networkManager: NetworkManager) {
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
        let reference = reference.uppercased()

        let parameters: Parameters = [
            "symbol": reference
        ]

        let url = "\(apiUrl)/v1/token_info/bep2"
        let request = networkManager.session.request(url, parameters: parameters)

        return networkManager.single(request: request).map { (tokenInfo: TokenInfo) in
            CustomToken(
                    coinName: tokenInfo.name,
                    coinCode: tokenInfo.originalSymbol,
                    coinType: .bep2(symbol: reference),
                    decimals: tokenInfo.decimals
            )
        }
    }

}

extension AddBep2TokenBlockchainService {

    struct TokenInfo: ImmutableMappable {
        let name: String
        let originalSymbol: String
        let decimals: Int

        init(map: Map) throws {
            name = try map.value("name")
            originalSymbol = try map.value("original_symbol")
            decimals = try map.value("contract_decimals")
        }
    }

}
