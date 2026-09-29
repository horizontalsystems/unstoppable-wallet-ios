import Foundation
import MarketKit
import Testing
@testable import WalletCore

// The Cross Pay deposit on XRP: to the provider's deposit address, with the provider's tag. Each
// failure here is a deposit the provider could not match. A classic deposit address, so the network
// setting does not matter (the app-hosted test still reads it through Core); X-address resolution is
// covered by the kit's own tests.
struct XrpDepositSendDataTests {
    @Test func noAttachmentPaysTheDepositAddressUntagged() throws {
        let payment = try Self.payment(depositAddress: Self.depositAddress, attachment: nil)

        #expect(payment.address == Self.depositAddress)
        #expect(payment.amount == 25)
        #expect(payment.tag == nil)
    }

    @Test func providerTagRidesTheDestinationTag() throws {
        let payment = try Self.payment(depositAddress: Self.depositAddress, attachment: .destinationTag("123456"))

        #expect(payment.address == Self.depositAddress)
        #expect(payment.tag == 123_456)
    }

    // a text memo has nowhere to go on XRP: the provider credits by tag only
    @Test func textAttachmentIsRefused() {
        #expect(throws: USwapMultiSwapApi.Attachment.AttachmentError.unsupported) {
            try Self.payment(depositAddress: Self.depositAddress, attachment: .text("order-42"))
        }
    }

    @Test func unknownAttachmentIsRefused() {
        #expect(throws: USwapMultiSwapApi.Attachment.AttachmentError.unsupported) {
            try Self.payment(depositAddress: Self.depositAddress, attachment: .unknown(type: "note", value: "x"))
        }
    }

    @Test func tagTheFieldCannotHoldIsRefused() {
        #expect(throws: USwapMultiSwapApi.Attachment.AttachmentError.outOfRange) {
            try Self.payment(depositAddress: Self.depositAddress, attachment: .destinationTag("4294967296"))
        }
    }
}

extension XrpDepositSendDataTests {
    private static let depositAddress = "rHb9CJAWyB4rj91VRWn96DkukG4bwdtyTh"

    private static let xrpToken = Token(
        coin: Coin(uid: "ripple", name: "XRP", code: "XRP"),
        blockchain: Blockchain(type: .xrp, name: "XRP Ledger", explorerUrl: nil),
        type: .native,
        decimals: 6
    )

    private static func payment(depositAddress: String, attachment: USwapMultiSwapApi.Attachment?) throws -> (amount: Decimal, address: String, tag: UInt32?) {
        let sendData = try XrpSendHelper.depositSendData(token: xrpToken, amount: 25, depositAddress: depositAddress, attachment: attachment)

        guard case let .xrp(_, data, destinationTag) = sendData, case let .payment(amount, address) = data else {
            Issue.record("expected an XRP payment, got \(sendData)")
            return (0, "", nil)
        }

        return (amount, address, destinationTag)
    }
}
