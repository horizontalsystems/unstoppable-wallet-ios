import RxSwift
import ObjectMapper
import HsToolKit
import Alamofire

class EnableCoinsErc20Provider {
    private let networkManager: NetworkManager

    init(networkManager: NetworkManager) {
        self.networkManager = networkManager
    }

}

extension EnableCoinsErc20Provider {

    func contractAddressesSingle(address: String) -> Single<[String]> {
        let url = "https://api.ethplorer.io/getAddressInfo/" + address
        let parameters = ["apiKey": "freekey"]

        let request = networkManager.session.request(url, parameters: parameters)
        return networkManager.single(request: request).map { (response: Response) -> [String] in
            response.tokens.map { $0.tokenInfo.address }
        }
    }

}

extension EnableCoinsErc20Provider {

    struct Response: ImmutableMappable {
        let tokens: [Token]

        init(map: Map) throws {
            tokens = (try? map.value("tokens")) ?? []
        }
    }

    struct Token: ImmutableMappable {
        let tokenInfo: TokenInfo

        init(map: Map) throws {
            tokenInfo = try map.value("tokenInfo")
        }
    }

    struct TokenInfo: ImmutableMappable {
        let address: String

        init(map: Map) throws {
            address = try map.value("address")
        }
    }

}
