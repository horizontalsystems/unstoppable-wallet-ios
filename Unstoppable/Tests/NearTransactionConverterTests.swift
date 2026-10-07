import Foundation
import GRDB
import MarketKit
import NearKit
import Testing
@testable import WalletCore

// Android `NearTransactionConverter`: a token movement wins over the NEAR attached to it, a signed
// transfer is a send, anything else signed is a contract call, NEAR arriving is a receive; the fee
// is the account's only when it signed. An expired transaction is failed and "not processed".
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
        // outgoing token sends stay out of the phishing check (TECH_DEBT F-3)
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

        guard case let .contractCall(contractId, method, value) = record.type else {
            Issue.record("expected a contract call, got \(record.type)")
            return
        }
        #expect(contractId == "wrap.near")
        #expect(method == "near_deposit")
        #expect(value?.value == -1)
        #expect(record.fee != nil)
    }

    @Test func signedActionWithoutMethodIsNamedByItsType() async throws {
        let record = try await Self.record(signer: Self.own, receiver: Self.own, actions: [TxActionJson(type: "AddKey")])

        guard case let .contractCall(_, method, value) = record.type else {
            Issue.record("expected a contract call, got \(record.type)")
            return
        }
        #expect(method == "AddKey")
        #expect(value == nil)
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

    static func nearTransfer(from: String, to: String, amount: String, kind: String = "Transfer") -> NearTransferJson {
        NearTransferJson(from: from, to: to, amount: amount, kind: kind, success: true)
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
