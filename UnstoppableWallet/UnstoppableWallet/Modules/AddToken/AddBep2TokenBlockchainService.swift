import Foundation
import RxSwift
import HsToolKit
import Alamofire
import ObjectMapper
import MarketKit

class AddBep2TokenBlockchainService {
    private let blockchain: Blockchain
    private let networkManager: NetworkManager

    init?(marketKit: MarketKit.Kit, networkManager: NetworkManager) {
        guard let blockchain = try? marketKit.blockchain(uid: BlockchainType.binanceChain.uid) else {
            return nil
        }

        self.blockchain = blockchain
        self.networkManager = networkManager
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
            "limit": 1000
        ]

        let url = "https://dex.binance.org/api/v1/tokens"
        let request = networkManager.session.request(url, parameters: parameters)
        let tokenQuery = tokenQuery(reference: reference)
        let blockchain = blockchain

        return networkManager.single(request: request)
                .flatMap { (bep2Tokens: [Bep2Token]) -> Single<Token> in
                    guard let bep2Token = bep2Tokens.first(where: { $0.symbol == reference }) else {
                        return Single.error(TokenError.notFound)
                    }

                    let token = Token(
                            coin: Coin(uid: tokenQuery.customCoinUid, name: bep2Token.name, code: bep2Token.originalSymbol),
                            blockchain: blockchain,
                            type: tokenQuery.tokenType,
                            decimals: 0
                    )

                    return Single.just(token)
                }
    }

}

extension AddBep2TokenBlockchainService {

    struct Bep2Token: ImmutableMappable {
        let name: String
        let originalSymbol: String
        let symbol: String

        init(map: Map) throws {
            name = try map.value("name")
            originalSymbol = try map.value("original_symbol")
            symbol = try map.value("symbol")
        }
    }

    enum TokenError: Error {
        case notFound
    }

}
