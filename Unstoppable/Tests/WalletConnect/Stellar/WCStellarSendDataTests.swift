import Foundation
import stellarsdk
import Testing
@testable import WalletCore

struct WCStellarSendDataTests {
    private let currency = Currency(code: "USD", symbol: "$", decimal: 2)

    @Test func transactionXdrKeepsFullValueForCopy() throws {
        let envelope = try WCStellarFixtures.envelope()
        let data = WCStellarData(xdr: envelope.xdr, transaction: envelope.transaction, sourceAccountId: envelope.sourceAccountId)
        let copyFields = data.baseSections.flatMap(\.fields).compactMap { $0.content as? HexField }

        #expect(copyFields.count == 1)
        let field = try #require(copyFields.first)
        #expect(field.title == "send.confirmation.transaction_xdr".localized)
        #expect(field.value == envelope.xdr)
    }

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
        #expect(sections[0].fields.count == 5)
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
        #expect(sections[1].fields.count == 7)
    }

    @Test func permissionsUnknownAndTransactionErrorCautionsCoexist() throws {
        let source = try KeyPair.generateRandomKeyPair()
        let options = try SetOptionsOperation(sourceAccountId: nil, masterKeyWeight: 0)
        let unknown = ManageDataOperation(sourceAccountId: nil, name: "key")
        let transaction = try stellarsdk.Transaction(sourceAccount: stellarsdk.Account(keyPair: source, sequenceNumber: 1), operations: [options, unknown], memo: .text("memo"))
        let xdr = try transaction.encodedEnvelope()
        let sign = WCStellarSignData(xdr: xdr, transaction: transaction, sourceAccountId: source.accountId)
        let submit = WCStellarSubmitData(token: WCStellarFixtures.token, xdr: xdr, transaction: transaction, sourceAccountId: source.accountId, fee: 0.00001, transactionError: WCStellarSendHandler.TransactionError.noTrustline)

        let signCautions = sign.cautions(baseToken: WCStellarFixtures.token, currency: currency, rates: [:])
        #expect(signCautions.count == 2)
        #expect(signCautions.map(\.type) == [.error, .warning])
        #expect(sign.canSend)
        #expect(submit.canSend == false)
        #expect(submit.cautions(baseToken: WCStellarFixtures.token, currency: currency, rates: [:]).count == 3)
        let fields = sign.baseSections.flatMap(\.fields)
        #expect(fields.compactMap { $0.content as? HexField }.filter { $0.title == "send.confirmation.transaction_xdr".localized }.count == 1)
        #expect(fields.compactMap { $0.content as? SimpleValueField }.filter { $0.title.description == "send.confirmation.operation".localized }.count == 2)
    }
}
