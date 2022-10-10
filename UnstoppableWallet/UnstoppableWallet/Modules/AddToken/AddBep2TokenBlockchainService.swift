import Foundation
import RxSwift
import HsToolKit
import Alamofire
import ObjectMapper
import MarketKit

class AddBep2TokenBlockchainService {
    private let blockchain: Blockchain
    private let networkManager: NetworkManager
    private let apiUrl: String

    init?(marketKit: MarketKit.Kit, networkManager: NetworkManager, appConfigProvider: AppConfigProvider) {
        guard let blockchain = try? marketKit.blockchain(uid: BlockchainType.binanceChain.uid) else {
            return nil
        }

        self.blockchain = blockchain
        self.networkManager = networkManager
        apiUrl = appConfigProvider.marketApiUrl
    }

}

extension AddBep2TokenBlockchainService: IAddTokenBlockchainService {

    func isValid(reference: String) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: "\\w+-\\w+") else {
            return false
        }

        return regex.firstMatch(in: reference, range: NSRange(location: 0, length: reference.count)) != nil
    }

    func tokenQuery(reference: String) -> TokenQuery {
        TokenQuery(blockchainType: blockchain.type, tokenType: .bep2(symbol: reference.uppercased()))
    }

    func tokenSingle(reference: String) -> Single<Token> {
        let reference = reference.uppercased()

        let parameters: Parameters = [
            "blockchain": blockchain.uid,
            "symbol": reference
        ]

        let url = "\(apiUrl)/v1/token_info/bep2"
        let request = networkManager.session.request(url, parameters: parameters)
        let tokenQuery = tokenQuery(reference: reference)
        let blockchain = blockchain

        return networkManager.single(request: request).map { (tokenInfo: TokenInfo) in
            Token(
                    coin: Coin(uid: tokenQuery.customCoinUid, name: tokenInfo.name, code: tokenInfo.originalSymbol),
                    blockchain: blockchain,
                    type: tokenQuery.tokenType,
                    decimals: tokenInfo.decimals
            )
        }
    }

}

extension AddBep2TokenBlockchainService {

    struct TokenInfo: ImmutableMappable {
        let name: String
        let originalSymbol: String
        let decimals: Int

        init(map: Map) throws {
            name = try map.value("name")
            originalSymbol = try map.value("original_symbol")
            decimals = try map.value("contract_decimals")
        }
    }

}
