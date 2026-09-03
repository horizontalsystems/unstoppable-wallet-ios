import Foundation
import MarketKit
import stellarsdk
import WalletConnectSign
import WalletConnectUtils
@testable import WalletCore

enum WCNStellarFixtures {
    static let token = Token(
        coin: Coin(uid: "stellar", name: "Stellar", code: "XLM"),
        blockchain: MarketKit.Blockchain(type: .stellar, name: "Stellar", explorerUrl: nil),
        type: .native,
        decimals: 7
    )

    // a one-payment envelope built with stellarsdk; returns the XDR and its source account id
    static func envelope() throws -> (xdr: String, sourceAccountId: String, transaction: stellarsdk.Transaction) {
        let source = try KeyPair.generateRandomKeyPair()
        let destination = try KeyPair.generateRandomKeyPair()
        guard let asset = Asset(type: AssetType.ASSET_TYPE_NATIVE) else {
            throw FixtureError.invalidAsset
        }
        let payment = try PaymentOperation(sourceAccountId: nil, destinationAccountId: destination.accountId, asset: asset, amount: 1)
        let transaction = try stellarsdk.Transaction(sourceAccount: stellarsdk.Account(keyPair: source, sequenceNumber: 1), operations: [payment], memo: Memo.none)
        return (try transaction.encodedEnvelope(), source.accountId, transaction)
    }

    static func request(method: String = WCNStellarTransactionParsed.submitMethod, chainId: String = "stellar:pubnet", params: [String: String]) throws -> Request {
        guard let blockchain = WalletConnectUtils.Blockchain(chainId) else {
            throw FixtureError.invalidChain
        }
        return try Request(topic: WCNTestFixtures.topic, method: method, params: AnyCodable(params), chainId: blockchain)
    }

    enum FixtureError: Error {
        case invalidAsset
        case invalidChain
    }
}
