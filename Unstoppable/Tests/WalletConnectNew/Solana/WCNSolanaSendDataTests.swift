import Foundation
import MarketKit
import Testing
@testable import WalletCore

struct WCNSolanaSendDataTests {
    private let currency = Currency(code: "USD", symbol: "$", decimal: 2)
    private static let token = Token(
        coin: Coin(uid: "solana", name: "Solana", code: "SOL"),
        blockchain: MarketKit.Blockchain(type: .solana, name: "Solana", explorerUrl: nil),
        type: .native,
        decimals: 9
    )

    private func parsed(method: String = WCNSolanaTransactionParsed.signAndSendMethod, from: String? = SolanaRawSigningFixtures.ours) throws -> WCNSolanaTransactionParsed {
        let request = try WCNTestFixtures.request(method: method, chainId: "solana:5eykt4UsFv8P8NJdTREpY1vzqKqZKvdp")
        return WCNSolanaTransactionParsed(request: request, rawTransactions: [SolanaRawSigningFixtures.partiallySigned], requiredSigners: [[SolanaRawSigningFixtures.other, SolanaRawSigningFixtures.ours]], from: from)
    }

    @Test func insufficientBalanceBlocksSend() throws {
        let data = try WCNSolanaSendData(token: Self.token, parsed: parsed(), fee: 0.000005, transactionError: WCNSolanaSendHandler.TransactionError.insufficientBalance(balance: 0))

        #expect(data.canSend == false)
        let cautions = data.cautions(baseToken: Self.token, currency: currency, rates: [:])
        #expect(cautions.count == 1)
        #expect(cautions[0].type == .error)
    }

    @Test func sectionsListSignersAccountAndFee() throws {
        let data = try WCNSolanaSendData(token: Self.token, parsed: parsed(), fee: 0.000005, transactionError: nil)
        let sections = data.sections(baseToken: Self.token, currency: currency, rates: [:])

        #expect(data.canSend)
        #expect(sections.count == 3)
        #expect(sections[0].fields.count == 2)
    }

    @Test func missingFromOmitsAccountSection() throws {
        let data = try WCNSolanaSendData(token: Self.token, parsed: parsed(from: nil), fee: nil, transactionError: nil)
        let sections = data.sections(baseToken: Self.token, currency: currency, rates: [:])
        #expect(sections.count == 1)
    }
}
