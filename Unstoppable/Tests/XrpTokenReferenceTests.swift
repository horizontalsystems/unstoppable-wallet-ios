import Foundation
import MarketKit
import Testing
@testable import WalletCore

// Adding an XRPL issued currency by reference (Android `AddXrpTokenBlockchainService`).
struct XrpTokenReferenceTests {
    private let service = AddXrpTokenBlockchainService(blockchain: Blockchain(type: .xrp, name: "XRP Ledger", explorerUrl: nil))

    private static let issuer = "rMxCKbEDwqr76QuheSUMdEGf4B9xJ8m5De"
    // "RLUSD" in the ledger's 40-hex form, as the token catalog lists it
    private static let rlusdHex = "524C555344000000000000000000000000000000"

    private func parsed(_ reference: String) throws -> (currency: String, issuer: String) {
        try service.validate(reference: reference)

        guard case let .xrpAsset(currency, issuer) = service.tokenQuery(reference: reference).tokenType else {
            Issue.record("expected an xrpAsset token type")
            return ("", "")
        }

        return (currency, issuer)
    }

    @Test func threeCharacterCodeIsKeptAsIs() throws {
        let result = try parsed("USD.\(Self.issuer)")
        #expect(result.currency == "USD")
        #expect(result.issuer == Self.issuer)
    }

    @Test func longerNameBecomesItsHexForm() throws {
        #expect(try parsed("RLUSD.\(Self.issuer)").currency == Self.rlusdHex)
    }

    @Test func hexCodeIsUppercased() throws {
        #expect(try parsed("\(Self.rlusdHex.lowercased()).\(Self.issuer)").currency == Self.rlusdHex)
    }

    @Test func separatorsAndOrderAreInterchangeable() throws {
        let expected = ("USD", Self.issuer)
        for reference in ["USD.\(Self.issuer)", "USD-\(Self.issuer)", "USD:\(Self.issuer)", "USD/\(Self.issuer)", "\(Self.issuer).USD"] {
            let result = try parsed(reference)
            #expect(result.currency == expected.0)
            #expect(result.issuer == expected.1)
        }
    }

    @Test func explorerLinkIsAccepted() throws {
        let result = try parsed("https://xrpscan.com/token/RLUSD.\(Self.issuer)")
        #expect(result.currency == Self.rlusdHex)
        #expect(result.issuer == Self.issuer)
    }

    @Test func surroundingWhitespaceIsTrimmed() throws {
        #expect(try parsed("  USD.\(Self.issuer)  ").currency == "USD")
    }

    // XRP itself is not an issued currency: a trust line for it cannot exist
    @Test func nativeCodeIsRejected() {
        #expect(throws: AddXrpTokenBlockchainService.TokenError.invalidReference) { try service.validate(reference: "XRP.\(Self.issuer)") }
        #expect(throws: AddXrpTokenBlockchainService.TokenError.invalidReference) { try service.validate(reference: "xrp.\(Self.issuer)") }
    }

    // An issuer is an account; the tag an X-address carries has no meaning for a trust line
    @Test func xAddressIssuerIsRejected() {
        #expect(throws: AddXrpTokenBlockchainService.TokenError.invalidReference) { try service.validate(reference: "USD.XVLhHMPHU98es4dbozjVtdWzVrDjtV18pX8yuPT7y4xaEHi") }
    }

    @Test func malformedReferencesAreRejected() {
        for reference in ["", "USD", Self.issuer, "USD.rNotAnAddress", "USD.\(Self.issuer).extra", "..", "USD."] {
            #expect(throws: AddXrpTokenBlockchainService.TokenError.invalidReference) { try service.validate(reference: reference) }
        }
    }

    // The ledger keeps no metadata for an issued currency, so the code is the name and the symbol
    @Test func tokenIsBuiltLocallyFromTheCode() async throws {
        let token = try await service.token(reference: "RLUSD.\(Self.issuer)")

        #expect(token.coin.code == "RLUSD")
        #expect(token.coin.name == "RLUSD")
        #expect(token.decimals == XrpKitManager.issuedTokenDecimals)
        #expect(token.blockchain.type == .xrp)
    }
}
