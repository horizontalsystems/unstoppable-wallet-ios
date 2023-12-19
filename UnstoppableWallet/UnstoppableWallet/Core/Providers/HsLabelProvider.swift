import Alamofire
import Foundation
import HsToolKit
import ObjectMapper
import RxSwift

class HsLabelProvider {
    private let networkManager: NetworkManager
    private let apiUrl = AppConfig.marketApiUrl
    private let headers: HTTPHeaders?

    init(networkManager: NetworkManager) {
        self.networkManager = networkManager
        headers = AppConfig.hsProviderApiKey.flatMap { HTTPHeaders([HTTPHeader(name: "apikey", value: $0)]) }
    }
}

extension HsLabelProvider {
    func updateStatusSingle() -> Single<EvmUpdateStatus> {
        let request = networkManager.session.request("\(apiUrl)/v1/status/updates", headers: headers)
        return networkManager.single(request: request)
    }

    func evmMethodLabelsSingle() -> Single<[EvmMethodLabel]> {
        let request = networkManager.session.request("\(apiUrl)/v1/evm-method-labels", headers: headers)
        return networkManager.single(request: request)
    }

    func evmAddressLabelsSingle() -> Single<[EvmAddressLabel]> {
        let request = networkManager.session.request("\(apiUrl)/v1/addresses/labels", headers: headers)
        return networkManager.single(request: request)
    }
}
