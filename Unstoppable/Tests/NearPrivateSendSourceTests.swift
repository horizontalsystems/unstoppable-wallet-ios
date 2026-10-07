import Foundation
import HsToolKit
import MarketKit
import Testing
@testable import WalletCore

// NEAR cannot fund a Private Send or Cross Pay order yet: refused before the order is committed, so
// none is left unpaid (Android has no NEAR deposit builder and fails only after the commit). The
// refusals come before anything that needs the app's services or the provider's asset map.
struct NearPrivateSendSourceTests {
    @Test func nearIsNotAPrivateSendOrCrossPaySource() {
        #expect(PrivateSendHandlerProvider.unsupportedSourceBlockchainTypes.contains(.near))
    }

    @Test func privateSendFromNearResolvesNoHandler() {
        let request = PrivateSendRequest(token: Self.nearToken, recipient: Self.recipient, amount: 1)

        let handler = PrivateSendHandlerProvider.handler(sendData: .privateSend(request: request)) { _, _, _ in
            fatalError("no order may be built for a NEAR source")
        }

        #expect(handler == nil)
    }

    @Test func crossPayFromNearResolvesNoHandler() {
        let request = CrossPayRequest(tokenIn: Self.nearToken, tokenOut: Self.token(.bitcoin), recipient: "bc1qexample", amount: 1)

        #expect(CrossPayHandlerProvider.instance(sendData: .crossPay(request: request)) == nil)
    }

    @Test func crossPayTabIsNotOfferedForNear() {
        #expect(!CrossPayPreSendViewModel.isSupported(token: Self.nearToken, service: Self.service()))
    }

    @Test func crossPayPairFundedByNearIsNotSupported() {
        #expect(!Self.service().supports(tokenIn: Self.nearToken, tokenOut: Self.token(.bitcoin)))
    }

    // NEAR as the recipient's chain is a separate question and stays open
    @Test func nearRecipientIsNotRefusedUpFront() {
        #expect(!PrivateSendHandlerProvider.unsupportedBlockchainTypes.contains(.near))
    }
}

extension NearPrivateSendSourceTests {
    static let recipient = "98793cd91a3f870fb126f66285808c7e094afcfc4eda8a970f6648cdf0dbd6de"

    static let nearToken = token(.near, decimals: 24)

    static func token(_ blockchainType: BlockchainType, decimals: Int = 8) -> Token {
        Token(
            coin: Coin(uid: blockchainType.uid, name: blockchainType.uid, code: blockchainType.uid),
            blockchain: Blockchain(type: blockchainType, name: blockchainType.uid, explorerUrl: nil),
            type: .native,
            decimals: decimals
        )
    }

    static func service() -> CrossPayService {
        CrossPayService(
            api: USwapMultiSwapApi(baseURL: URL(string: "https://example.invalid")!, apiKey: nil, networkManager: NetworkManager()),
            // never reached for a NEAR source: the refusal comes first
            assetRepository: { _ in fatalError("the asset map must not be read") },
            commitRequestBuilder: USwapCommitRequestBuilder(providerId: CrossPayService.providerId)
        )
    }
}
