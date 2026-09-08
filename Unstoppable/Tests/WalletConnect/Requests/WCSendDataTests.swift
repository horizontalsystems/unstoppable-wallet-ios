import Foundation
import MarketKit
import Testing
@testable import WalletCore

struct WCSendDataTests {
    private func request(verdict: WCVerificationVerdict, payload: WCRequestPayload? = nil) throws -> WCRequest {
        try WCRequest(payload: payload ?? WCStubRequestPayload.make(), verdict: verdict, dAppName: "React App")
    }

    private let currency = Currency(code: "USD", symbol: "$", decimal: 2)
    private static let token = Token(
        coin: Coin(uid: "ethereum", name: "Ethereum", code: "ETH"),
        blockchain: Blockchain(type: .ethereum, name: "Ethereum", explorerUrl: nil),
        type: .native,
        decimals: 18
    )

    @Test func passKeepsInnerBehaviour() throws {
        let inner = StubSendData(canSend: true)
        let data = try WCSendData(inner: inner, request: request(verdict: .pass))

        #expect(data.canSend)
        #expect(data.cautions(baseToken: WCSendDataTests.token, currency: currency, rates: [:]).isEmpty)
        #expect(data.customSendButtonTitle == nil)
    }

    @Test func blockDisablesSendAndAddsErrorCaution() throws {
        let data = try WCSendData(inner: StubSendData(canSend: true), request: request(verdict: .block(reason: .swapNotToCanonicalRouter)))

        #expect(data.canSend == false)
        let cautions = data.cautions(baseToken: WCSendDataTests.token, currency: currency, rates: [:])
        #expect(cautions == [CautionNew(text: WCVerdictReason.swapNotToCanonicalRouter.text, type: .error)])
    }

    @Test func cautionKeepsSendAndAddsWarning() throws {
        let data = try WCSendData(inner: StubSendData(canSend: true), request: request(verdict: .caution(reason: .originInvalid)))

        #expect(data.canSend)
        let cautions = data.cautions(baseToken: WCSendDataTests.token, currency: currency, rates: [:])
        #expect(cautions == [CautionNew(text: WCVerdictReason.originInvalid.text, type: .warning)])
    }

    @Test func innerCannotSendStaysDisabledOnPass() throws {
        let data = try WCSendData(inner: StubSendData(canSend: false), request: request(verdict: .pass))
        #expect(data.canSend == false)
    }

    @Test func headerThenOneCardWithNetworkRow() throws {
        let data = try WCSendData(inner: StubSendData(canSend: true), request: request(verdict: .pass))
        let sections = data.sections(baseToken: WCSendDataTests.token, currency: currency, rates: [:])

        #expect(sections.count == 2)
        #expect(sections[0].isList == false)
        #expect((sections[0].fields[0].content as? WCSendHeaderField)?.title == "wallet_connect.transaction.title".localized)
        #expect(sections[1].isMain == false)
        #expect(sections[1].fields.count == 2)
    }

    @Test func walletRowFollowsNetworkWhenAccountNamed() throws {
        let data = try WCSendData(inner: StubSendData(canSend: true), request: request(verdict: .pass), accountName: "Main")
        let sections = data.sections(baseToken: WCSendDataTests.token, currency: currency, rates: [:])

        #expect(sections[1].fields.count == 3)
    }

    @Test func headerFromHandlerOverridesTitle() throws {
        let header = WCSendHeader(title: "Token Allowance", description: "desc")
        let data = try WCSendData(inner: StubSendData(canSend: true), request: request(verdict: .pass), header: header)
        let field = data.sections(baseToken: WCSendDataTests.token, currency: currency, rates: [:])[0].fields[0].content as? WCSendHeaderField

        #expect(field?.title == "Token Allowance")
        #expect(field?.description == "desc")
    }

    @Test func signOnlyRequestUsesSignButton() throws {
        let payload = try WCStubRequestPayload.make(method: "eth_signTransaction")
        payload.stubSignOnly = true
        let data = try WCSendData(inner: StubSendData(canSend: true), request: request(verdict: .pass, payload: payload))
        #expect(data.customSendButtonTitle == "button.sign".localized)

        let field = data.sections(baseToken: WCSendDataTests.token, currency: currency, rates: [:])[0].fields[0].content as? WCSendHeaderField
        #expect(field?.title == "wallet_connect.sign.request_title".localized)
        #expect(field?.description == "wallet_connect.sign_transaction.description".localized("React App"))
    }
}

private final class StubSendData: ISendData {
    private let sendable: Bool

    init(canSend: Bool) {
        sendable = canSend
    }

    var feeData: FeeData? { nil }
    var canSend: Bool { sendable }
    var rateCoins: [Coin] { [] }

    func cautions(baseToken _: Token, currency _: Currency, rates _: [String: Decimal]) -> [CautionNew] {
        []
    }

    func sections(baseToken _: Token, currency _: Currency, rates _: [String: Decimal]) -> [SendDataSection] {
        [SendDataSection([.simpleValue(title: "Amount", value: "1 ETH")])]
    }
}
