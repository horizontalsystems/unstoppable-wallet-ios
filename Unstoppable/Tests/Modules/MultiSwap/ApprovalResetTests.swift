import Foundation
import MarketKit
import Testing
@testable import Unstoppable
@testable import WalletCore

// requiresApprovalReset: canonical USDT (ETH/Tron) reverts on non-zero -> non-zero approve;
// other eip20 tokens and native coins don't. Shared by swap flows that build approvals.
struct ApprovalResetTests {
    private static func eip20(_ address: String, blockchainType: BlockchainType) -> Token {
        Token(
            coin: Coin(uid: "c", name: "C", code: "C"),
            blockchain: Blockchain(type: blockchainType, name: "B", explorerUrl: nil),
            type: .eip20(address: address),
            decimals: 6
        )
    }

    @Test func ethereumUsdtRequiresReset() {
        let usdt = Self.eip20("0xdac17f958d2ee523a2206206994597c13d831ec7", blockchainType: .ethereum)
        #expect(ApprovalReset.required(token: usdt))
    }

    @Test func ethereumUsdtMatchIsCaseInsensitive() {
        let usdt = Self.eip20("0xDAC17F958D2EE523A2206206994597C13D831EC7", blockchainType: .ethereum)
        #expect(ApprovalReset.required(token: usdt))
    }

    @Test func bscStablecoinDoesNotRequireReset() {
        let bscUsd = Self.eip20("0x55d398326f99059ff775485246999027b3197955", blockchainType: .binanceSmartChain)
        #expect(!ApprovalReset.required(token: bscUsd))
    }

    @Test func otherEthereumTokenDoesNotRequireReset() {
        let usdc = Self.eip20("0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48", blockchainType: .ethereum)
        #expect(!ApprovalReset.required(token: usdc))
    }

    @Test func nativeCoinDoesNotRequireReset() {
        let native = Token(
            coin: Coin(uid: "eth", name: "Ethereum", code: "ETH"),
            blockchain: Blockchain(type: .ethereum, name: "Ethereum", explorerUrl: nil),
            type: .native,
            decimals: 18
        )
        #expect(!ApprovalReset.required(token: native))
    }
}
