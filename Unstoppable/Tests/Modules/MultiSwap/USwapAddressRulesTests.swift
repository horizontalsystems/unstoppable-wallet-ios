import Foundation
import MarketKit
import ObjectMapper
import Testing
@testable import WalletCore

/// A route's `addressRules` decide every Zcash address the app sends: unified when the rule names
/// `unified`, transparent otherwise; `source.sameAsRefund` makes the source the refund address.
struct USwapAddressRulesTests {
    private typealias Rules = USwapMultiSwapApi.ZcashAddressRules

    private static let documented: [String: Any] = [
        "destination": [
            "unified": ["receivers": ["orchard", "sapling"], "requiresOneOf": ["orchard", "transparent"]],
            "transparent": true,
            "tex": true,
        ],
        "refund": ["transparent": true],
        "source": ["transparent": true, "sameAsRefund": true],
    ]

    @Test func decodesDocumentedObject() throws {
        let rules = try Mapper<USwapMultiSwapApi.ZcashAddressRulesResponse>().map(JSON: Self.documented).rules

        #expect(rules.destination?.unified == Rules.Unified(receivers: ["orchard", "sapling"], requiresOneOf: ["orchard", "transparent"]))
        #expect(rules.destination?.transparent == true)
        #expect(rules.destination?.tex == true)
        #expect(rules.refund?.unified == nil)
        #expect(rules.refund?.transparent == true)
        #expect(rules.source?.sameAsRefund == true)
    }

    @Test func rateRouteCarriesAddressRules() throws {
        let response = try Mapper<USwapMultiSwapApi.RateQuoteResponse>().map(JSON: [
            "providers": ["EXOLIX"],
            "expectedBuyAmount": "1.5",
            "addressRules": Self.documented,
        ])

        #expect(response.quote.addressRules?.destination?.unified != nil)
        #expect(response.quote.providerId == "EXOLIX")
    }

    @Test func previewResponseCarriesAddressRules() throws {
        let response = try Mapper<USwapMultiSwapApi.SwapResponseMapping>().map(JSON: [
            "expectedBuyAmount": "1.5",
            "previewToken": "token",
            "addressRules": ["refund": ["transparent": true], "source": ["transparent": true]],
        ])

        #expect(response.response.addressRules?.refund?.transparent == true)
        #expect(response.response.addressRules?.source?.sameAsRefund == false)
        #expect(response.response.addressRules?.destination == nil)
    }

    // MARK: - Kinds

    @Test func destinationKindFollowsUnifiedPresence() throws {
        let rules = try Mapper<USwapMultiSwapApi.ZcashAddressRulesResponse>().map(JSON: Self.documented).rules

        #expect(USwapZcashAddressPolicy.destinationKind(rules: rules, sellBlockchainType: .ethereum, executionType: "transfer") == .unified(receivers: ["orchard", "sapling"], requiresOneOf: ["orchard", "transparent"]))
        #expect(USwapZcashAddressPolicy.destinationAcceptsTex(rules: rules))
        #expect(USwapZcashAddressPolicy.refundKind(rules: rules) == .transparent)
        #expect(USwapZcashAddressPolicy.sourcePolicy(rules: rules) == .sameAsRefund)
    }

    /// A vault deposit sold from an OP_RETURN-memo chain cannot name a unified address in its memo: the
    /// destination is transparent whatever the rule recommends. Other execution types and memo-capable
    /// sell chains keep the rule.
    @Test func vaultDepositFromOpReturnChainForcesTransparentDestination() throws {
        let rules = try Mapper<USwapMultiSwapApi.ZcashAddressRulesResponse>().map(JSON: Self.documented).rules

        #expect(USwapZcashAddressPolicy.destinationKind(rules: rules, sellBlockchainType: .bitcoin, executionType: "thorchain_deposit") == .transparent)
        #expect(USwapZcashAddressPolicy.destinationKind(rules: rules, sellBlockchainType: .litecoin, executionType: "thorchain_deposit") == .transparent)
        #expect(USwapZcashAddressPolicy.destinationKind(rules: rules, sellBlockchainType: .ethereum, executionType: "thorchain_deposit") != .transparent)
        #expect(USwapZcashAddressPolicy.destinationKind(rules: rules, sellBlockchainType: .bitcoin, executionType: "transfer") != .transparent)
        #expect(USwapZcashAddressPolicy.destinationKind(rules: rules, sellBlockchainType: .bitcoin, executionType: nil) != .transparent)
    }

    @Test func noRulesMeanTransparentAndNoSource() {
        #expect(USwapZcashAddressPolicy.destinationKind(rules: nil, sellBlockchainType: .ethereum, executionType: nil) == .transparent)
        #expect(!USwapZcashAddressPolicy.destinationAcceptsTex(rules: nil))
        #expect(USwapZcashAddressPolicy.refundKind(rules: nil) == .transparent)
        #expect(USwapZcashAddressPolicy.sourcePolicy(rules: nil) == .omit)
    }

    @Test func recipientValidationRejectsWhatIsNotAZcashAddress() {
        #expect(throws: ZcashRecipientMismatch.unparseable) {
            try USwapZcashAddressPolicy.validateRecipient("0x1234567890abcdef1234567890abcdef12345678", kind: .transparent, acceptsTex: false, acceptsTransparent: true)
        }
        #expect(throws: ZcashRecipientMismatch.unparseable) {
            try USwapZcashAddressPolicy.validateRecipient("", kind: .unified(receivers: ["orchard"], requiresOneOf: []), acceptsTex: true, acceptsTransparent: false)
        }
    }

    /// `transparent: false` is honoured (a transparent or TEX recipient is refused), except where the
    /// OP_RETURN memo guard forces a transparent destination, which every such route takes.
    @Test func transparentAcceptanceFollowsTheRuleUnlessForced() {
        let unified = Rules.Unified(receivers: ["orchard"], requiresOneOf: ["orchard"])
        let shieldedOnly = Rules(destination: Rules.Rule(unified: unified, transparent: false), refund: nil, source: nil)
        let documented = Rules(destination: Rules.Rule(unified: unified, transparent: true, tex: true), refund: nil, source: nil)

        #expect(!USwapZcashAddressPolicy.destinationAcceptsTransparent(rules: shieldedOnly, sellBlockchainType: .ethereum, executionType: "transfer"))
        #expect(USwapZcashAddressPolicy.destinationAcceptsTransparent(rules: documented, sellBlockchainType: .ethereum, executionType: "transfer"))
        #expect(USwapZcashAddressPolicy.destinationAcceptsTransparent(rules: nil, sellBlockchainType: .ethereum, executionType: nil))
        // forced transparent: the destination is transparent whatever the rule says
        #expect(USwapZcashAddressPolicy.destinationAcceptsTransparent(rules: shieldedOnly, sellBlockchainType: .bitcoin, executionType: "thorchain_deposit"))
        #expect(USwapZcashAddressPolicy.destinationKind(rules: shieldedOnly, sellBlockchainType: .bitcoin, executionType: "thorchain_deposit") == .transparent)
    }

    @Test func unifiedRefundAndOwnSource() {
        let unified = Rules.Unified(receivers: ["orchard"], requiresOneOf: ["orchard"])
        let rules = Rules(
            destination: nil,
            refund: Rules.Rule(unified: unified),
            source: Rules.Rule(unified: unified, sameAsRefund: false)
        )

        #expect(USwapZcashAddressPolicy.refundKind(rules: rules) == .unified(receivers: ["orchard"], requiresOneOf: ["orchard"]))
        #expect(USwapZcashAddressPolicy.sourcePolicy(rules: rules) == .own(.unified(receivers: ["orchard"], requiresOneOf: ["orchard"])))
    }

    // MARK: - receiversToBuild

    @Test func receiversIncludeTransparentWhenNamed() {
        let receivers = USwapZcashAddressPolicy.receiversToBuild(Rules.Unified(receivers: ["orchard", "transparent"], requiresOneOf: ["orchard"]))

        #expect(receivers == [.orchard, .transparent])
    }

    @Test func receiversGuaranteeRequiresOneOf() {
        let receivers = USwapZcashAddressPolicy.receiversToBuild(Rules.Unified(receivers: ["sapling"], requiresOneOf: ["orchard", "transparent"]))

        #expect(receivers == [.sapling, .orchard])
    }

    @Test func receiversSatisfiedRequirementAddsNothing() {
        let receivers = USwapZcashAddressPolicy.receiversToBuild(Rules.Unified(receivers: ["orchard", "sapling"], requiresOneOf: ["orchard", "transparent"]))

        #expect(receivers == [.orchard, .sapling])
    }

    @Test func receiversFallBackToShieldedPair() {
        #expect(USwapZcashAddressPolicy.receiversToBuild(Rules.Unified(receivers: [], requiresOneOf: [])) == [.orchard, .sapling])
        #expect(USwapZcashAddressPolicy.receiversToBuild(Rules.Unified(receivers: ["unknown"], requiresOneOf: ["unknown"])) == [.orchard, .sapling])
        #expect(USwapZcashAddressPolicy.receiversToBuild(kind: .transparent).isEmpty)
    }

    // MARK: - Recipient parser filter

    @Test func parserFilterRestrictsTransparentOnlyRoutes() {
        let unified = ZcashAddressKind.unified(receivers: ["orchard"], requiresOneOf: [])

        #expect(USwapZcashAddressPolicy.recipientParserFilter(kind: .transparent, acceptsTransparent: true) != nil)
        #expect(USwapZcashAddressPolicy.recipientParserFilter(kind: unified, acceptsTransparent: true) == nil)
        // a unified rule that refuses transparent restricts the field to shielded addresses
        #expect(USwapZcashAddressPolicy.recipientParserFilter(kind: unified, acceptsTransparent: false) != nil)
    }

    // MARK: - Preview 400 { message, field, addressRules }

    @Test func previewAddressErrorParsesFieldBody() throws {
        let error = try #require(USwapMultiSwapApi.previewAddressError(statusCode: 400, json: [
            "message": "refundAddress is a unified address; this route takes transparent",
            "field": "refundAddress",
            "addressRules": Self.documented,
        ]))

        #expect(error.field == "refundAddress")
        #expect(error.message == "refundAddress is a unified address; this route takes transparent")
        #expect(error.addressRules?.refund?.transparent == true)
    }

    @Test func ordinaryProviderErrorIsNotAnAddressError() {
        let body: [String: Any] = ["error": "Amount out of range", "provider": "QUICKEX", "errorCode": "amountOutOfRange"]

        #expect(USwapMultiSwapApi.previewAddressError(statusCode: 400, json: body) == nil)
        #expect(USwapMultiSwapApi.previewAddressError(statusCode: 403, json: ["message": "x", "field": "refundAddress"]) == nil)
    }
}
