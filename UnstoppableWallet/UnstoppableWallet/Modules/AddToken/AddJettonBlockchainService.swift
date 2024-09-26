import Foundation
import HsToolKit
import MarketKit
import RxSwift
import TonKit
import TonSwift

class AddJettonBlockchainService {
    private let blockchain: Blockchain

    init(blockchain: Blockchain) {
        self.blockchain = blockchain
    }
}

extension AddJettonBlockchainService: IAddTokenBlockchainService {
    var placeholder: String {
        "add_token.input_placeholder.jetton_master_address".localized
    }

    func validate(reference: String) throws {
        do {
            _ = try TonSwift.Address.parse(reference)
        } catch {
            throw TokenError.invalidAddress
        }
    }

    func tokenQuery(reference: String) -> TokenQuery {
        var reference = reference

        do {
            let address = try TonSwift.Address.parse(reference)
            reference = address.toString(testOnly: TonKitManager.isTestNet, bounceable: true)
        } catch {}

        return TokenQuery(blockchainType: blockchain.type, tokenType: .jetton(address: reference))
    }

    func tokenSingle(reference: String) -> Single<Token> {
        guard let address = try? TonSwift.Address.parse(reference) else {
            return Single.error(TokenError.invalidAddress)
        }

        let tokenQuery = tokenQuery(reference: reference)

        return Single.create { [blockchain] observer in
            Task { [blockchain] in
                do {
                    let jetton = try await TonKit.Kit.jetton(address: address)

                    let token = Token(
                        coin: Coin(uid: tokenQuery.customCoinUid, name: jetton.name, code: jetton.symbol, image: jetton.image),
                        blockchain: blockchain,
                        type: tokenQuery.tokenType,
                        decimals: jetton.decimals
                    )

                    observer(.success(token))
                } catch {
                    observer(.error(TokenError.notFound(blockchainName: blockchain.name)))
                }
            }

            return Disposables.create()
        }
    }
}

extension AddJettonBlockchainService {
    enum TokenError: LocalizedError {
        case invalidAddress
        case notFound(blockchainName: String)

        var errorDescription: String? {
            switch self {
            case .invalidAddress: return "add_token.invalid_ton_address".localized
            case let .notFound(blockchainName): return "add_token.jetton_master_not_found".localized(blockchainName)
            }
        }
    }
}
