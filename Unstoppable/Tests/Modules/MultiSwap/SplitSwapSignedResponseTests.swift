import Foundation
import ObjectMapper
import Testing
@testable import WalletCore

struct SplitSwapSignedResponseTests {
    @Test func splitSignedParsesAggregateBody() throws {
        let response = try USwapMultiSwapApi.SplitSignedResponseMapping(JSONObject: [
            "splitUuid": "be52c0bd",
            "status": "signed",
            "hash": "0xdeposit",
        ]).response

        #expect(response.splitUuid == "be52c0bd")
        #expect(response.status == "signed")
        #expect(response.hash == "0xdeposit")
    }

    /// The report succeeded whether or not the server echoes the status; only a body without the id is malformed
    @Test func splitSignedWithoutStatusParses() throws {
        let response = try USwapMultiSwapApi.SplitSignedResponseMapping(JSONObject: ["splitUuid": "be52c0bd"]).response

        #expect(response.splitUuid == "be52c0bd")
        #expect(response.status == nil)
        #expect(response.hash == nil)
    }

    @Test func splitSignedWithoutSplitUuidThrows() {
        #expect(throws: (any Error).self) {
            try USwapMultiSwapApi.SplitSignedResponseMapping(JSONObject: ["status": "signed"])
        }
    }

    @Test func splitRequestNeverSendsFloating() {
        var request = USwapMultiSwapApi.SplitRequest(
            sellAsset: "ETH.ETH",
            sellAmount: 0.039,
            slippage: 1,
            chainId: "1",
            outputs: [
                .init(buyAsset: "ETH.USDT", percent: 50, destinationAddress: "0x1"),
                .init(buyAsset: "ETH.USDT", percent: 50, destinationAddress: "0x2"),
            ]
        )
        request.providerId = "SWAPUZ_SPLIT"
        request.refundAddress = "0x3"

        let parameters = request.parameters

        #expect(parameters["floating"] == nil)
        #expect(parameters["amountType"] as? String == "percent")
    }
}
