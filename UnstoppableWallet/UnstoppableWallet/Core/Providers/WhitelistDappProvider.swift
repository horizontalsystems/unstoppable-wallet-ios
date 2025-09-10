import Alamofire
import Foundation
import HsToolKit
import ObjectMapper
import RxSwift

class WhitelistDappProvider {
    private let networkManager: NetworkManager
    private let apiUrl = AppConfig.marketApiUrl
    private let headers: HTTPHeaders?

    init(networkManager: NetworkManager) {
        self.networkManager = networkManager
        headers = AppConfig.hsProviderApiKey.flatMap { HTTPHeaders([HTTPHeader(name: "apikey", value: $0)]) }
    }
}

extension WhitelistDappProvider {
    func whitelistDapps() -> Single<[WhitelistDapp]> {
        let request = networkManager.session.request("\(apiUrl)/v1/defi-protocols/dapps", headers: headers)
        return networkManager.single(request: request)
    }
}
