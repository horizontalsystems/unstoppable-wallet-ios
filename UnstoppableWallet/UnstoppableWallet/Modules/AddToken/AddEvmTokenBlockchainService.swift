import Foundation
import RxSwift
import Alamofire
import HsToolKit
import EthereumKit
import CoinKit

protocol IAddEvmTokenResolver {
    var apiUrl: String { get }
    var explorerKey: String { get }
    func coinType(address: String) -> CoinType
}

class AddEvmTokenBlockchainService {
    private let resolver: IAddEvmTokenResolver
    private let networkManager: NetworkManager

    init(resolver: IAddEvmTokenResolver, networkManager: NetworkManager) {
        self.resolver = resolver
        self.networkManager = networkManager
    }

}

extension AddEvmTokenBlockchainService: IAddTokenBlockchainService {

    func validate(reference: String) throws {
        _ = try EthereumKit.Address(hex: reference)
    }

    func coinType(reference: String) -> CoinType {
        resolver.coinType(address: reference.lowercased())
    }

    func coinSingle(reference: String) -> Single<Coin> {
        let reference = reference.lowercased()

        let parameters: Parameters = [
            "module": "account",
            "action": "tokentx",
            "contractaddress": reference,
            "page": 1,
            "offset": 1,
            "apikey": resolver.explorerKey
        ]

        let request = networkManager.session.request(resolver.apiUrl, parameters: parameters)

        return networkManager.single(request: request, mapper: ApiMapper(coinType: resolver.coinType(address: reference)) )
    }

}

extension AddEvmTokenBlockchainService {

    class ApiMapper: IApiMapper {
        private let coinType: CoinType

        init(coinType: CoinType) {
            self.coinType = coinType
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
                    title: tokenName,
                    code: tokenSymbol,
                    decimal: tokenDecimal,
                    type: coinType
            )
        }

    }

}

extension AddEvmTokenBlockchainService {

    enum ApiError: LocalizedError {
        case contractDoesNotExist
        case invalidResponse

        var errorDescription: String? {
            switch self {
            case .contractDoesNotExist: return "add_evm_token.contract_not_exist".localized
            default: return "\(self)"
            }
        }

    }

}
