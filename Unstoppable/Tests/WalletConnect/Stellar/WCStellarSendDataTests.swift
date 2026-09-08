import Foundation
import Testing
@testable import WalletCore

struct WCStellarSendDataTests {
    private let currency = Currency(code: "USD", symbol: "$", decimal: 2)

    @Test func submitDataWithErrorCannotSend() throws {
        let envelope = try WCStellarFixtures.envelope()
        let data = WCStellarSubmitData(
            token: WCStellarFixtures.token, xdr: envelope.xdr, transaction: envelope.transaction, sourceAccountId: envelope.sourceAccountId,
            fee: 0.00001, transactionError: WCStellarSendHandler.TransactionError.insufficientBalance(balance: 0)
        )

        #expect(data.canSend == false)
        let cautions = data.cautions(baseToken: WCStellarFixtures.token, currency: currency, rates: [:])
        #expect(cautions.count == 1)
        #expect(cautions[0].type == .error)
    }

    @Test func submitDataWithoutErrorCanSendAndShowsFee() throws {
        let envelope = try WCStellarFixtures.envelope()
        let data = WCStellarSubmitData(
            token: WCStellarFixtures.token, xdr: envelope.xdr, transaction: envelope.transaction, sourceAccountId: envelope.sourceAccountId,
            fee: 0.00001, transactionError: nil
        )

        #expect(data.canSend)
        #expect(data.cautions(baseToken: WCStellarFixtures.token, currency: currency, rates: [:]).isEmpty)
        let sections = data.sections(baseToken: WCStellarFixtures.token, currency: currency, rates: [:])
        #expect(sections.count == 2)
        #expect(sections[0].fields.count == 2)
        #expect(data.feeFields(baseToken: WCStellarFixtures.token, currency: currency, rates: [:]).count == 1)
    }

    @Test func signDataIsSignOnlyThroughWrapper() throws {
        let envelope = try WCStellarFixtures.envelope()
        let request = try WCStellarFixtures.request(method: WCStellarTransactionPayload.signMethod, params: ["xdr": envelope.xdr])
        let payload = WCStellarTransactionPayload(request: request, xdr: envelope.xdr, sourceAccountId: envelope.sourceAccountId)
        let inner = WCStellarSignData(xdr: envelope.xdr, transaction: envelope.transaction, sourceAccountId: envelope.sourceAccountId)
        let data = WCSendData(inner: inner, request: WCRequest(payload: payload, verdict: .pass, dAppName: "dApp"))

        #expect(data.canSend)
        #expect(data.customSendButtonTitle == "button.sign".localized)
        // header + one card (transaction, account, network)
        let sections = data.sections(baseToken: WCStellarFixtures.token, currency: currency, rates: [:])
        #expect(sections.count == 2)
        #expect(sections[1].isMain == false)
        #expect(sections[1].fields.count == 4)
    }
}
