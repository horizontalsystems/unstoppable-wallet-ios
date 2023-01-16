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

    var placeholder: String {
        "add_token.input_placeholder.contract_address".localized
    }

    func validate(reference: String) throws {
        do {
            _ = try EvmKit.Address(hex: reference)
        } catch {
            throw TokenError.invalidAddress
        }
    }

    func tokenQuery(reference: String) -> TokenQuery {
        TokenQuery(blockchainType: blockchain.type, tokenType: .eip20(address: reference.lowercased()))
    }

    func tokenSingle(reference: String) -> Single<Token> {
        guard let address = try? EvmKit.Address(hex: reference) else {
            return Single.error(TokenError.invalidAddress)
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
                .catchError { _ in
                    Single.error(TokenError.notFound(blockchainName: blockchain.name))
                }
    }

}

extension AddEvmTokenBlockchainService {

    enum TokenError: LocalizedError {
        case invalidAddress
        case notFound(blockchainName: String)

        var errorDescription: String? {
            switch self {
            case .invalidAddress: return "add_token.invalid_contract_address".localized
            case .notFound(let blockchainName): return "add_token.contract_address_not_found".localized(blockchainName)
            }
        }
    }

}
