import Foundation
import RxSwift
import Alamofire
import HsToolKit
import EthereumKit
import MarketKit

class AddEvmTokenBlockchainService {
    private let networkType: NetworkType
    private let appConfigProvider: IAppConfigProvider
    private let networkManager: NetworkManager

    init(networkType: NetworkType, appConfigProvider: IAppConfigProvider, networkManager: NetworkManager) {
        self.networkType = networkType
        self.appConfigProvider = appConfigProvider
        self.networkManager = networkManager
    }

    private var apiUrl: String {
        switch networkType {
        case .ethMainNet: return "https://api.etherscan.io"
        case .bscMainNet: return "https://api.bscscan.com"
        case .ropsten: return "https://api-ropsten.etherscan.io"
        case .rinkeby: return "https://api-rinkeby.etherscan.io"
        case .kovan: return "https://api-kovan.etherscan.io"
        case .goerli: return "https://api-goerli.etherscan.io"
        }
    }

    var explorerKey: String {
        switch networkType {
        case .ethMainNet, .ropsten, .rinkeby, .kovan, .goerli: return appConfigProvider.etherscanKey
        case .bscMainNet: return appConfigProvider.bscscanKey
        }
    }

    func coinType(address: String) -> CoinType {
        switch networkType {
        case .ethMainNet, .ropsten, .rinkeby, .kovan, .goerli: return .erc20(address: address)
        case .bscMainNet: return .bep20(address: address)
        }
    }

}

extension AddEvmTokenBlockchainService: IAddTokenBlockchainService {

    func isValid(reference: String) -> Bool {
        do {
            _ = try EthereumKit.Address(hex: reference)
            return true
        } catch {
            return false
        }
    }

    func coinType(reference: String) -> CoinType {
        coinType(address: reference.lowercased())
    }

    func customTokenSingle(reference: String) -> Single<CustomToken> {
        let reference = reference.lowercased()

        let parameters: Parameters = [
            "module": "account",
            "action": "tokentx",
            "contractaddress": reference,
            "page": 1,
            "offset": 1,
            "apikey": explorerKey
        ]

        let url = "\(apiUrl)/api"
        let request = networkManager.session.request(url, parameters: parameters)

        return networkManager.single(request: request, mapper: ApiMapper(coinType: coinType(address: reference)) )
    }

}

extension AddEvmTokenBlockchainService {

    class ApiMapper: IApiMapper {
        private let coinType: CoinType

        init(coinType: CoinType) {
            self.coinType = coinType
        }

        public func map(statusCode: Int, data: Any?) throws -> CustomToken {
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

            return CustomToken(
                    coinName: tokenName,
                    coinCode: tokenSymbol,
                    coinType: coinType,
                    decimal: tokenDecimal
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
            case .contractDoesNotExist: return "add_token.contract_not_found".localized
            default: return "\(self)"
            }
        }

    }

}
