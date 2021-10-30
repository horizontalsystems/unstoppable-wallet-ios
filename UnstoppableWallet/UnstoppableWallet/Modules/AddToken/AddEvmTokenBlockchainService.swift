import Foundation
import RxSwift
import Alamofire
import EthereumKit
import ObjectMapper
import HsToolKit
import MarketKit

class AddEvmTokenBlockchainService {
    private let apiUrl = "https://markets-dev.horizontalsystems.xyz"

    private let blockchain: Blockchain
    private let networkManager: NetworkManager

    init(blockchain: Blockchain, networkManager: NetworkManager) {
        self.blockchain = blockchain
        self.networkManager = networkManager
    }

    func coinType(address: String) -> CoinType {
        switch blockchain {
        case .ethereum: return .erc20(address: address)
        case .binanceSmartChain: return .bep20(address: address)
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
            "address": reference
        ]

        let url = "\(apiUrl)/v1/token_info/\(blockchain.apiPath)"
        let request = networkManager.session.request(url, parameters: parameters)
        let coinType = self.coinType(address: reference)

        return networkManager.single(request: request).map { (tokenInfo: TokenInfo) in
            CustomToken(
                    coinName: tokenInfo.name,
                    coinCode: tokenInfo.symbol,
                    coinType: coinType,
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

    enum Blockchain {
        case ethereum
        case binanceSmartChain

        var apiPath: String {
            switch self {
            case .ethereum: return "erc20"
            case .binanceSmartChain: return "bep20"
            }
        }
    }

}
