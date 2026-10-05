import Foundation
import MarketKit
import SolanaKit
import Testing
@testable import WalletCore

struct WCSolanaSendDataTests {
    private let currency = Currency(code: "USD", symbol: "$", decimal: 2)
    private static let token = Token(
        coin: Coin(uid: "solana", name: "Solana", code: "SOL"),
        blockchain: MarketKit.Blockchain(type: .solana, name: "Solana", explorerUrl: nil),
        type: .native,
        decimals: 9
    )

    private func payload(method: String = WCSolanaTransactionPayload.signAndSendMethod, from: String? = SolanaRawSigningFixtures.ours) throws -> WCSolanaTransactionPayload {
        let request = try WCTestFixtures.request(method: method, chainId: "solana:5eykt4UsFv8P8NJdTREpY1vzqKqZKvdp")
        return WCSolanaTransactionPayload(request: request, rawTransactions: [SolanaRawSigningFixtures.partiallySigned], requiredSigners: [[SolanaRawSigningFixtures.other, SolanaRawSigningFixtures.ours]], from: from)
    }

    @Test func insufficientBalanceBlocksSend() throws {
        let data = try WCSolanaSendData(token: Self.token, payload: payload(), fee: 0.000005, transactionError: WCSolanaSendHandler.TransactionError.insufficientBalance(balance: 0))

        #expect(data.canSend == false)
        let cautions = data.cautions(baseToken: Self.token, currency: currency, rates: [:])
        #expect(cautions.count == 1)
        #expect(cautions[0].type == .error)
    }

    // The fixture transfers from the other signer, which also pays the network fee.
    @Test func sectionsListDecodedTransferAndFee() throws {
        let data = try WCSolanaSendData(token: Self.token, payload: payload(), fee: 0.000005, transactionError: nil)
        let sections = data.sections(baseToken: Self.token, currency: currency, rates: [:])

        #expect(data.canSend)
        #expect(sections.count == 1)
        #expect(sections[0].fields.count == 4)
        let addresses = sections[0].fields.compactMap { $0.content as? RecipientField }
        #expect(addresses.map(\.value) == [SolanaRawSigningFixtures.other, SolanaRawSigningFixtures.ours])
        #expect(addresses.first?.title == "send.confirmation.from".localized)
        #expect(data.feeFields(baseToken: Self.token, currency: currency, rates: [:]).isEmpty)
        #expect(data.cautions(baseToken: Self.token, currency: currency, rates: [:]).isEmpty)
    }

    @Test func opaqueTransactionWarnsButStaysSendable() throws {
        let request = try WCTestFixtures.request(method: WCSolanaTransactionPayload.signAndSendMethod, chainId: "solana:5eykt4UsFv8P8NJdTREpY1vzqKqZKvdp")
        let raw = SolanaRawSigningFixtures.rawTransaction(signerKeys: [SolanaRawSigningFixtures.oursPublicKey])
        let payload = WCSolanaTransactionPayload(request: request, rawTransactions: [raw], requiredSigners: [[SolanaRawSigningFixtures.ours]], from: SolanaRawSigningFixtures.ours)
        let data = WCSolanaSendData(token: Self.token, payload: payload, fee: nil, transactionError: nil)

        let cautions = data.cautions(baseToken: Self.token, currency: currency, rates: [:])
        #expect(data.canSend)
        #expect(cautions.count == 1)
        #expect(cautions[0].type == .warning)
        #expect(data.sections(baseToken: Self.token, currency: currency, rates: [:])[0].fields.isEmpty)
    }

    @Test func feeIsShownWhenConnectedSignerIsFeePayer() throws {
        let data = try WCSolanaSendData(token: Self.token, payload: payload(from: SolanaRawSigningFixtures.other), fee: 0.000005, transactionError: nil)
        #expect(data.feeFields(baseToken: Self.token, currency: currency, rates: [:]).count == 1)
        let fields = data.sections(baseToken: Self.token, currency: currency, rates: [:])[0].fields
        #expect(fields.count == 3)
    }

    @Test func batchPreservesDistinctWarningsAndHiddenRecipientRemainsSignable() throws {
        let ours = SolanaRawSigningFixtures.oursPublicKey
        let transfer = SolanaRawSigningFixtures.Instruction(program: 1, accounts: [0, 2], data: SolanaRawSigningFixtures.systemTransferData)
        let hidden = SolanaRawSigningFixtures.summaryTransaction(keys: [ours, PublicKey.systemProgramId.data], instructions: [transfer], version: 0x80, writableLookupIndices: [4])
        let unknown = SolanaRawSigningFixtures.summaryTransaction(keys: [ours, PublicKey.systemProgramId.data, Data(repeating: 0x22, count: 32)], instructions: [.init(program: 1, accounts: [0, 0], data: SolanaRawSigningFixtures.systemTransferData), .init(program: 2, accounts: [0], data: Data())])
        let request = try WCTestFixtures.request(method: WCSolanaTransactionPayload.signAllMethod, chainId: "solana:5eykt4UsFv8P8NJdTREpY1vzqKqZKvdp")
        let payload = WCSolanaTransactionPayload(request: request, rawTransactions: [unknown, Data([1]), hidden, hidden], requiredSigners: Array(repeating: [SolanaRawSigningFixtures.ours], count: 4), from: SolanaRawSigningFixtures.ours)
        let data = WCSolanaSendData(token: Self.token, payload: payload, fee: nil, transactionError: nil)
        let cautions = data.cautions(baseToken: Self.token, currency: currency, rates: [:])
        #expect(data.canSend)
        #expect(cautions.map(\.title) == ["wallet_connect.solana.hidden_recipient.title".localized, "wallet_connect.solana.unreadable_transaction.title".localized, "wallet_connect.solana.unknown_instructions.title".localized])
        #expect(cautions.map(\.type) == [.error, .warning, .warning])
        let values = data.sections(baseToken: Self.token, currency: currency, rates: [:])[0].fields.compactMap { $0.content as? SimpleValueField }
        #expect(values.filter { $0.title.description == "send.confirmation.to".localized && $0.value.description == "wallet_connect.solana.unknown_lookup_address".localized }.count == 2)
    }

    @Test func lookupAuthorityIsDisclosedAsUnknownSource() throws {
        let raw = SolanaRawSigningFixtures.summaryTransaction(keys: [SolanaRawSigningFixtures.oursPublicKey, PublicKey.tokenProgramId.data], instructions: [.init(program: 1, accounts: [0, 0, 2], data: Data([3, 1, 0, 0, 0, 0, 0, 0, 0]))], version: 0x80, readonlyLookupIndices: [0])
        let summary = WCSolanaTransactionSummary(rawTransaction: raw)
        let fields = summary.fields(baseToken: Self.token, signer: SolanaRawSigningFixtures.ours)
        let source = try #require(fields.compactMap { $0.content as? SimpleValueField }.first { $0.title.description == "send.confirmation.from".localized })
        #expect(source.value.description == "wallet_connect.solana.unknown_lookup_address".localized)
        #expect(summary.feePayer == SolanaRawSigningFixtures.ours)
    }
}
