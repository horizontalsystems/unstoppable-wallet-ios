import Foundation
import HsToolKit
import RxSwift
import Alamofire

class ProFeaturesAuthorizationAdapter {
    private let baseUrl: String
    private let networkManager: NetworkManager
    private let headers: HTTPHeaders?

    init(baseUrl: String, networkManager: NetworkManager, apiKey: String?) {
        self.baseUrl = baseUrl
        self.networkManager = networkManager

        headers = apiKey.flatMap { HTTPHeaders([HTTPHeader(name: "apikey", value: $0)]) }
    }

}

extension ProFeaturesAuthorizationAdapter {

    // Get AuthKey

    func message(address: String) -> Single<String> {
        let parameters: Parameters = [
            "address": address
        ]
        networkManager.single(url: "\(baseUrl)/v1/auth/get-key", method: .get, parameters: parameters, headers: headers)
    }

    // Authenticate

    func authenticate(address: String, signature: String) -> Single<String> {
        let parameters: Parameters = [
            "address": address,
            "signature": signature
        ]

        return networkManager.single(url: "\(baseUrl)/v1/auth/authenticate", method: .post, parameters: parameters, headers: headers)
    }

}
