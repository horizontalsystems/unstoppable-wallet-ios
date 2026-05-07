import Foundation
import HsToolKit
import MarketKit
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

    func token(reference: String) async throws -> Token {
        guard let address = try? TonSwift.Address.parse(reference) else {
            throw TokenError.invalidAddress
        }

        let tokenQuery = tokenQuery(reference: reference)

        do {
            let jetton = try await TonKit.Kit.jetton(address: address)
            return Token(
                coin: Coin(uid: tokenQuery.customCoinUid, name: jetton.name, code: jetton.symbol, image: jetton.image),
                blockchain: blockchain,
                type: tokenQuery.tokenType,
                decimals: jetton.decimals
            )
        } catch {
            throw TokenError.notFound(blockchainName: blockchain.name)
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
