import Alamofire
import Foundation
import HsToolKit
import ObjectMapper
import RxSwift

class ProFeaturesAuthorizationAdapter {
    private let apiUrl = AppConfig.marketApiUrl
    private let networkManager: NetworkManager
    private let headers: HTTPHeaders?

    init(networkManager: NetworkManager) {
        self.networkManager = networkManager
        headers = AppConfig.hsProviderApiKey.flatMap { HTTPHeaders([HTTPHeader(name: "apikey", value: $0)]) }
    }
}

extension ProFeaturesAuthorizationAdapter {
    // Get AuthKey

    func message(address: String) -> Single<String> {
        let parameters: Parameters = [
            "address": address,
        ]
        return networkManager.single(url: "\(apiUrl)/v1/auth/get-key", method: .get, parameters: parameters, headers: headers).map { (response: AuthorizeResponse) in
            response.key
        }
    }

    // Authenticate

    func authenticate(address: String, signature: String) -> Single<String> {
        let parameters: Parameters = [
            "address": address,
            "signature": signature,
        ]

        return networkManager.single(url: "\(apiUrl)/v1/auth/authenticate", method: .post, parameters: parameters, headers: headers).map { (response: AuthenticateResponse) in
            response.key
        }
    }
}

extension ProFeaturesAuthorizationAdapter {
    private class AuthorizeResponse: ImmutableMappable {
        public let key: String

        public required init(map: Map) throws {
            key = try map.value("key")
        }
    }

    private class AuthenticateResponse: ImmutableMappable {
        public let key: String

        public required init(map: Map) throws {
            key = try map.value("token")
        }
    }
}
