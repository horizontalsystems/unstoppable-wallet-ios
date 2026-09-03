import MarketKit
import Testing
@testable import WalletCore

struct WCNSendDataTests {
    private func request(verdict: WCNVerificationVerdict, parsed: WCNParsedRequest? = nil) throws -> WCNRequest {
        try WCNRequest(parsed: parsed ?? WCNStubParsedRequest.make(), verdict: verdict, dAppName: "React App")
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
        let data = try WCNSendData(inner: inner, request: request(verdict: .pass))

        #expect(data.canSend)
        #expect(data.cautions(baseToken: WCNSendDataTests.token, currency: currency, rates: [:]).isEmpty)
        #expect(data.customSendButtonTitle == nil)
    }

    @Test func blockDisablesSendAndAddsErrorCaution() throws {
        let data = try WCNSendData(inner: StubSendData(canSend: true), request: request(verdict: .block(reason: "to != router")))

        #expect(data.canSend == false)
        let cautions = data.cautions(baseToken: WCNSendDataTests.token, currency: currency, rates: [:])
        #expect(cautions == [CautionNew(text: "to != router", type: .error)])
    }

    @Test func cautionKeepsSendAndAddsWarning() throws {
        let data = try WCNSendData(inner: StubSendData(canSend: true), request: request(verdict: .caution(reason: "origin mismatch")))

        #expect(data.canSend)
        let cautions = data.cautions(baseToken: WCNSendDataTests.token, currency: currency, rates: [:])
        #expect(cautions == [CautionNew(text: "origin mismatch", type: .warning)])
    }

    @Test func innerCannotSendStaysDisabledOnPass() throws {
        let data = try WCNSendData(inner: StubSendData(canSend: false), request: request(verdict: .pass))
        #expect(data.canSend == false)
    }

    @Test func appendsDAppSection() throws {
        let data = try WCNSendData(inner: StubSendData(canSend: true), request: request(verdict: .pass))
        let sections = data.sections(baseToken: WCNSendDataTests.token, currency: currency, rates: [:])

        #expect(sections.count == 2)
        #expect(sections[1].isMain == false)
        #expect(sections[1].fields.count == 1)
    }

    @Test func signOnlyRequestUsesSignButton() throws {
        let parsed = try WCNStubParsedRequest.make(method: "eth_signTransaction")
        parsed.stubSignOnly = true
        let data = try WCNSendData(inner: StubSendData(canSend: true), request: request(verdict: .pass, parsed: parsed))
        #expect(data.customSendButtonTitle == "button.sign".localized)
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
