import Foundation
import GRDB
import MarketKit
import NearKit
import Testing
@testable import WalletCore

// Android `NearTransactionConverter`: the net change of each asset across the transaction. One asset
// moving is a send or a receive, several are a contract call listing each; NEAR paid into a call is a
// contract call; the fee is the account's only when it signed. An expired transaction is failed and
// "not processed".
struct NearTransactionConverterTests {
    @Test func signedTransferIsASend() async throws {
        let record = try await Self.record(
            signer: Self.own, receiver: Self.other,
            actions: [Self.transfer(Self.oneNear)],
            nearTransfers: [Self.nearTransfer(from: Self.own, to: Self.other, amount: Self.oneNear)],
            fee: "44636512500000000000"
        )

        guard case let .send(value, to, sentToSelf, memo) = record.type else {
            Issue.record("expected a send, got \(record.type)")
            return
        }
        #expect(value.value == -1)
        #expect(value.token == Self.nearToken)
        #expect(to == Self.other)
        #expect(!sentToSelf)
        #expect(memo == nil)
        #expect(record.fee?.value == Decimal(string: "0.0000446365125")!)
        #expect(record.status(lastBlockHeight: nil) == .completed)
    }

    @Test func transferToSelfIsSentToSelf() async throws {
        let record = try await Self.record(signer: Self.own, receiver: Self.own, actions: [Self.transfer(Self.oneNear)])

        guard case let .send(_, _, sentToSelf, _) = record.type else {
            Issue.record("expected a send, got \(record.type)")
            return
        }
        #expect(sentToSelf)
    }

    @Test func incomingNearIsAReceiveWithoutFee() async throws {
        let record = try await Self.record(
            signer: Self.other, receiver: Self.own,
            actions: [Self.transfer(Self.oneNear)],
            nearTransfers: [Self.nearTransfer(from: Self.other, to: Self.own, amount: Self.oneNear)],
            fee: "44636512500000000000"
        )

        guard case let .receive(value, from, _) = record.type else {
            Issue.record("expected a receive, got \(record.type)")
            return
        }
        #expect(value.value == 1)
        #expect(from == Self.other)
        // someone else signed it, so someone else paid the gas
        #expect(record.fee == nil)
        #expect(record.transferEvents.incoming.count == 1)
    }

    @Test func outgoingTokenTransferIsATokenSendWithMemo() async throws {
        let record = try await Self.record(
            signer: Self.own, receiver: Self.usdtContract,
            actions: [Self.functionCall("ft_transfer", deposit: "1")],
            nearTransfers: [Self.nearTransfer(from: Self.own, to: Self.usdtContract, amount: "1", kind: "FunctionCallDeposit")],
            ftTransfers: [Self.ftTransfer(from: Self.own, to: Self.other, amount: "2500000", memo: "order-42")],
            knownTokens: [Self.usdtToken]
        )

        guard case let .send(value, to, _, memo) = record.type else {
            Issue.record("expected a send, got \(record.type)")
            return
        }
        #expect(value.token == Self.usdtToken)
        #expect(value.value == Decimal(string: "-2.5")!)
        #expect(to == Self.other)
        #expect(memo == "order-42")
        // what the account signed stays out of the phishing check
        #expect(record.transferEvents.incoming.isEmpty)
    }

    @Test func unknownTokenIsScaledByItsMetadata() async throws {
        let record = try await Self.record(
            signer: Self.other, receiver: Self.usdtContract,
            actions: [Self.functionCall("ft_transfer", deposit: "1")],
            ftTransfers: [Self.ftTransfer(from: Self.other, to: Self.own, amount: "2500000", memo: nil)],
            metadata: try Self.metadata(symbol: "USDt", decimals: 6)
        )

        guard case let .receive(value, from, _) = record.type else {
            Issue.record("expected a receive, got \(record.type)")
            return
        }
        #expect(value.value == Decimal(string: "2.5")!)
        #expect(value.code == "USDt")
        #expect(from == Self.other)
    }

    @Test func unreadableTokenShowsTheRawAmount() async throws {
        let record = try await Self.record(
            signer: Self.other, receiver: Self.usdtContract,
            actions: [Self.functionCall("ft_transfer", deposit: "1")],
            ftTransfers: [Self.ftTransfer(from: Self.other, to: Self.own, amount: "2500000", memo: nil)]
        )

        #expect(record.mainValue?.value == 2_500_000)
        #expect(record.mainValue?.code == Self.usdtContract)
    }

    // the spam scan at adapter creation: no contract read per unknown token ahead of the first page
    @Test func spamScanRecordSkipsTokenMetadata() async throws {
        let metadataRequests = MetadataRequests()
        let record = try await Self.record(
            signer: Self.other, receiver: Self.usdtContract,
            actions: [Self.functionCall("ft_transfer", deposit: "1")],
            ftTransfers: [Self.ftTransfer(from: Self.other, to: Self.own, amount: "2500000", memo: nil)],
            metadata: try Self.metadata(symbol: "USDt", decimals: 6),
            metadataRequests: metadataRequests,
            resolvesUnknownMetadata: false
        )

        #expect(metadataRequests.count == 0)
        guard case let .receive(value, _, _) = record.type, case .unknownToken = value.kind else {
            Issue.record("expected an unknown token receive, got \(record.type)")
            return
        }
        #expect(value.code == Self.usdtContract)
    }

    @Test func displayedRecordReadsTokenMetadata() async throws {
        let metadataRequests = MetadataRequests()
        _ = try await Self.record(
            signer: Self.other, receiver: Self.usdtContract,
            actions: [Self.functionCall("ft_transfer", deposit: "1")],
            ftTransfers: [Self.ftTransfer(from: Self.other, to: Self.own, amount: "2500000", memo: nil)],
            metadata: try Self.metadata(symbol: "USDt", decimals: 6),
            metadataRequests: metadataRequests
        )

        #expect(metadataRequests.count == 1)
    }

    @Test func otherSignedActionIsAContractCall() async throws {
        let record = try await Self.record(
            signer: Self.own, receiver: "wrap.near",
            actions: [Self.functionCall("near_deposit", deposit: Self.oneNear)],
            nearTransfers: [Self.nearTransfer(from: Self.own, to: "wrap.near", amount: Self.oneNear, kind: "FunctionCallDeposit")],
            fee: "44636512500000000000"
        )

        guard case let .contractCall(contractId, method, incoming, outgoing) = record.type else {
            Issue.record("expected a contract call, got \(record.type)")
            return
        }
        #expect(contractId == "wrap.near")
        #expect(method == "near_deposit")
        #expect(incoming.isEmpty)
        #expect(outgoing.map(\.value.value) == [-1])
        #expect(outgoing.first?.address == "wrap.near")
        #expect(record.mainValue?.value == -1)
        #expect(record.fee != nil)
    }

    // a wrap moves two assets: one contract call listing both, in both histories
    @Test func wrapShowsBothLegs() async throws {
        let record = try await Self.record(
            signer: Self.own, receiver: Self.usdtContract,
            actions: [Self.functionCall("near_deposit", deposit: Self.oneNear)],
            nearTransfers: [Self.nearTransfer(from: Self.own, to: Self.usdtContract, amount: Self.oneNear, kind: "FunctionCallDeposit", methodName: "near_deposit")],
            ftTransfers: [Self.ftTransfer(from: nil, to: Self.own, amount: "1000000", memo: nil)],
            knownTokens: [Self.usdtToken]
        )

        guard case let .contractCall(_, _, incoming, outgoing) = record.type else {
            Issue.record("expected a contract call, got \(record.type)")
            return
        }
        #expect(incoming.map(\.value.value) == [1])
        #expect(incoming.first?.value.token == Self.usdtToken)
        // a mint: the contract is the other side
        #expect(incoming.first?.address == Self.usdtContract)
        #expect(outgoing.map(\.value.value) == [-1])
        #expect(record.mainValue == nil)
        // what the account signed itself is not checked for phishing
        #expect(record.transferEvents.incoming.isEmpty)
    }

    // the receiver's registration and the 1 yocto proof belong to the token send, net of the refund
    @Test func registrationNextToATokenSendIsNotANearMovement() async throws {
        let record = try await Self.record(
            signer: Self.own, receiver: Self.usdtContract,
            actions: [Self.functionCall("storage_deposit", deposit: "1250000000000000000000"), Self.functionCall("ft_transfer", deposit: "1")],
            nearTransfers: [
                Self.nearTransfer(from: Self.own, to: Self.usdtContract, amount: "1250000000000000000000", kind: "FunctionCallDeposit", methodName: "storage_deposit"),
                Self.nearTransfer(from: Self.own, to: Self.usdtContract, amount: "1", kind: "FunctionCallDeposit", methodName: "ft_transfer"),
                Self.nearTransfer(from: Self.usdtContract, to: Self.own, amount: "1250000000000000000000"),
            ],
            ftTransfers: [Self.ftTransfer(from: Self.own, to: Self.other, amount: "2500000", memo: nil)],
            knownTokens: [Self.usdtToken]
        )

        guard case let .send(value, to, _, _) = record.type else {
            Issue.record("expected a token send, got \(record.type)")
            return
        }
        #expect(value.token == Self.usdtToken)
        #expect(to == Self.other)
    }

    // someone else's call that paid the account in two assets is checked for phishing
    @Test func unsignedContractCallIncomingIsCheckedForPhishing() async throws {
        let record = try await Self.record(
            signer: Self.other, receiver: Self.usdtContract,
            actions: [Self.functionCall("payout", deposit: "0")],
            nearTransfers: [Self.nearTransfer(from: Self.usdtContract, to: Self.own, amount: Self.oneNear)],
            ftTransfers: [Self.ftTransfer(from: Self.other, to: Self.own, amount: "2500000", memo: nil)],
            knownTokens: [Self.usdtToken]
        )

        guard case let .contractCall(_, _, incoming, outgoing) = record.type else {
            Issue.record("expected a contract call, got \(record.type)")
            return
        }
        #expect(incoming.count == 2)
        #expect(outgoing.isEmpty)
        #expect(record.transferEvents.incoming.count == 2)
    }

    @Test func signedActionWithoutMethodIsNamedByItsType() async throws {
        let record = try await Self.record(signer: Self.own, receiver: Self.own, actions: [TxActionJson(type: "AddKey")])

        guard case let .contractCall(_, method, incoming, outgoing) = record.type else {
            Issue.record("expected a contract call, got \(record.type)")
            return
        }
        #expect(method == "AddKey")
        #expect(incoming.isEmpty && outgoing.isEmpty)
        #expect(record.mainValue == nil)
    }

    @Test func failedTransactionIsFailed() async throws {
        let record = try await Self.record(signer: Self.own, receiver: Self.other, actions: [Self.transfer(Self.oneNear)], status: "Failed", failure: #"{"ActionError":{}}"#)

        #expect(record.status(lastBlockHeight: nil) == .failed)
        #expect(!record.expired)
    }

    // never included before its block hash expired: nothing happened on chain (Android `notProcessed`)
    @Test func expiredTransactionIsNotProcessed() async throws {
        let record = try await Self.record(signer: Self.own, receiver: Self.other, actions: [Self.transfer(Self.oneNear)], status: "Failed", failure: "expired")

        #expect(record.status(lastBlockHeight: nil) == .failed)
        #expect(record.expired)
    }

    @Test func pendingTransactionIsPending() async throws {
        let record = try await Self.record(signer: Self.own, receiver: Self.other, actions: [Self.transfer(Self.oneNear)], status: "Pending")

        #expect(record.status(lastBlockHeight: 100) == .pending)
    }
}

extension NearTransactionConverterTests {
    static let own = "98793cd91a3f870fb126f66285808c7e094afcfc4eda8a970f6648cdf0dbd6de"
    static let other = "alice.near"
    static let usdtContract = "usdt.tether-token.near"
    static let oneNear = "1000000000000000000000000"

    static let nearToken = Token(
        coin: Coin(uid: "near", name: "NEAR Protocol", code: "NEAR"),
        blockchain: Blockchain(type: .near, name: "Near Protocol", explorerUrl: nil),
        type: .native,
        decimals: 24
    )

    static let usdtToken = Token(
        coin: Coin(uid: "tether", name: "Tether", code: "USDT"),
        blockchain: Blockchain(type: .near, name: "Near Protocol", explorerUrl: nil),
        type: .nep141(contractId: usdtContract),
        decimals: 6
    )

    struct TxActionJson: Encodable {
        let type: String
        var deposit: String?
        var methodName: String?
    }

    struct NearTransferJson: Encodable {
        let from: String
        let to: String
        let amount: String
        let kind: String
        let success: Bool
        var methodName: String?
    }

    struct FtTransferJson: Encodable {
        let contractId: String
        let from: String?
        let to: String?
        let amount: String
        let memo: String?
    }

    static func transfer(_ deposit: String) -> TxActionJson {
        TxActionJson(type: "Transfer", deposit: deposit)
    }

    static func functionCall(_ method: String, deposit: String) -> TxActionJson {
        TxActionJson(type: "FunctionCall", deposit: deposit, methodName: method)
    }

    static func nearTransfer(from: String, to: String, amount: String, kind: String = "Transfer", methodName: String? = nil) -> NearTransferJson {
        NearTransferJson(from: from, to: to, amount: amount, kind: kind, success: true, methodName: methodName)
    }

    static func ftTransfer(from: String?, to: String?, amount: String, memo: String?) -> FtTransferJson {
        FtTransferJson(contractId: usdtContract, from: from, to: to, amount: amount, memo: memo)
    }

    static func json(_ value: some Encodable) throws -> String {
        try String(decoding: JSONEncoder().encode(value), as: UTF8.self)
    }

    static func metadata(symbol: String, decimals: Int) throws -> FtMetadata {
        let values: [String: (any DatabaseValueConvertible)?] = ["contractId": usdtContract, "name": "Tether USD", "symbol": symbol, "decimals": decimals, "spec": "ft-1.0.0"]
        return try FtMetadata(row: Row(values))
    }

    enum StubError: Error {
        case unreadable
    }

    final class MetadataRequests {
        var count = 0
    }

    static func record(
        signer: String,
        receiver: String,
        actions: [TxActionJson],
        nearTransfers: [NearTransferJson] = [],
        ftTransfers: [FtTransferJson] = [],
        fee: String? = nil,
        status: String = "Success",
        failure: String? = nil,
        knownTokens: [Token] = [],
        metadata: FtMetadata? = nil,
        metadataRequests: MetadataRequests? = nil,
        resolvesUnknownMetadata: Bool = true
    ) async throws -> NearTransactionRecord {
        let values: [String: (any DatabaseValueConvertible)?] = try [
            "hash": "6zgh2u9DqHHiXzdy9ouTP7oGky2T4nugqzqt9wJZwNFm",
            "blockHeight": status == "Pending" ? nil : 150_000_000,
            "timestamp": 1_790_000_000,
            "signerId": signer,
            "receiverId": receiver,
            "actions": json(actions),
            "nearTransfers": json(nearTransfers),
            "ftTransfers": json(ftTransfers),
            "fee": fee,
            "status": status,
            "failure": failure,
            "expiresAfterHeight": nil,
        ]
        let transaction = try NearKit.Transaction(row: Row(values))

        var tokens = [TokenQuery(blockchainType: .near, tokenType: .native): nearToken]
        for token in knownTokens {
            tokens[token.tokenQuery] = token
        }

        let converter = NearTransactionConverter(
            accountId: own,
            source: TransactionSource(blockchainType: .near, meta: nil),
            baseToken: nearToken,
            coinManager: StubCoinManager(tokens: tokens),
            ftMetadata: { _ in
                metadataRequests?.count += 1
                guard let metadata else { throw StubError.unreadable }
                return metadata
            }
        )

        return await converter.transactionRecord(transaction: transaction, resolvesUnknownMetadata: resolvesUnknownMetadata)
    }
}

private struct StubCoinManager: ICoinManager {
    let tokens: [TokenQuery: Token]

    func token(query: TokenQuery) throws -> Token? {
        tokens[query]
    }
}
