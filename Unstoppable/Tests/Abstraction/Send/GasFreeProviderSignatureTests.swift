import Testing
@testable import Unstoppable
@testable import WalletCore

struct GasFreeProviderSignatureTests {
    // Reference vector computed independently via Python:
    //   import hmac, hashlib, base64
    //   sig = base64.b64encode(hmac.new(b"test-secret",
    //                                    b"GET/tron/api/v1/config/token/all1700000000",
    //                                    hashlib.sha256).digest()).decode()
    @Test func computesReferenceVector() {
        let signature = GasFreeProvider.computeSignature(
            method: "GET",
            fullPath: "/tron/api/v1/config/token/all",
            timestamp: 1_700_000_000,
            apiSecret: "test-secret"
        )

        #expect(signature == "pVLtIlwAPxuHZXkA6BmIYkrYQQ6DbsKhs1snxu5Dnu4=")
    }

    @Test func differentSecretProducesDifferentSignature() {
        let signatureA = GasFreeProvider.computeSignature(
            method: "GET",
            fullPath: "/tron/api/v1/config/token/all",
            timestamp: 1_700_000_000,
            apiSecret: "secret-a"
        )
        let signatureB = GasFreeProvider.computeSignature(
            method: "GET",
            fullPath: "/tron/api/v1/config/token/all",
            timestamp: 1_700_000_000,
            apiSecret: "secret-b"
        )

        #expect(signatureA != signatureB)
    }

    @Test func methodIsCaseSensitiveInSignature() {
        // Spec uses uppercase HTTP method (GET/POST). Verify lowercase produces a
        // different signature so we don't silently accept a mixed-case METHOD.
        let upper = GasFreeProvider.computeSignature(
            method: "GET",
            fullPath: "/tron/api/v1/config/token/all",
            timestamp: 1_700_000_000,
            apiSecret: "test-secret"
        )
        let lower = GasFreeProvider.computeSignature(
            method: "get",
            fullPath: "/tron/api/v1/config/token/all",
            timestamp: 1_700_000_000,
            apiSecret: "test-secret"
        )

        #expect(upper != lower)
    }
}
