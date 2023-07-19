import Foundation
import RxSwift
import TronKit
import HsToolKit
import MarketKit

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

    func tokenSingle(reference: String) -> Single<Token> {
        guard let address = try? TronKit.Address(address: reference) else {
            return Single.error(TokenError.invalidAddress)
        }

        let tokenQuery = tokenQuery(reference: reference)
        let blockchain = blockchain
        let apiKey = AppConfig.tronGridApiKey

        return Single<Token>.create { observer in
            let task = Task { [weak self] in
                guard let strongSelf = self else {
                    observer(.error(TokenError.disposableError))
                    return
                }

                do {
                    async let name = try Trc20DataProvider.fetchName(networkManager: strongSelf.networkManager, network: strongSelf.network, apiKey: apiKey, contractAddress: address)
                    async let symbol = try Trc20DataProvider.fetchSymbol(networkManager: strongSelf.networkManager, network: strongSelf.network, apiKey: apiKey, contractAddress: address)
                    async let decimals = try Trc20DataProvider.fetchDecimals(networkManager: strongSelf.networkManager, network: strongSelf.network, apiKey: apiKey, contractAddress: address)

                    let token = try await Token(
                        coin: Coin(uid: tokenQuery.customCoinUid, name: name, code: symbol),
                        blockchain: blockchain,
                        type: tokenQuery.tokenType,
                        decimals: decimals
                    )

                    observer(.success(token))
                } catch {
                    print("ERROR: \(error)")
                    observer(.error(TokenError.notFound(blockchainName: blockchain.name)))
                }
            }

            return Disposables.create {
                task.cancel()
            }
        }
    }

}

extension AddTronTokenBlockchainService {

    enum TokenError: LocalizedError {
        case disposableError
        case invalidAddress
        case notFound(blockchainName: String)

        var errorDescription: String? {
            switch self {
                case .disposableError: return ""
                case .invalidAddress: return "add_token.invalid_contract_address".localized
                case .notFound(let blockchainName): return "add_token.contract_address_not_found".localized(blockchainName)
            }
        }
    }

}
