import Foundation
import Testing
@testable import WalletCore

// A refused /v2/rate reaches the app as 200 with empty routes, 200 without routes, or a non-2xx carrying the
// same envelope as its body. The two JSON shapes below cover all three, and must yield the same provider errors.
struct CrossPayRateRefusalTests {
    @Test func everyRefusalShapeYieldsTheSameMinimum() {
        let providerErrors: [[String: Any]] = [["provider": "NEAR", "errorCode": "amountOutOfRange", "minimumAmount": "10"]]
        let shapes: [[String: Any]] = [
            ["routes": [Any](), "providerErrors": providerErrors],
            ["providerErrors": providerErrors],
        ]

        for json in shapes {
            let errors = USwapMultiSwapApi.rateProviderErrors(json: json)

            #expect(errors.count == 1)
            #expect(errors.first?.errorCode == "amountOutOfRange")
            #expect(errors.first?.minimumAmount == 10)
        }
    }

    @Test func unstructuredBodyHasNoProviderErrors() {
        #expect(USwapMultiSwapApi.rateProviderErrors(json: nil).isEmpty)
        #expect(USwapMultiSwapApi.rateProviderErrors(json: "Not Found").isEmpty)
        #expect(USwapMultiSwapApi.rateProviderErrors(json: ["error": "Unauthorized"]).isEmpty)
    }
}
