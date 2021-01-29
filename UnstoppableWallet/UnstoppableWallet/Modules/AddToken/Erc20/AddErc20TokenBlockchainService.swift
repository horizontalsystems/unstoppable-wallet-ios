import Foundation
import RxSwift
import Alamofire
import HsToolKit
import EthereumKit

class AddErc20TokenBlockchainService {
    private let appConfigProvider: IAppConfigProvider
    private let networkManager: NetworkManager

    init(appConfigProvider: IAppConfigProvider, networkManager: NetworkManager) {
        self.appConfigProvider = appConfigProvider
        self.networkManager = networkManager
    }

}

extension AddErc20TokenBlockchainService: IAddTokenBlockchainService {

    func validate(reference: String) throws {
        _ = try EthereumKit.Address(hex: reference)
    }

    func existingCoin(reference: String, coins: [Coin]) -> Coin? {
        coins.first { coin in
            if case .erc20(let address) = coin.type, address.lowercased() == reference.lowercased() {
                return true
            }

            return false
        }
    }

    func coinSingle(reference: String) -> Single<Coin> {
        let parameters: Parameters = [
            "module": "account",
            "action": "tokentx",
            "contractaddress": reference,
            "page": 1,
            "offset": 1,
            "apikey": appConfigProvider.etherscanKey
        ]

        let apiUrl = appConfigProvider.testMode ? "https://api-ropsten.etherscan.io/api" : "https://api.etherscan.io/api"
        let request = networkManager.session.request(apiUrl, parameters: parameters)

        return networkManager.single(request: request, mapper: ApiMapper(address: reference))
    }

}

extension AddErc20TokenBlockchainService {

    class ApiMapper: IApiMapper {
        private let address: String

        init(address: String) {
            self.address = address
        }

        public func map(statusCode: Int, data: Any?) throws -> Coin {
            guard let map = data as? [String: Any] else {
                throw NetworkManager.RequestError.invalidResponse(statusCode: statusCode, data: data)
            }

            guard let status = map["status"] as? String, status == "1" else {
                throw ApiError.contractDoesNotExist
            }

            guard let results = map["result"] as? [[String: Any]], let result = results.first else {
                throw ApiError.invalidResponse
            }

            guard let tokenName = result["tokenName"] as? String else {
                throw ApiError.invalidResponse
            }

            guard let tokenSymbol = result["tokenSymbol"] as? String else {
                throw ApiError.invalidResponse
            }

            guard let tokenDecimalString = result["tokenDecimal"] as? String, let tokenDecimal = Int(tokenDecimalString) else {
                throw ApiError.invalidResponse
            }

            return Coin(
                    id: tokenSymbol,
                    title: tokenName,
                    code: tokenSymbol,
                    decimal: tokenDecimal,
                    type: .erc20(address: address)
            )
        }

    }

}

extension AddErc20TokenBlockchainService {

    enum ApiError: LocalizedError {
        case contractDoesNotExist
        case invalidResponse

        var errorDescription: String? {
            switch self {
            case .contractDoesNotExist: return "add_erc20_token.contract_not_exist".localized
            default: return "\(self)"
            }
        }

    }

}
