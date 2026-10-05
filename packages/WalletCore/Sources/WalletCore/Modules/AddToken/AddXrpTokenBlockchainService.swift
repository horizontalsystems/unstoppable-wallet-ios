import Foundation
import HsExtensions
import MarketKit
import XrpKit

/// Adds an XRPL issued currency by reference (Android `AddXrpTokenBlockchainService`). Accepted
/// forms: `CODE.issuer`, `CODE-issuer`, `issuer.CODE`, or an explorer token URL. CODE may be the
/// 3-character code, the 40-hex ledger form, or a longer name such as `RLUSD`, converted to hex.
class AddXrpTokenBlockchainService {
    private let blockchain: Blockchain

    init(blockchain: Blockchain) {
        self.blockchain = blockchain
    }

    private struct Parsed {
        let currency: String
        let issuer: String
    }

    private func parse(_ input: String) -> Parsed? {
        var text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return nil }

        // https://xrpscan.com/token/RLUSD.rMxCK... or https://bithomp.com/token/issuer/CODE
        if text.hasPrefix("http"), let range = text.range(of: "/token/") {
            text = String(text[range.upperBound...]).trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        }

        let parts = text.split(whereSeparator: { ".-/:".contains($0) }).map(String.init).filter { !$0.isEmpty }
        guard parts.count == 2 else { return nil }

        let (a, b) = (parts[0], parts[1])
        let rawCode: String
        let issuer: String
        if Self.isClassicAddress(b) {
            (rawCode, issuer) = (a, b)
        } else if Self.isClassicAddress(a) {
            (rawCode, issuer) = (b, a)
        } else {
            return nil
        }

        guard let currency = Self.ledgerCurrency(code: rawCode) else { return nil }
        return Parsed(currency: currency, issuer: issuer)
    }

    // an issuer is an account: the tag an X-address may carry has no meaning here
    private static func isClassicAddress(_ value: String) -> Bool {
        !XAddress.isXAddress(value) && AccountId.isValid(address: value)
    }

    /// 3-character and 40-hex codes are kept; a 4..20 character ASCII name becomes its hex form.
    private static func ledgerCurrency(code: String) -> String? {
        if code.uppercased() == CurrencyCodec.xrp { return nil }
        if XrpKit.Kit.isValidCurrencyCode(code) {
            return code.count == 40 ? code.uppercased() : code
        }
        if (4 ... 20).contains(code.count), code.unicodeScalars.allSatisfy({ (0x21 ... 0x7E).contains($0.value) }) {
            let hex = code.hs.data.hs.hex.uppercased()
            return hex.padding(toLength: 40, withPad: "0", startingAt: 0)
        }
        return nil
    }
}

extension AddXrpTokenBlockchainService: IAddTokenBlockchainService {
    var placeholder: String {
        "add_token.input_placeholder.xrp_currency".localized
    }

    func validate(reference: String) throws {
        guard parse(reference) != nil else {
            throw TokenError.invalidReference
        }
    }

    func tokenQuery(reference: String) -> TokenQuery {
        let parsed = parse(reference)
        return TokenQuery(blockchainType: blockchain.type, tokenType: .xrpAsset(currency: parsed?.currency ?? "", issuer: parsed?.issuer ?? ""))
    }

    // the ledger keeps no metadata for an issued currency: the code is the name and the symbol
    func token(reference: String) async throws -> Token {
        guard let parsed = parse(reference) else {
            throw TokenError.invalidReference
        }

        let tokenQuery = tokenQuery(reference: reference)
        let code = XrpKit.Kit.displayCurrencyCode(parsed.currency)

        return Token(
            coin: Coin(uid: tokenQuery.customCoinUid, name: code, code: code),
            blockchain: blockchain,
            type: tokenQuery.tokenType,
            decimals: XrpKitManager.issuedTokenDecimals
        )
    }
}

extension AddXrpTokenBlockchainService {
    enum TokenError: LocalizedError {
        case invalidReference

        var errorDescription: String? {
            switch self {
            case .invalidReference: return "add_token.invalid_xrp_currency".localized
            }
        }
    }
}
