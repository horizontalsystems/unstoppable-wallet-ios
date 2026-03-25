import Foundation
import HsToolKit
import MarketKit
import RxSwift
import SolanaKit

class AddSplTokenBlockchainService {
    private let blockchain: Blockchain
    private let networkManager: NetworkManager

    init(blockchain: Blockchain, networkManager: NetworkManager) {
        self.blockchain = blockchain
        self.networkManager = networkManager
    }
}

extension AddSplTokenBlockchainService: IAddTokenBlockchainService {
    var placeholder: String {
        "add_token.input_placeholder.mint_address".localized
    }

    func validate(reference: String) throws {
        do {
            _ = try SolanaKit.Address(reference)
        } catch {
            throw TokenError.invalidAddress
        }
    }

    func tokenQuery(reference: String) -> TokenQuery {
        TokenQuery(blockchainType: .solana, tokenType: .spl(address: reference))
    }

    func tokenSingle(reference: String) -> Single<Token> {
        let tokenQuery = tokenQuery(reference: reference)

        return Single.create { [blockchain, networkManager] observer in
            Task { [blockchain, networkManager] in
                do {
                    let info = try await SolanaKit.Kit.tokenInfo(
                        networkManager: networkManager,
                        apiKey: AppConfig.jupiterApiKey,
                        mintAddress: reference
                    )

                    let token = Token(
                        coin: Coin(uid: tokenQuery.customCoinUid, name: info.name, code: info.symbol),
                        blockchain: blockchain,
                        type: tokenQuery.tokenType,
                        decimals: info.decimals
                    )

                    observer(.success(token))
                } catch {
                    observer(.error(TokenError.notFound(blockchainName: blockchain.name)))
                }
            }

            return Disposables.create()
        }
    }

    func token(reference: String) async throws -> MarketKit.Token {
        guard (try? SolanaKit.Address(reference)) != nil else {
            throw TokenError.invalidAddress
        }

        let tokenQuery = tokenQuery(reference: reference)

        do {
            let info = try await SolanaKit.Kit.tokenInfo(
                networkManager: networkManager,
                apiKey: AppConfig.jupiterApiKey,
                mintAddress: reference
            )

            return Token(
                coin: Coin(uid: tokenQuery.customCoinUid, name: info.name, code: info.symbol),
                blockchain: blockchain,
                type: tokenQuery.tokenType,
                decimals: info.decimals
            )
        } catch {
            throw TokenError.notFound(blockchainName: blockchain.name)
        }
    }
}

extension AddSplTokenBlockchainService {
    enum TokenError: LocalizedError {
        case invalidAddress
        case notFound(blockchainName: String)

        var errorDescription: String? {
            switch self {
            case .invalidAddress: return "add_token.invalid_mint_address".localized
            case let .notFound(blockchainName): return "add_token.mint_address_not_found".localized(blockchainName)
            }
        }
    }
}
