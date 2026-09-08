import Foundation
import MarketKit
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

    // the fixture is a 1000-lamport system transfer: Method, Value, To
    @Test func sectionsListDecodedTransferAndFee() throws {
        let data = try WCSolanaSendData(token: Self.token, payload: payload(), fee: 0.000005, transactionError: nil)
        let sections = data.sections(baseToken: Self.token, currency: currency, rates: [:])

        #expect(data.canSend)
        #expect(sections.count == 1)
        #expect(sections[0].fields.count == 3)
        #expect(data.feeFields(baseToken: Self.token, currency: currency, rates: [:]).count == 1)
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
}
