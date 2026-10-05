import Foundation
import MarketKit
import StellarKit
import Testing
@testable import WalletCore

// Android parity (StellarContractMovementTest): a contract call's balance changes, netted per
// asset, render as a swap, a plain send or a plain receive; anything else stays unsupported.
struct StellarOperationConverterTests {
    private static let own = "GOWNACCOUNT"
    private static let other = "GOTHERACCOUNT"
    private static let contract = "CCONTRACT"
    private static let usdc: [String: Any] = ["asset": ["code": "USDC", "issuer": "GUSDCISSUER"]]
    private static let eurc: [String: Any] = ["asset": ["code": "EURC", "issuer": "GEURCISSUER"]]
    private static let xlm: [String: Any] = ["native": [String: Any]()]

    @Test func soldOneAssetReceivedAnotherIsSwap() throws {
        let type = try convert([
            change(from: Self.own, to: Self.contract, asset: Self.xlm, amount: 10),
            change(from: Self.contract, to: Self.own, asset: Self.usdc, amount: 3),
        ])

        guard case let .swap(valueIn, valueOut) = type else {
            Issue.record("expected swap, got \(type)")
            return
        }
        #expect(valueIn.code == "XLM" && valueIn.value == -10)
        #expect(valueOut.code == "USDC" && valueOut.value == 3)
    }

    @Test func repeatedMovementsOfOneAssetAreSummed() throws {
        let type = try convert([
            change(from: Self.own, to: Self.contract, asset: Self.xlm, amount: 3),
            change(from: Self.own, to: Self.other, asset: Self.xlm, amount: 2),
            change(from: Self.contract, to: Self.own, asset: Self.usdc, amount: 1),
        ])

        guard case let .swap(valueIn, _) = type else {
            Issue.record("expected swap, got \(type)")
            return
        }
        #expect(valueIn.value == -5)
    }

    @Test func assetOnBothSidesIsNetted() throws {
        let type = try convert([
            change(from: Self.own, to: Self.contract, asset: Self.xlm, amount: 5),
            change(from: Self.contract, to: Self.own, asset: Self.xlm, amount: 1),
            change(from: Self.contract, to: Self.own, asset: Self.usdc, amount: 2),
        ])

        guard case let .swap(valueIn, _) = type else {
            Issue.record("expected swap, got \(type)")
            return
        }
        #expect(valueIn.value == -4)
    }

    @Test func severalAssetsInOneDirectionStayUnsupported() throws {
        let type = try convert([
            change(from: Self.own, to: Self.contract, asset: Self.xlm, amount: 1),
            change(from: Self.own, to: Self.contract, asset: Self.usdc, amount: 1),
        ])

        guard case let .unsupported(function) = type else {
            Issue.record("expected unsupported, got \(type)")
            return
        }
        #expect(function == "InvokeContract")
    }

    @Test func oneDirectionalOutgoingMovementIsSend() throws {
        let type = try convert([change(from: Self.own, to: Self.contract, asset: Self.usdc, amount: 7)])

        guard case let .sendPayment(value, to, sentToSelf) = type else {
            Issue.record("expected send, got \(type)")
            return
        }
        #expect(value.code == "USDC" && value.value == -7)
        #expect(to == Self.contract)
        #expect(!sentToSelf)
    }

    // A transfer to the issuer is reported as a burn with no recipient
    @Test func burnIsSendToEmptyRecipient() throws {
        let type = try convert([change(type: "burn", from: Self.own, to: nil, asset: Self.usdc, amount: 2)])

        guard case let .sendPayment(value, to, _) = type else {
            Issue.record("expected send, got \(type)")
            return
        }
        #expect(value.value == -2)
        #expect(to == "")
    }

    @Test func mintIsReceiveFromEmptySender() throws {
        let type = try convert([change(type: "mint", from: nil, to: Self.own, asset: Self.usdc, amount: 4)])

        guard case let .receivePayment(value, from) = type else {
            Issue.record("expected receive, got \(type)")
            return
        }
        #expect(value.value == 4)
        #expect(from == "")
    }

    @Test func changesNotTouchingTheAccountStayUnsupported() throws {
        let foreign = try convert([change(from: Self.other, to: Self.contract, asset: Self.xlm, amount: 1)])
        let empty = try convert([])

        guard case .unsupported = foreign, case .unsupported = empty else {
            Issue.record("expected unsupported, got \(foreign) / \(empty)")
            return
        }
    }

    // The counterparty is the one of the moved asset, not of the first change
    @Test func counterpartyIsTakenPerAsset() throws {
        let type = try convert([
            change(from: Self.contract, to: Self.own, asset: Self.eurc, amount: 1),
            change(from: Self.own, to: Self.contract, asset: Self.eurc, amount: 1),
            change(from: Self.other, to: Self.own, asset: Self.usdc, amount: 5),
        ])

        guard case let .receivePayment(value, from) = type else {
            Issue.record("expected receive, got \(type)")
            return
        }
        #expect(value.code == "USDC")
        #expect(from == Self.other)
    }

    // As on Android, the first matching change decides even when it carries no counterparty
    @Test func counterpartyOfFirstMatchingChangeIsKeptWhenEmpty() throws {
        let type = try convert([
            change(type: "mint", from: nil, to: Self.own, asset: Self.usdc, amount: 2),
            change(from: Self.other, to: Self.own, asset: Self.usdc, amount: 3),
        ])

        guard case let .receivePayment(value, from) = type else {
            Issue.record("expected receive, got \(type)")
            return
        }
        #expect(value.value == 5)
        #expect(from == "")
    }

    // MARK: - spam correlation context

    @Test func contractSendIsOwnButGivesNoCorrelationContext() throws {
        let record = try record(invoke: [change(from: Self.own, to: Self.contract, asset: Self.usdc, amount: 7)])

        #expect(OutputTransactionFactory.outgoingAddresses(from: record) == [])
        #expect(OutputTransactionFactory().cachedOutputs(from: record).isEmpty)
    }

    @Test func contractReceiveGivesNoCorrelationContext() throws {
        let record = try record(invoke: [change(from: Self.other, to: Self.own, asset: Self.usdc, amount: 5)])

        #expect(OutputTransactionFactory.outgoingAddresses(from: record) == nil)
        #expect(OutputTransactionFactory.counterpartyAddresses(from: record) == [])
        #expect(OutputTransactionFactory().cachedOutputs(from: record).isEmpty)
    }

    @Test func classicPaymentKeepsCorrelationContext() throws {
        let sent = try record(type: ["payment": ["data": ["amount": 1, "asset": Self.xlm, "from": Self.own, "to": Self.other]]])
        let received = try record(type: ["payment": ["data": ["amount": 1, "asset": Self.xlm, "from": Self.other, "to": Self.own]]])

        #expect(OutputTransactionFactory.outgoingAddresses(from: sent) == [Self.other])
        #expect(OutputTransactionFactory.counterpartyAddresses(from: received) == [Self.other])
    }
}

extension StellarOperationConverterTests {
    private func convert(_ changes: [[String: Any]]) throws -> StellarTransactionRecord.`Type` {
        try record(invoke: changes).type
    }

    private func record(invoke changes: [[String: Any]]) throws -> StellarTransactionRecord {
        try record(type: ["invokeHostFunction": ["data": ["function": "InvokeContract", "balanceChanges": changes]]])
    }

    private func record(type: [String: Any]) throws -> StellarTransactionRecord {
        let json: [String: Any] = [
            "id": "1",
            "createdAt": 0,
            "pagingToken": "1",
            "sourceAccount": Self.own,
            "transactionHash": String(repeating: "a", count: 64),
            "transactionSuccessful": true,
            "type": type,
        ]
        let operation = try JSONDecoder().decode(TxOperation.self, from: JSONSerialization.data(withJSONObject: json))

        let converter = StellarOperationConverter(
            accountId: Self.own,
            source: TransactionSource(blockchainType: .stellar, meta: nil),
            baseToken: Self.baseToken,
            coinManager: StubCoinManager(tokens: [TokenQuery(blockchainType: .stellar, tokenType: .native): Self.baseToken])
        )

        return try #require(converter.transactionRecord(operations: [operation]))
    }

    private func change(type: String = "transfer", from: String?, to: String?, asset: [String: Any], amount: Decimal) -> [String: Any] {
        var change: [String: Any] = ["type": type, "asset": asset, "amount": amount]
        change["from"] = from
        change["to"] = to
        return change
    }

    private static let baseToken = Token(
        coin: Coin(uid: "stellar", name: "Stellar", code: "XLM"),
        blockchain: Blockchain(type: .stellar, name: "Stellar", explorerUrl: nil),
        type: .native,
        decimals: 7
    )
}

private struct StubCoinManager: ICoinManager {
    let tokens: [TokenQuery: Token]

    func token(query: TokenQuery) throws -> Token? {
        tokens[query]
    }
}
