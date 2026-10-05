import Combine
import Foundation
import MarketKit
import Testing
@testable import WalletCore

// The deposit attachment of Private Send and Cross Pay on every chain but XRP: the default
// `depositSendData(attachment:)` turns it into a memo as the Private Send and Cross Pay handlers did
// before this method, and hands it to the chain's memo-based deposit method (Bitcoin overrides that one).
struct DepositAttachmentTests {
    @Test func noAttachmentBuildsWithoutMemo() throws {
        let handler = StubPreSendHandler(memoType: .onChainPublic)

        _ = try handler.depositSendData(amount: 1, address: Self.depositAddress, attachment: nil, settings: nil)

        #expect(handler.depositCalls.count == 1)
        #expect(handler.depositCalls.first?.memo == nil)
        #expect(handler.depositCalls.first?.address == Self.depositAddress)
    }

    @Test func deliverableTextRidesTheMemo() throws {
        let handler = StubPreSendHandler(memoType: .onChainPublic)

        _ = try handler.depositSendData(amount: 1, address: Self.depositAddress, attachment: .text("order-42"), settings: nil)

        #expect(handler.depositCalls.first?.memo == "order-42")
    }

    // the chain's handler is asked about the deposit address itself (shielded vs transparent Zcash)
    @Test func memoTypeIsAskedForTheDepositAddress() throws {
        let handler = StubPreSendHandler(memoType: .onChainPublic)

        _ = try handler.depositSendData(amount: 1, address: Self.depositAddress, attachment: .text("order-42"), settings: nil)

        #expect(handler.memoTypeAddresses.contains(Self.depositAddress))
    }

    @Test func textTheChainCannotDeliverIsRefused() {
        for memoType in [MemoType.none, .onChainPrivate, .local] {
            let handler = StubPreSendHandler(memoType: memoType)

            #expect(throws: USwapMultiSwapApi.Attachment.AttachmentError.undeliverable) {
                try handler.depositSendData(amount: 1, address: Self.depositAddress, attachment: .text("order-42"), settings: nil)
            }
            #expect(handler.depositCalls.isEmpty)
        }
    }

    // a tag has no field outside XRP, and an unknown kind cannot be carried at all
    @Test func tagAndUnknownAttachmentsAreRefused() {
        let handler = StubPreSendHandler(memoType: .onChainPublic)

        #expect(throws: USwapMultiSwapApi.Attachment.AttachmentError.unsupported) {
            try handler.depositSendData(amount: 1, address: Self.depositAddress, attachment: .destinationTag("123"), settings: nil)
        }
        #expect(throws: USwapMultiSwapApi.Attachment.AttachmentError.unsupported) {
            try handler.depositSendData(amount: 1, address: Self.depositAddress, attachment: .unknown(type: "note", value: "x"), settings: nil)
        }
        #expect(handler.depositCalls.isEmpty)
    }

    // Cross Pay's commit gate: XRP by its destination tag, every other chain by a delivered memo
    @Test func commitGateFollowsTheChain() throws {
        try USwapMultiSwapApi.Attachment.validate(.destinationTag("123"), blockchainType: .xrp)
        try USwapMultiSwapApi.Attachment.validate(.text("order-42"), blockchainType: .bitcoin)
        try USwapMultiSwapApi.Attachment.validate(nil, blockchainType: .ethereum)

        #expect(throws: USwapMultiSwapApi.Attachment.AttachmentError.unsupported) {
            try USwapMultiSwapApi.Attachment.validate(.text("order-42"), blockchainType: .xrp)
        }
        #expect(throws: USwapMultiSwapApi.Attachment.AttachmentError.unsupported) {
            try USwapMultiSwapApi.Attachment.validate(.destinationTag("123"), blockchainType: .bitcoin)
        }
        #expect(throws: USwapMultiSwapApi.Attachment.AttachmentError.undeliverable) {
            try USwapMultiSwapApi.Attachment.validate(.text("order-42"), blockchainType: .ethereum)
        }
    }
}

extension DepositAttachmentTests {
    private static let depositAddress = "deposit-address"

    private final class StubPreSendHandler: IPreSendHandler {
        private let memoTypeValue: MemoType
        private(set) var memoTypeAddresses = [String?]()
        private(set) var depositCalls = [(address: String, memo: String?)]()

        init(memoType: MemoType) {
            memoTypeValue = memoType
        }

        let state: AdapterState = .synced
        var statePublisher: AnyPublisher<AdapterState, Never> { Empty().eraseToAnyPublisher() }
        let balance: Decimal = 100
        var balancePublisher: AnyPublisher<Decimal, Never> { Empty().eraseToAnyPublisher() }

        func memoType(address: String?) -> MemoType {
            memoTypeAddresses.append(address)
            return memoTypeValue
        }

        func sendData(amount _: Decimal, address _: String, memo _: String?) -> SendDataResult {
            .invalid(cautions: [])
        }

        // the chain's own deposit method, as Bitcoin overrides it: reached through the default
        func depositSendData(amount _: Decimal, address: String, memo: String?, settings _: PreSendSettingsSnapshot?) -> SendDataResult {
            depositCalls.append((address, memo))
            return .invalid(cautions: [])
        }
    }
}
