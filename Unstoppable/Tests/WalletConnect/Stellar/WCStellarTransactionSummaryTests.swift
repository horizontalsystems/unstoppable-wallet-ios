import Foundation
import stellarsdk
import Testing
@testable import WalletCore

struct WCStellarTransactionSummaryTests {
    @Test func paymentDisclosesAmountIssuerDestinationAndEffectiveSource() throws {
        let source = try KeyPair.generateRandomKeyPair()
        let destination = try KeyPair.generateRandomKeyPair()
        let issuer = try KeyPair.generateRandomKeyPair()
        let asset = try #require(Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "USD", issuer: issuer))
        let amount = try #require(Decimal(string: "1.0000001"))
        let payment = try PaymentOperation(sourceAccountId: source.accountId, destinationAccountId: destination.accountId, asset: asset, amount: amount)
        let summary = try summary(operations: [payment], memo: .id(0))
        let fields = try #require(summary.operations.first).fields

        #expect(value("send.confirmation.to", in: fields) == destination.accountId)
        #expect(value("wallet_connect.stellar.amount", in: fields) == "1.0000001 USD")
        #expect(value("wallet_connect.stellar.issuer", in: fields) == issuer.accountId)
        #expect(value("wallet_connect.stellar.source", in: fields) == source.accountId)
        #expect(value("wallet_connect.stellar.memo_id", in: summary.memoFields) == "0")
        #expect(summary.warnings.isEmpty)
    }

    @Test func pathPaymentsUseDifferentBoundsDespiteSharedSdkPropertyNames() throws {
        let asset = try #require(Asset(type: AssetType.ASSET_TYPE_NATIVE))
        let destination = try KeyPair.generateRandomKeyPair().accountId
        let send = try PathPaymentStrictSendOperation(sourceAccountId: nil, sendAsset: asset, sendMax: 5, destinationAccountId: destination, destAsset: asset, destAmount: 4, path: [])
        let receive = try PathPaymentStrictReceiveOperation(sourceAccountId: nil, sendAsset: asset, sendMax: 5, destinationAccountId: destination, destAsset: asset, destAmount: 4, path: [])
        let summary = try summary(operations: [send, receive])

        #expect(value("wallet_connect.stellar.send_amount", in: summary.operations[0].fields) == "5 XLM")
        #expect(value("wallet_connect.stellar.receive_min", in: summary.operations[0].fields) == "4 XLM")
        #expect(value("wallet_connect.stellar.send_max", in: summary.operations[1].fields) == "5 XLM")
        #expect(value("wallet_connect.stellar.receive_amount", in: summary.operations[1].fields) == "4 XLM")
    }

    @Test func offersKeepBothIssuersAndBuySellDirection() throws {
        let issuerA = try KeyPair.generateRandomKeyPair()
        let issuerB = try KeyPair.generateRandomKeyPair()
        let selling = try #require(Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "USD", issuer: issuerA))
        let buying = try #require(Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "USD", issuer: issuerB))
        let buy = ManageBuyOfferOperation(sourceAccountId: nil, selling: selling, buying: buying, amount: 2, price: Price(numerator: 3, denominator: 2), offerId: 7)
        let sell = ManageSellOfferOperation(sourceAccountId: nil, selling: selling, buying: buying, amount: 0, price: Price(numerator: 3, denominator: 2), offerId: 7)
        let summary = try summary(operations: [buy, sell])

        for operation in summary.operations {
            #expect(value("wallet_connect.stellar.selling_issuer", in: operation.fields) == issuerA.accountId)
            #expect(value("wallet_connect.stellar.buying_issuer", in: operation.fields) == issuerB.accountId)
            #expect(value("wallet_connect.stellar.offer_id", in: operation.fields) == "7")
        }
        #expect(value("wallet_connect.stellar.buy_amount", in: summary.operations[0].fields) == "2 USD")
        #expect(value("wallet_connect.stellar.sell_amount", in: summary.operations[1].fields) == "0 USD")
        #expect(value("wallet_connect.stellar.buy_price", in: summary.operations[0].fields) == "3/2")
        #expect(value("wallet_connect.stellar.sell_price", in: summary.operations[1].fields) == "3/2")
    }

    @Test func setOptionsKeepsZeroValuesAndUnknownWarning() throws {
        let signer = try KeyPair.generateRandomKeyPair()
        let options = try SetOptionsOperation(sourceAccountId: nil, clearFlags: 0, setFlags: 0, masterKeyWeight: 0, lowThreshold: 0, mediumThreshold: 0, highThreshold: 0, homeDomain: "", signer: .ed25519(WrappedData32(Data(signer.publicKey.bytes))), signerWeight: 0)
        let unknown = ManageDataOperation(sourceAccountId: nil, name: "key", data: Data([1]))
        let summary = try summary(operations: [options, unknown])
        let fields = summary.operations[0].fields

        for key in ["clear_flags", "set_flags", "master_weight", "low_threshold", "medium_threshold", "high_threshold", "signer_weight"] {
            #expect(value("wallet_connect.stellar.\(key)", in: fields) == "0")
        }
        #expect(value("wallet_connect.stellar.home_domain", in: fields) == "\"\"")
        #expect(value("wallet_connect.stellar.signer", in: fields) == signer.accountId)
        #expect(summary.warnings == [.accountPermissions, .unknownOperations])
    }

    @Test func nonAddressSignerKindsAndMemoHashesKeepFullBytes() throws {
        let bytes = Data(repeating: 0xAB, count: 32)
        let options = try SetOptionsOperation(sourceAccountId: nil, signer: .hashX(WrappedData32(bytes)), signerWeight: 1)
        let summary = try summary(operations: [options], memo: .returnHash(bytes))

        #expect(value("wallet_connect.stellar.signer_type", in: summary.operations[0].fields) == "Hash X")
        #expect(value("wallet_connect.stellar.signer", in: summary.operations[0].fields) == String(repeating: "ab", count: 32))
        #expect(value("wallet_connect.stellar.memo_return_hash", in: summary.memoFields) == String(repeating: "ab", count: 32))
    }

    @Test func createAndMergeDiscloseDestinationWithoutInventingMergeAmount() throws {
        let destination = try KeyPair.generateRandomKeyPair()
        let create = CreateAccountOperation(sourceAccountId: nil, destination: destination, startBalance: 3)
        let merge = try AccountMergeOperation(destinationAccountId: destination.accountId, sourceAccountId: nil)
        let summary = try summary(operations: [create, merge])

        #expect(value("wallet_connect.stellar.amount", in: summary.operations[0].fields) == "3 XLM")
        #expect(value("send.confirmation.to", in: summary.operations[1].fields) == destination.accountId)
        #expect(value("wallet_connect.stellar.amount", in: summary.operations[1].fields) == nil)
    }

    @Test func inheritedMuxedSourceRetainsId() throws {
        let source = try MuxedAccount(accountId: KeyPair.generateRandomKeyPair().accountId, sequenceNumber: 1, id: 42)
        let operation = ManageDataOperation(sourceAccountId: nil, name: "key")
        let transaction = try stellarsdk.Transaction(sourceAccount: source, operations: [operation], memo: Memo.none)
        let decoded = try stellarsdk.Transaction(envelopeXdr: transaction.encodedEnvelope())
        let summary = WCStellarTransactionSummary(transaction: decoded)

        #expect(value("wallet_connect.stellar.source", in: summary.operations[0].fields) == source.accountId)
        #expect(source.accountId.hasPrefix("M"))
    }

    @Test func signedPayloadSignerKeepsKeyAndPayload() throws {
        let signer = try KeyPair.generateRandomKeyPair()
        let key = Ed25519SignedPayload(ed25519: WrappedData32(Data(signer.publicKey.bytes)), payload: Data([0, 1, 255]))
        let operation = try SetOptionsOperation(sourceAccountId: nil, signer: .signedPayload(key), signerWeight: 1)
        let summary = try summary(operations: [operation])

        #expect(value("wallet_connect.stellar.signer", in: summary.operations[0].fields) == signer.accountId)
        #expect(value("wallet_connect.stellar.signer_payload", in: summary.operations[0].fields) == "0001ff")
    }

    @Test func trustlineKeepsZeroLimitAndPoolSharesRemainIncomplete() throws {
        let issuer = try KeyPair.generateRandomKeyPair()
        let asset = try #require(ChangeTrustAsset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: "USD", issuer: issuer))
        let native = try #require(Asset(type: AssetType.ASSET_TYPE_NATIVE))
        let pool = try #require(try ChangeTrustAsset(assetA: native, assetB: asset))
        let summary = try summary(operations: [ChangeTrustOperation(sourceAccountId: nil, asset: asset, limit: 0), ChangeTrustOperation(sourceAccountId: nil, asset: pool)])

        #expect(value("wallet_connect.stellar.limit", in: summary.operations[0].fields) == "0")
        #expect(value("wallet_connect.stellar.issuer", in: summary.operations[0].fields) == issuer.accountId)
        #expect(summary.warnings == [.unknownOperations])
    }

    private func summary(operations: [stellarsdk.Operation], memo: Memo = .none) throws -> WCStellarTransactionSummary {
        let source = try KeyPair.generateRandomKeyPair()
        let transaction = try stellarsdk.Transaction(sourceAccount: stellarsdk.Account(keyPair: source, sequenceNumber: 1), operations: operations, memo: memo)
        // Exercise the same SDK decoding boundary as a real WalletConnect request.
        let decoded = try stellarsdk.Transaction(envelopeXdr: transaction.encodedEnvelope())
        return WCStellarTransactionSummary(transaction: decoded)
    }

    private func value(_ titleKey: String, in fields: [WCStellarTransactionSummary.Field]) -> String? {
        fields.first { $0.titleKey == titleKey }?.value
    }
}
