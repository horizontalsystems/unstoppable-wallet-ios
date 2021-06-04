import Foundation
import RxSwift
import Alamofire
import HsToolKit
import EthereumKit
import CoinKit

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

    func validate(reference: String) throws {
        _ = try EthereumKit.Address(hex: reference)
    }

    func coinType(reference: String) -> CoinType {
        coinType(address: reference.lowercased())
    }

    func coinSingle(reference: String) -> Single<Coin> {
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
