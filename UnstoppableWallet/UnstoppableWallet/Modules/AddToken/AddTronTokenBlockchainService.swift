import Foundation
import HsToolKit
import MarketKit
import TronKit

class AddTronTokenBlockchainService {
    private let blockchain: Blockchain
    private let networkManager: NetworkManager
    private let network: Network

    init(blockchain: Blockchain, networkManager: NetworkManager, network: Network) {
        self.blockchain = blockchain
        self.networkManager = networkManager
        self.network = network
    }
}

extension AddTronTokenBlockchainService: IAddTokenBlockchainService {
    var placeholder: String {
        "add_token.input_placeholder.contract_address".localized
    }

    func validate(reference: String) throws {
        do {
            _ = try TronKit.Address(address: reference)
        } catch {
            throw TokenError.invalidAddress
        }
    }

    func tokenQuery(reference: String) -> TokenQuery {
        TokenQuery(blockchainType: blockchain.type, tokenType: .eip20(address: reference))
    }

    func token(reference: String) async throws -> Token {
        guard let address = try? TronKit.Address(address: reference) else {
            throw TokenError.invalidAddress
        }

        let tokenQuery = tokenQuery(reference: reference)
        let apiKeys = AppConfig.tronGridApiKeys

        do {
            async let name = Trc20DataProvider.fetchName(networkManager: networkManager, network: network, apiKeys: apiKeys, contractAddress: address)
            async let symbol = Trc20DataProvider.fetchSymbol(networkManager: networkManager, network: network, apiKeys: apiKeys, contractAddress: address)
            async let decimals = Trc20DataProvider.fetchDecimals(networkManager: networkManager, network: network, apiKeys: apiKeys, contractAddress: address)

            return try await Token(
                coin: Coin(uid: tokenQuery.customCoinUid, name: name, code: symbol),
                blockchain: blockchain,
                type: tokenQuery.tokenType,
                decimals: decimals
            )
        } catch {
            throw TokenError.notFound(blockchainName: blockchain.name)
        }
    }
}

extension AddTronTokenBlockchainService {
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
