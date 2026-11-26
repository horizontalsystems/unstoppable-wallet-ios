import Foundation
import MarketKit
import NearKit

/// Adds a NEP-141 token by its contract account id (`usdt.tether-token.near`) or a NearBlocks token
/// link (Android `AddNearTokenBlockchainService`). Name, symbol and decimals come from the
/// contract's `ft_metadata`.
class AddNearTokenBlockchainService {
    private let blockchain: Blockchain
    private let rpcUrls: [URL]

    init(blockchain: Blockchain, rpcUrls: [URL]) {
        self.blockchain = blockchain
        self.rpcUrls = rpcUrls
    }

    /// https://nearblocks.io/token/usdt.tether-token.near?tab=holders -> usdt.tether-token.near
    static func contractId(reference: String) -> String? {
        var text = reference.trimmingCharacters(in: .whitespacesAndNewlines)

        // a contract id such as `http.near` has no `/token/` and is kept whole, as on Android
        if text.hasPrefix("http"), let range = text.range(of: "/token/") {
            text = String(text[range.upperBound...])
            if let end = text.firstIndex(where: { $0 == "?" || $0 == "#" }) {
                text = String(text[..<end])
            }
            text = text.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        }

        text = text.lowercased()
        return NearKit.Kit.isValid(accountId: text) ? text : nil
    }
}

extension AddNearTokenBlockchainService: IAddTokenBlockchainService {
    var placeholder: String {
        "add_token.input_placeholder.contract_address".localized
    }

    func validate(reference: String) throws {
        guard Self.contractId(reference: reference) != nil else {
            throw TokenError.invalidReference
        }
    }

    func tokenQuery(reference: String) -> TokenQuery {
        TokenQuery(blockchainType: blockchain.type, tokenType: .nep141(contractId: Self.contractId(reference: reference) ?? ""))
    }

    func token(reference: String) async throws -> Token {
        guard let contractId = Self.contractId(reference: reference) else {
            throw TokenError.invalidReference
        }

        let tokenQuery = tokenQuery(reference: reference)
        let metadata: FtMetadata

        do {
            // the kit bounds decimals and text lengths of the untrusted metadata
            metadata = try await NearKit.Kit.ftMetadata(contractId: contractId, rpcUrls: rpcUrls)
        } catch {
            throw TokenError.notFound(blockchainName: blockchain.name)
        }

        let name = metadata.name.trimmingCharacters(in: .whitespaces).isEmpty ? metadata.symbol : metadata.name

        return Token(
            coin: Coin(uid: tokenQuery.customCoinUid, name: name, code: metadata.symbol),
            blockchain: blockchain,
            type: tokenQuery.tokenType,
            decimals: metadata.decimals
        )
    }
}

extension AddNearTokenBlockchainService {
    enum TokenError: LocalizedError {
        case invalidReference
        case notFound(blockchainName: String)

        var errorDescription: String? {
            switch self {
            case .invalidReference: return "add_token.invalid_contract_address".localized
            case let .notFound(blockchainName): return "add_token.contract_address_not_found".localized(blockchainName)
            }
        }
    }
}
