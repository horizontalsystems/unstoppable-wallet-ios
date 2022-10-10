import Foundation
import RxSwift
import Alamofire
import EvmKit
import ObjectMapper
import HsToolKit
import MarketKit

class AddEvmTokenBlockchainService {
    private let blockchain: Blockchain
    private let networkManager: NetworkManager
    private let apiUrl: String

    init(blockchain: Blockchain, networkManager: NetworkManager, appConfigProvider: AppConfigProvider) {
        self.blockchain = blockchain
        self.networkManager = networkManager
        apiUrl = appConfigProvider.marketApiUrl
    }

}

extension AddEvmTokenBlockchainService: IAddTokenBlockchainService {

    func isValid(reference: String) -> Bool {
        do {
            _ = try EvmKit.Address(hex: reference)
            return true
        } catch {
            return false
        }
    }

    func tokenQuery(reference: String) -> TokenQuery {
        TokenQuery(blockchainType: blockchain.type, tokenType: .eip20(address: reference.lowercased()))
    }

    func tokenSingle(reference: String) -> Single<Token> {
        let reference = reference.lowercased()

        let parameters: Parameters = [
            "blockchain": blockchain.uid,
            "address": reference,
        ]

        let url = "\(apiUrl)/v1/token_info/eip20"
        let request = networkManager.session.request(url, parameters: parameters)
        let tokenQuery = tokenQuery(reference: reference)
        let blockchain = blockchain

        return networkManager.single(request: request).map { (tokenInfo: TokenInfo) in
            Token(
                    coin: Coin(uid: tokenQuery.customCoinUid, name: tokenInfo.name, code: tokenInfo.symbol),
                    blockchain: blockchain,
                    type: tokenQuery.tokenType,
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
