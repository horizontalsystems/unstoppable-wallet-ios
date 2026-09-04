import Foundation
import Testing
@testable import WalletCore

struct WCNStellarSendDataTests {
    private let currency = Currency(code: "USD", symbol: "$", decimal: 2)

    @Test func submitDataWithErrorCannotSend() throws {
        let envelope = try WCNStellarFixtures.envelope()
        let data = WCNStellarSubmitData(
            token: WCNStellarFixtures.token, xdr: envelope.xdr, transaction: envelope.transaction, sourceAccountId: envelope.sourceAccountId,
            fee: 0.00001, transactionError: WCNStellarSendHandler.TransactionError.insufficientBalance(balance: 0)
        )

        #expect(data.canSend == false)
        let cautions = data.cautions(baseToken: WCNStellarFixtures.token, currency: currency, rates: [:])
        #expect(cautions.count == 1)
        #expect(cautions[0].type == .error)
    }

    @Test func submitDataWithoutErrorCanSendAndShowsFee() throws {
        let envelope = try WCNStellarFixtures.envelope()
        let data = WCNStellarSubmitData(
            token: WCNStellarFixtures.token, xdr: envelope.xdr, transaction: envelope.transaction, sourceAccountId: envelope.sourceAccountId,
            fee: 0.00001, transactionError: nil
        )

        #expect(data.canSend)
        #expect(data.cautions(baseToken: WCNStellarFixtures.token, currency: currency, rates: [:]).isEmpty)
        let sections = data.sections(baseToken: WCNStellarFixtures.token, currency: currency, rates: [:])
        #expect(sections.count == 3)
        #expect(sections[0].fields.count == 2)
    }

    @Test func signDataIsSignOnlyThroughWrapper() throws {
        let envelope = try WCNStellarFixtures.envelope()
        let request = try WCNStellarFixtures.request(method: WCNStellarTransactionPayload.signMethod, params: ["xdr": envelope.xdr])
        let payload = WCNStellarTransactionPayload(request: request, xdr: envelope.xdr, sourceAccountId: envelope.sourceAccountId)
        let inner = WCNStellarSignData(xdr: envelope.xdr, transaction: envelope.transaction, sourceAccountId: envelope.sourceAccountId)
        let data = WCNSendData(inner: inner, request: WCNRequest(payload: payload, verdict: .pass, dAppName: "dApp"))

        #expect(data.canSend)
        #expect(data.customSendButtonTitle == "button.sign".localized)
        // transaction + account + dApp + sign-only note
        let sections = data.sections(baseToken: WCNStellarFixtures.token, currency: currency, rates: [:])
        #expect(sections.count == 4)
        #expect(sections[3].isMain == false)
    }
}
