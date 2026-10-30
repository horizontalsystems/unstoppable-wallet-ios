import Foundation
import MarketKit
import NearKit
import RxSwift
import Testing
@testable import WalletCore

/// The receiver check of Android `NearAddressValidator` the address parser cannot make: the account
/// itself is refused (whether a named account exists is NearAddressParserItemTests).
struct NearRecipientCheckTests {
    @Test func ownAccountIsRefused() {
        let handler = Self.handler()

        let cautions = Self.cautions(handler.sendData(amount: 1, address: Self.ownAddress, memo: nil))

        #expect(cautions.first?.text == "send.address_error.own_address".localized("NEAR"))
        #expect(cautions.first?.title == "send.address.invalid_address".localized)
    }

    @Test func namedAndImplicitAccountsPass() {
        #expect(Self.isValid(Self.handler().sendData(amount: 1, address: Self.named, memo: nil)))
        #expect(Self.isValid(Self.handler().sendData(amount: 1, address: Self.implicit, memo: nil)))
    }

    @Test func malformedAccountIdIsRefused() {
        let handler = Self.handler()

        let cautions = Self.cautions(handler.sendData(amount: 1, address: "Alice..near", memo: nil))

        #expect(cautions.first?.text == "send.address.invalid_address".localized)
    }

    /// only a NEP-141 ft_transfer carries a memo (Android `sendMemoSupport`)
    @Test func memoOnlyForTokens() throws {
        #expect(Self.handler().memoType(address: Self.implicit) == .none)
        #expect(Self.handler(token: Self.usdtToken).memoType(address: Self.implicit) == .onChainPublic)

        let nativeSend = try #require(Self.sendData(Self.handler().sendData(amount: 1, address: Self.implicit, memo: "hi")))
        #expect(nativeSend.memo == nil)

        let tokenSend = try #require(Self.sendData(Self.handler(token: Self.usdtToken).sendData(amount: 1, address: Self.implicit, memo: "hi")))
        #expect(tokenSend.memo == "hi")

        let blankMemo = try #require(Self.sendData(Self.handler(token: Self.usdtToken).sendData(amount: 1, address: Self.implicit, memo: "  ")))
        #expect(blankMemo.memo == nil)
    }

    /// A NEAR deposit is a plain transfer with no memo field (Android `memoDelivery = None`): a token
    /// handler must not let its own memo support carry the provider's attachment.
    @Test func depositRefusesAnyAttachment() {
        let handler = Self.handler(token: Self.usdtToken)

        #expect(throws: USwapMultiSwapApi.Attachment.AttachmentError.undeliverable) {
            try handler.depositSendData(amount: 1, address: Self.implicit, attachment: .text("order-42"), settings: nil)
        }
        #expect(throws: USwapMultiSwapApi.Attachment.AttachmentError.unsupported) {
            try handler.depositSendData(amount: 1, address: Self.implicit, attachment: .destinationTag("42"), settings: nil)
        }
    }

    @Test func depositWithoutAttachmentPaysTheDepositAddress() throws {
        let handler = Self.handler(token: Self.usdtToken)

        let result = try handler.depositSendData(amount: 25, address: Self.implicit, attachment: nil, settings: nil)
        let sendData = try #require(Self.sendData(result))

        #expect(sendData.address == Self.implicit)
        #expect(sendData.amount == 25)
        #expect(sendData.memo == nil)
    }

    /// a Private Send or Cross Pay payout to NEAR is not refused up front (unlike XRP and Stellar)
    @Test func nearRecipientIsNotRefusedUpFront() {
        #expect(!PrivateSendHandlerProvider.unsupportedBlockchainTypes.contains(.near))
    }

    @Test func swapDepositAttachmentIsRefused() throws {
        #expect(throws: USwapMultiSwapApi.Attachment.AttachmentError.undeliverable) {
            try USwapMultiSwapApi.Attachment.memo(.text("order-42"), memoType: BlockchainType.near.memoType)
        }
        #expect(try USwapMultiSwapApi.Attachment.memo(nil, memoType: BlockchainType.near.memoType) == nil)
    }
}

extension NearRecipientCheckTests {
    static let ownAddress = String(repeating: "a", count: 64)
    static let implicit = "98793cd91a3f870fb126f66285808c7e094afcfc4eda8a970f6648cdf0dbd6de"
    static let named = "alice.near"

    static let nearToken = Token(
        coin: Coin(uid: "near", name: "NEAR Protocol", code: "NEAR"),
        blockchain: Blockchain(type: .near, name: "Near Protocol", explorerUrl: nil),
        type: .native,
        decimals: 24
    )

    static let usdtToken = Token(
        coin: Coin(uid: "tether", name: "Tether", code: "USDT"),
        blockchain: Blockchain(type: .near, name: "Near Protocol", explorerUrl: nil),
        type: .nep141(contractId: "usdt.tether-token.near"),
        decimals: 6
    )

    static func handler(token: Token = NearRecipientCheckTests.nearToken) -> NearPreSendHandler {
        NearPreSendHandler(token: token, adapter: StubSendNearAdapter())
    }

    static func cautions(_ result: SendDataResult) -> [CautionNew] {
        guard case let .invalid(cautions) = result else {
            Issue.record("expected the address to be refused")
            return []
        }
        return cautions
    }

    static func isValid(_ result: SendDataResult) -> Bool {
        if case .valid = result {
            return true
        }
        return false
    }

    static func sendData(_ result: SendDataResult) -> (amount: Decimal, address: String, memo: String?)? {
        guard case let .valid(sendData) = result, case let .near(_, amount, address, memo) = sendData else {
            return nil
        }
        return (amount, address, memo)
    }

    final class StubSendNearAdapter: ISendNearAdapter, IBalanceAdapter {
        let isMainNet = true
        let balanceState: AdapterState = .synced
        let balanceStateUpdatedObservable: Observable<AdapterState> = .never()
        let balanceData = BalanceData(balance: 1)
        let balanceDataUpdatedObservable: Observable<BalanceData> = .never()

        let address = NearRecipientCheckTests.ownAddress
        let fee = Decimal(string: "0.0000446")!
        let availableNear: Decimal = 1
        let pendingTransactionHashes = Set<String>()

        func estimate(address _: String, amount _: Decimal, memo _: String?) async throws -> NearSendEstimate {
            fatalError("not estimated in these tests")
        }

        func send(amount _: Decimal, address _: String, memo _: String?, estimate _: NearSendEstimate, signer _: NearKit.Signer) async throws -> String {
            fatalError("not sent in these tests")
        }
    }
}
