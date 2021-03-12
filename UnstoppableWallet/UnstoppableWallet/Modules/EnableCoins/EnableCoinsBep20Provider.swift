import RxSwift
import ObjectMapper
import HsToolKit
import Alamofire

class EnableCoinsBep20Provider {
    private let appConfigProvider: IAppConfigProvider
    private let networkManager: NetworkManager

    init(appConfigProvider: IAppConfigProvider, networkManager: NetworkManager) {
        self.appConfigProvider = appConfigProvider
        self.networkManager = networkManager
    }

}

extension EnableCoinsBep20Provider {

    func contractAddressesSingle(address: String) -> Single<[String]> {
        let url = "https://api.bscscan.com/api"

        let parameters: Parameters = [
            "module": "account",
            "action": "tokentx",
            "address": address,
            "apikey": appConfigProvider.bscscanKey
        ]

        let request = networkManager.session.request(url, parameters: parameters)

        return networkManager.single(request: request, mapper: ApiMapper())
    }

}

extension EnableCoinsBep20Provider {

    class ApiMapper: IApiMapper {

        public func map(statusCode: Int, data: Any?) throws -> [String] {
            guard let map = data as? [String: Any] else {
                throw NetworkManager.RequestError.invalidResponse(statusCode: statusCode, data: data)
            }

            guard let status = map["status"] as? String, status == "1" else {
                throw ApiError.notFound
            }

            guard let results = map["result"] as? [[String: Any]] else {
                throw ApiError.invalidResponse
            }

            var contractAddresses = Set<String>()

            for result in results {
                guard let contractAddress = result["contractAddress"] as? String else {
                    throw ApiError.invalidResponse
                }

                contractAddresses.insert(contractAddress)
            }

            return Array(contractAddresses)
        }

    }

    enum ApiError: LocalizedError {
        case notFound
        case invalidResponse
    }

}
