import Foundation
import RxSwift
import EvmKit
import Eip20Kit
import HsToolKit
import MarketKit

class AddEvmTokenBlockchainService {
    private let blockchain: Blockchain
    private let networkManager: NetworkManager
    private let rpcSource: RpcSource

    init?(blockchain: Blockchain, networkManager: NetworkManager, evmSyncSourceManager: EvmSyncSourceManager) {
        self.blockchain = blockchain
        self.networkManager = networkManager

        guard let rpcSource = evmSyncSourceManager.httpSyncSource(blockchainType: blockchain.type)?.rpcSource else {
            return nil
        }

        self.rpcSource = rpcSource
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
        guard let address = try? EvmKit.Address(hex: reference) else {
            return Single.error(TokenError.invalidReference)
        }

        let tokenQuery = tokenQuery(reference: reference)
        let blockchain = blockchain

        return Eip20Kit.Kit.tokenInfoSingle(networkManager: networkManager, rpcSource: rpcSource, contractAddress: address)
                .map { tokenInfo in
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

    enum TokenError: Error {
        case invalidReference
    }

}
