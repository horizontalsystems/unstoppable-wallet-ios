import Foundation
import ObjectMapper
import Testing
@testable import WalletCore

/// The AML address precheck is driven by the route's `amlProviderId`: present -> `GET /v3/check-addresses`
/// with the SENDER addresses only (never the recipient) and the id verbatim; absent -> no call. No provider id lives in the app.
struct USwapAmlPrecheckTests {
    private typealias Api = USwapMultiSwapApi

    @Test func rateRouteDecodesAmlProviderId() throws {
        let withId = try Mapper<Api.RateQuoteResponse>().map(JSON: [
            "providers": ["QUICKEX"], "expectedBuyAmount": "1", "amlPolicy": "good", "amlProviderId": "quickex",
        ])
        let withoutId = try Mapper<Api.RateQuoteResponse>().map(JSON: [
            "providers": ["THORCHAIN"], "expectedBuyAmount": "1", "amlPolicy": "excellent",
        ])

        #expect(withId.quote.amlProviderId == "quickex")
        #expect(withId.quote.amlPolicy == "good")
        #expect(withoutId.quote.amlProviderId == nil)
    }

    @Test func previewResponseDecodesAmlProviderId() throws {
        let withId = try Mapper<Api.SwapResponseMapping>().map(JSON: ["expectedBuyAmount": "1", "previewToken": "t", "amlProviderId": "quickex"])
        let withoutId = try Mapper<Api.SwapResponseMapping>().map(JSON: ["expectedBuyAmount": "1", "previewToken": "t"])

        #expect(withId.response.amlProviderId == "quickex")
        #expect(withoutId.response.amlProviderId == nil)
    }

    @Test func isRequiredOnlyForANonEmptyId() {
        #expect(USwapAmlPrecheck.isRequired(amlProviderId: "quickex"))
        #expect(!USwapAmlPrecheck.isRequired(amlProviderId: nil))
        #expect(!USwapAmlPrecheck.isRequired(amlProviderId: ""))
    }

    /// Sender addresses only, trimmed and deduplicated; an empty sender set stays empty (the provider
    /// treats it as inconclusive, never as a pass).
    @Test func addressesAreSenderOnlyAndDeduped() {
        #expect(USwapAmlPrecheck.addresses(sender: ["bc1qsender", "bc1qother"]) == ["bc1qsender", "bc1qother"])
        #expect(USwapAmlPrecheck.addresses(sender: ["bc1qsender", " bc1qsender ", "bc1qsender"]) == ["bc1qsender"])
        #expect(USwapAmlPrecheck.addresses(sender: [" ", ""]) == [])
        #expect(USwapAmlPrecheck.addresses(sender: []) == [])
    }

    @Test func checkAddressesRequestCarriesCsvAndIdVerbatim() {
        let request = Api.CheckAddressesRequest(addresses: ["bc1qsender", "bc1qother"], amlProviderId: "quickex")

        #expect(request.parameters["addresses"] as? String == "bc1qsender,bc1qother")
        #expect(request.parameters["amlProviderId"] as? String == "quickex")
    }

    // MARK: - addressBlacklisted

    @Test func providerErrorRecognisesAddressBlacklisted() throws {
        let blacklisted = try Mapper<Api.ProviderErrorResponse>().map(JSON: [
            "error": "Destination address is blacklisted", "provider": "QUICKEX", "errorCode": "addressBlacklisted",
        ]).providerError
        let other = Api.ProviderError(providerId: "QUICKEX", message: nil, errorCode: "amountOutOfRange", minimumAmount: 1, maximumAmount: nil)

        #expect(blacklisted.isAddressBlacklisted)
        #expect(blacklisted.message == "Destination address is blacklisted")
        #expect(!other.isAddressBlacklisted)
    }

    @Test func commitErrorRecognisesAddressBlacklisted() {
        let providerError = Api.ProviderError(providerId: "QUICKEX", message: "blacklisted", errorCode: "addressBlacklisted", minimumAmount: nil, maximumAmount: nil)

        #expect(Api.CommitError(httpStatus: 403, status: nil, reason: "blacklisted", providerError: providerError).isAddressBlacklisted)
        #expect(!Api.CommitError(httpStatus: 409, status: "rate_changed", reason: nil, providerError: nil).isAddressBlacklisted)
    }
}
