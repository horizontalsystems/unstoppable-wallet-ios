import Eip20Kit
import EvmKit
import Foundation
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
        // the native coin's ERC-20 interface is the native coin itself (Android AddTokenService)
        if let contract = blockchain.type.nativeTokenContract, reference.caseInsensitiveCompare(contract.address) == .orderedSame {
            return TokenQuery(blockchainType: blockchain.type, tokenType: .native)
        }

        return TokenQuery(blockchainType: blockchain.type, tokenType: .eip20(address: reference.lowercased()))
    }

    func token(reference: String) async throws -> Token {
        guard let address = try? EvmKit.Address(hex: reference) else {
            throw TokenError.invalidAddress
        }

        // Arc's transfer-log address is not a contract at all. The native coin's ERC-20 interface
        // does not get here, `tokenQuery` resolves it to the native coin; the guard stays as a backstop.
        guard !blockchain.type.isBlockedEip20(address: reference) else {
            throw TokenError.invalidAddress
        }

        let tokenQuery = tokenQuery(reference: reference)

        do {
            let tokenInfo = try await Eip20Kit.Kit.tokenInfo(networkManager: networkManager, rpcSource: rpcSource, contractAddress: address)
            return Token(
                coin: Coin(uid: tokenQuery.customCoinUid, name: tokenInfo.name, code: tokenInfo.symbol),
                blockchain: blockchain,
                type: tokenQuery.tokenType,
                decimals: tokenInfo.decimals
            )
        } catch {
            throw TokenError.notFound(blockchainName: blockchain.name)
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
            case let .notFound(blockchainName): return "add_token.contract_address_not_found".localized(blockchainName)
            }
        }
    }
}
