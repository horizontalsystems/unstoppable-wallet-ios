import Foundation
import ObjectMapper
import Testing
@testable import WalletCore

struct SplitSwapTrackTests {
    @Test func splitBodyKeepsOutputsPerRecipient() throws {
        let response = try USwapMultiSwapApi.TrackResponseMapping(JSONObject: Self.splitBody).response
        let outputs = try #require(response.outputs)

        #expect(response.status == "swapping")
        #expect(response.toAmount == 110.5)
        #expect(outputs.map(\.index) == [0, 1])
        #expect(outputs.map(\.status) == ["completed", "swapping"])
        #expect(outputs.map(\.toAddress) == ["0x3f4e9c3ac73a4cff7540293c24a3d055e03fd78d", "0x38e54bcb23d85097e5a1047eeda655e7aa42f8d1"])
        #expect(outputs.map(\.fromAmount) == [Decimal(string: "0.0288571793"), Decimal(string: "0.0192381196")])
        #expect(outputs.map(\.toAmount) == [64.5, 46])
        #expect(outputs.map(\.legs.count) == [2, 2])
    }

    @Test func singleBodyHasNoOutputs() throws {
        let response = try USwapMultiSwapApi.TrackResponseMapping(JSONObject: Self.output(index: 0, status: "pending", toAddress: "0xabc", fromAmount: "1", toAmount: "2")).response

        #expect(response.outputs == nil)
    }

    @Test func percentsFollowDepositSharesAndAddUpTo100() {
        let outputs = [
            Self.output(fromAmount: 0.0288571793, toAmount: 64.5),
            Self.output(fromAmount: 0.0192381196, toAmount: 46),
        ]

        #expect(SwapInfoViewModel.percents(outputs: outputs) == [60, 40])
    }

    @Test func percentsFallBackToOutputAmounts() {
        let outputs = [
            Self.output(fromAmount: nil, toAmount: 1),
            Self.output(fromAmount: nil, toAmount: 1),
            Self.output(fromAmount: nil, toAmount: 1),
        ]

        #expect(SwapInfoViewModel.percents(outputs: outputs) == [33, 33, 34])
    }
}

extension SplitSwapTrackTests {
    private static func output(fromAmount: Decimal?, toAmount: Decimal?) -> Swap.Output {
        Swap.Output(index: 0, status: .pending, toAddress: nil, fromAmount: fromAmount, toAmount: toAmount, legs: [])
    }

    private static func output(index: Int, status: String, toAddress: String, fromAmount: String, toAmount: String, payoutHash: String = "") -> [String: Any] {
        [
            "index": index,
            "status": status,
            "fromAsset": "ETH.ETH",
            "toAsset": "ETH.USDT-0XDAC17F958D2EE523A2206206994597C13D831EC7",
            "fromAmount": fromAmount,
            "toAmount": toAmount,
            "toAddress": toAddress,
            "legs": [
                [
                    "chainId": "1", "status": "completed", "type": "native_send", "hash": "0xdeposit",
                    "fromAsset": "ETH.ETH", "toAsset": "ETH.ETH",
                ],
                [
                    "chainId": "1", "status": status == "completed" ? "completed" : "pending", "type": "native_send", "hash": payoutHash,
                    "fromAsset": "ETH.USDT-0XDAC17F958D2EE523A2206206994597C13D831EC7", "toAsset": "ETH.USDT-0XDAC17F958D2EE523A2206206994597C13D831EC7",
                ],
            ],
        ]
    }

    private static var splitBody: [String: Any] {
        [
            "splitUuid": "84396522-8370-4cb3-82bb-169b34201c45",
            "status": "swapping",
            "providers": ["SWAPUZ"],
            "hash": "0xdeposit",
            "outputs": [
                output(index: 0, status: "completed", toAddress: "0x3f4e9c3ac73a4cff7540293c24a3d055e03fd78d", fromAmount: "0.0288571793", toAmount: "64.5", payoutHash: "0xpayout"),
                output(index: 1, status: "swapping", toAddress: "0x38e54bcb23d85097e5a1047eeda655e7aa42f8d1", fromAmount: "0.0192381196", toAmount: "46"),
            ],
        ]
    }
}
