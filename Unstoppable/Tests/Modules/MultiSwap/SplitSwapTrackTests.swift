import Foundation
import ObjectMapper
import Testing
@testable import WalletCore

/// /v3/split/track answers the /v3/track body with `splitUuid`: one deposit leg, then each output's payout
/// (and refund) legs tagged `meta.outputIndex`
struct SplitSwapTrackTests {
    @Test func flatSplitBodyDerivesOutputsFromPayoutLegs() throws {
        let response = try Self.response([
            "splitUuid": Self.splitUuid,
            "status": "swapping",
            "providers": ["SWAPUZ_SPLIT"],
            "hash": "0xdeposit",
            "fromAsset": "ETH.ETH",
            "toAsset": Self.usdt,
            "toAmount": "",
            "legs": [
                Self.depositLeg,
                Self.payoutLeg(index: 0, status: "completed", toAddress: Self.address0, toAmount: "39.00", hash: "0xpayout"),
                Self.payoutLeg(index: 1, status: "pending", toAddress: Self.address1),
            ],
        ])
        let outputs = try #require(response.outputs)

        #expect(response.legs.count == 3)
        #expect(response.toAmount == nil)
        #expect(outputs.map(\.index) == [0, 1])
        #expect(outputs.map(\.status) == ["completed", "pending"])
        #expect(outputs.map(\.toAddress) == [Self.address0, Self.address1])
        #expect(outputs.map(\.toAmount) == [39, nil])
        #expect(outputs.map(\.legs.count) == [1, 1])
    }

    @Test func sharedAddressOutputsStayDistinct() throws {
        let response = try Self.response(Self.splitBody(legs: [
            Self.depositLeg,
            Self.payoutLeg(index: 0, status: "pending", toAddress: Self.address0),
            Self.payoutLeg(index: 1, status: "pending", toAddress: Self.address0),
        ]))
        let outputs = try #require(response.outputs)

        #expect(outputs.map(\.index) == [0, 1])
        #expect(outputs.map(\.toAddress) == [Self.address0, Self.address0])
    }

    @Test func refundLegAttachesToOutputWithoutDrivingStatus() throws {
        let response = try Self.response(Self.splitBody(legs: [
            Self.depositLeg,
            Self.payoutLeg(index: 0, status: "completed", toAddress: Self.address0, toAmount: "39"),
            Self.payoutLeg(index: 1, status: "pending", toAddress: Self.address1),
            Self.payoutLeg(index: 1, status: "completed", toAddress: Self.address1, refund: true),
        ]))
        let outputs = try #require(response.outputs)
        let output = try #require(outputs.first { $0.index == 1 })

        #expect(output.status == "pending")
        #expect(output.legs.count == 2)
        #expect(output.legs.map(\.refund) == [false, true])
    }

    @Test func preObservationSplitBodyHasEmptyOutputs() throws {
        let response = try Self.response([
            "splitUuid": Self.splitUuid,
            "status": "not_started",
            "providers": ["SWAPUZ_SPLIT"],
            "legs": [],
        ])

        #expect(response.outputs?.isEmpty == true)
        #expect(response.fromAsset == nil)
    }

    @Test func emptyStringsReadAsNil() throws {
        let response = try Self.response([
            "splitUuid": Self.splitUuid,
            "status": "swapping",
            "fromAsset": "ETH.ETH",
            "toAsset": "",
            "toAmount": "",
            "hash": "",
            "legs": [],
        ])

        #expect(response.toAsset == nil)
        #expect(response.toAmount == nil)
        #expect(response.hash == nil)
    }

    @Test func completedSplitKeepsServerToAmountOnly() throws {
        let legs = [
            Self.depositLeg,
            Self.payoutLeg(index: 0, status: "completed", toAddress: Self.address0, toAmount: "39.00"),
            Self.payoutLeg(index: 1, status: "completed", toAddress: Self.address1, toAmount: "39.00"),
        ]

        var reported = Self.splitBody(status: "completed", legs: legs)
        reported["toAmount"] = "78.00"
        #expect(try Self.response(reported).toAmount == 78)

        var missing = Self.splitBody(status: "completed", legs: legs)
        missing["toAmount"] = ""
        #expect(try Self.response(missing).toAmount == nil)
    }

    @Test func completedSplitSumsOnlySeededOutputs() throws {
        var body = Self.splitBody(status: "completed", legs: [
            Self.depositLeg,
            Self.payoutLeg(index: 0, status: "completed", toAddress: Self.address0, toAmount: "39.00"),
            Self.payoutLeg(index: 1, status: "completed", toAddress: Self.address1, toAmount: "39.00"),
            Self.payoutLeg(index: 7, status: "completed", toAddress: Self.address1, toAmount: "1000.00"),
        ])
        body["toAmount"] = ""
        let response = try Self.response(body)

        let merged = USwapTracker.mergedOutputs(existing: Self.seededOutputs, reported: response.outputs)
        let amountOut = USwapTracker.completedAmountOut(status: .completed, reportedToAmount: response.toAmount, outputs: merged)

        #expect(merged?.map(\.index) == [0, 1])
        #expect(amountOut == 78)
    }

    @Test func completedAmountOutPrefersServerToAmount() {
        let amountOut = USwapTracker.completedAmountOut(status: .completed, reportedToAmount: 80, outputs: Self.seededOutputs)

        #expect(amountOut == 80)
    }

    @Test func singleBodyHasNoOutputs() throws {
        let response = try Self.response([
            "uuid": "swap-uuid",
            "status": "pending",
            "fromAsset": "ETH.ETH",
            "toAsset": Self.usdt,
            "toAmount": "2",
            "legs": [Self.depositLeg],
        ])

        #expect(response.outputs == nil)
    }

    @Test func mergeKeepsUnreportedOutputs() throws {
        let existing = Self.seededOutputs
        let reported = [
            USwapMultiSwapApi.TrackResponse.Output(index: 0, status: "completed", toAddress: Self.address0, fromAmount: nil, toAmount: 39, legs: []),
        ]

        let merged = try #require(USwapTracker.mergedOutputs(existing: existing, reported: reported))

        #expect(merged.count == 2)
        #expect(merged[0].status == .completed)
        #expect(merged[0].toAmount == 39)
        #expect(merged[0].fromAmount == 0.6)
        #expect(merged[1] == existing[1])
    }

    @Test func mergeIgnoresIndicesOutsideSeededSet() throws {
        let reported = [
            USwapMultiSwapApi.TrackResponse.Output(index: 1, status: "pending", toAddress: Self.address1, fromAmount: nil, toAmount: nil, legs: []),
            USwapMultiSwapApi.TrackResponse.Output(index: 7, status: "completed", toAddress: Self.address0, fromAmount: nil, toAmount: 1000, legs: []),
        ]

        let merged = try #require(USwapTracker.mergedOutputs(existing: Self.seededOutputs, reported: reported))

        #expect(merged.map(\.index) == [0, 1])
        #expect(merged[1].status == .pending)
    }

    @Test func mergeWithoutSeededOutputsIgnoresReport() throws {
        let reported = [
            USwapMultiSwapApi.TrackResponse.Output(index: 0, status: "completed", toAddress: Self.address0, fromAmount: nil, toAmount: 39, legs: []),
        ]

        #expect(try #require(USwapTracker.mergedOutputs(existing: nil, reported: reported)).isEmpty)
        #expect(try #require(USwapTracker.mergedOutputs(existing: [], reported: reported)).isEmpty)
    }

    @Test func mergeKeepsExistingForSingleSwap() {
        #expect(USwapTracker.mergedOutputs(existing: Self.seededOutputs, reported: nil) == Self.seededOutputs)
    }

    @Test func pauseReasonIsTopLevel() throws {
        var body = Self.splitBody(status: "action_required", legs: [Self.depositLeg])
        body["meta"] = ["pauseReason": "manual_review"]

        #expect(try Self.response(body).pauseReason == "manual_review")
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
    private static let splitUuid = "be52c0bd-8370-4cb3-82bb-169b34201c45"
    private static let usdt = "ETH.USDT-0XDAC17F958D2EE523A2206206994597C13D831EC7"
    private static let address0 = "0x3f4e9c3ac73a4cff7540293c24a3d055e03fd78d"
    private static let address1 = "0x38e54bcb23d85097e5a1047eeda655e7aa42f8d1"

    private static var seededOutputs: [Swap.Output] {
        [
            Swap.Output(index: 0, status: .notStarted, toAddress: address0, fromAmount: 0.6, toAmount: nil, legs: []),
            Swap.Output(index: 1, status: .notStarted, toAddress: address1, fromAmount: 0.4, toAmount: nil, legs: []),
        ]
    }

    private static func response(_ json: [String: Any]) throws -> USwapMultiSwapApi.TrackResponse {
        try USwapMultiSwapApi.TrackResponseMapping(JSONObject: json).response
    }

    private static func output(fromAmount: Decimal?, toAmount: Decimal?) -> Swap.Output {
        Swap.Output(index: 0, status: .pending, toAddress: nil, fromAmount: fromAmount, toAmount: toAmount, legs: [])
    }

    private static var depositLeg: [String: Any] {
        [
            "chainId": "1", "status": "completed", "type": "native_send", "hash": "0xdeposit",
            "fromAsset": "ETH.ETH", "toAsset": "ETH.ETH", "fromAmount": "0.039", "toAddress": "0xff02",
        ]
    }

    private static func payoutLeg(index: Int, status: String, toAddress: String, toAmount: String? = nil, hash: String = "", refund: Bool = false) -> [String: Any] {
        var meta: [String: Any] = ["outputIndex": index]
        if refund {
            meta["refund"] = true
        }

        var leg: [String: Any] = [
            "chainId": "1", "status": status, "type": "native_send", "hash": hash,
            "fromAsset": usdt, "toAsset": usdt, "toAddress": toAddress, "meta": meta,
        ]
        if let toAmount {
            leg["toAmount"] = toAmount
        }
        return leg
    }

    private static func splitBody(status: String = "swapping", legs: [[String: Any]]) -> [String: Any] {
        [
            "splitUuid": splitUuid,
            "status": status,
            "providers": ["SWAPUZ_SPLIT"],
            "hash": "0xdeposit",
            "fromAsset": "ETH.ETH",
            "toAsset": usdt,
            "legs": legs,
        ]
    }
}
