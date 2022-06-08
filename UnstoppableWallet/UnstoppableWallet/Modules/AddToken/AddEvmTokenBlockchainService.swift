import Foundation
import RxSwift
import Alamofire
import EthereumKit
import ObjectMapper
import HsToolKit
import MarketKit

class AddEvmTokenBlockchainService {
    private let apiUrl = "https://markets-dev.horizontalsystems.xyz"

    private let blockchainType: BlockchainType
    private let networkManager: NetworkManager

    init(blockchainType: BlockchainType, networkManager: NetworkManager) {
        self.blockchainType = blockchainType
        self.networkManager = networkManager
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

    func tokenQuery(reference: String) -> TokenQuery {
        TokenQuery(blockchainType: blockchainType, tokenType: .eip20(address: reference.lowercased()))
    }

    func customCoinSingle(reference: String) -> Single<AddTokenModule.CustomCoin> {
        let reference = reference.lowercased()

        let parameters: Parameters = [
            "address": reference
        ]

        let url = "\(apiUrl)/v1/token_info/\(blockchainType.apiPath)"
        let request = networkManager.session.request(url, parameters: parameters)
        let tokenQuery = tokenQuery(reference: reference)

        return networkManager.single(request: request).map { (tokenInfo: TokenInfo) in
            AddTokenModule.CustomCoin(
                    tokenQuery: tokenQuery,
                    name: tokenInfo.name,
                    code: tokenInfo.symbol,
                    decimals: tokenInfo.decimals
            )
        }
    }

}

extension AddEvmTokenBlockchainService {

    struct TokenInfo: ImmutableMappable {
        let name: String
        let symbol: String
        let decimals: Int

        init(map: Map) throws {
            name = try map.value("name")
            symbol = try map.value("symbol")
            decimals = try map.value("decimals")
        }
    }

}

extension BlockchainType {

    var apiPath: String {
        switch self {
        case .ethereum: return "erc20"
        case .binanceSmartChain: return "bep20"
        case .polygon: return "mrc20"
        case .optimism: return "optimism"
        case .arbitrumOne: return "arbitrum-one"
        default: fatalError("Unsupported blockchain type")
        }
    }

}
