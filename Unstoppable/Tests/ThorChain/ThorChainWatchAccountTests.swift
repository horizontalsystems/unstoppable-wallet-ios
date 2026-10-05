import Foundation
import MarketKit
import RxSwift
import Testing
@testable import WalletCore

// Watch accounts by address on THORChain and Maya (Android `ThorchainAddress` / `MayachainAddress`).
struct ThorChainWatchAccountTests {
    // MARK: tokens and networks

    @Test func thorWatchSeesRuneAndThorAssets() {
        let type = AccountType.thorChainAddress(address: Self.thor)

        #expect(type.supports(token: Self.token(.thorChain, .native)))
        #expect(type.supports(token: Self.token(.thorChain, .thorChainAsset(denom: "tcy"))))
        #expect(!type.supports(token: Self.token(.mayaChain, .native)))
        #expect(BlockchainType.thorChain.supports(accountType: type))
        #expect(!BlockchainType.mayaChain.supports(accountType: type))
    }

    @Test func mayaWatchSeesCacaoOnly() {
        let type = AccountType.mayaChainAddress(address: Self.maya)

        #expect(type.supports(token: Self.token(.mayaChain, .native)))
        #expect(!type.supports(token: Self.token(.mayaChain, .thorChainAsset(denom: "maya"))))
        #expect(!type.supports(token: Self.token(.thorChain, .native)))
        #expect(!type.supports(token: Self.token(.ethereum, .native)))
        #expect(BlockchainType.mayaChain.supports(accountType: type))
        #expect(!BlockchainType.thorChain.supports(accountType: type))
    }

    @Test func sameAddressIsOneAccount() {
        #expect(AccountType.thorChainAddress(address: Self.thor) == .thorChainAddress(address: Self.thor))
        #expect(AccountType.thorChainAddress(address: Self.thor).uniqueId() == AccountType.thorChainAddress(address: Self.thor).uniqueId())
        #expect(AccountType.thorChainAddress(address: Self.thor) != .mayaChainAddress(address: Self.thor))
    }

    // MARK: watch screen parsing

    // Solana checks only "base58, 32 bytes": a thor1 address without 0 and l passes it
    @Test func solanaAloneTakesThorAddressWithoutZeroAndL() {
        #expect(parse(Self.thorWithoutZeroAndL, handlers: AddressParserFactory.parserChainHandlers(blockchainType: .solana))?.blockchainType == .solana)
    }

    // the order of WatchViewModel: THORChain and Maya before Solana
    @Test func watchOrderResolvesThorAndMayaBeforeSolana() {
        #expect(parse(Self.thorWithoutZeroAndL)?.blockchainType == .thorChain)
        #expect(parse(Self.thor)?.blockchainType == .thorChain)
        #expect(parse(Self.maya)?.blockchainType == .mayaChain)
    }

    @Test func thorParserTakesOnlyThorAddresses() {
        let thorOnly = AddressParserFactory.parserChainHandlers(blockchainType: .thorChain)

        #expect(parse(Self.thor.uppercased(), handlers: thorOnly)?.blockchainType == .thorChain)

        let rejected = [
            Self.maya,
            "sthor1le9eykyndunax8k24w8fykd8ndx35w2h78yeee", // another hrp
            "thor1LE9EYKYNDUNAX8K24W8FYKD8NDX35W2H27C008", // mixed case
            "thor133r7yg73dmwcc3a5dt79hthzv86nkfs4je877q", // broken checksum
            "thor1qqqsyqcyq5rqwzqfpg9scrgwpugpzysnzs23v9ccrydpk8qarc0sztexdf", // 32-byte payload
        ]
        for address in rejected {
            #expect(parse(address, handlers: thorOnly) == nil, "\(address) was accepted")
        }
    }
}

extension ThorChainWatchAccountTests {
    private static let thor = "thor1le9eykyndunax8k24w8fykd8ndx35w2h27c008"
    // the same key under the Maya hrp
    private static let maya = "maya1le9eykyndunax8k24w8fykd8ndx35w2h2fxreh"
    private static let thorWithoutZeroAndL = "thor133r7yg73dmwcc3a5dt79hthzv86nkfs4je877k"

    private static func token(_ blockchainType: BlockchainType, _ type: TokenType) -> Token {
        Token(
            coin: Coin(uid: "coin", name: "Coin", code: "COIN"),
            blockchain: Blockchain(type: blockchainType, name: blockchainType.uid, explorerUrl: nil),
            type: type,
            decimals: 8
        )
    }

    private func parse(_ address: String, handlers: [IAddressParserItem]? = nil) -> Address? {
        let chain = AddressParserChain()
        if let handlers {
            chain.append(handlers: handlers)
        } else {
            chain.append(handlers: AddressParserFactory.parserChainHandlers(blockchainType: .thorChain))
            chain.append(handlers: AddressParserFactory.parserChainHandlers(blockchainType: .mayaChain))
            chain.append(handlers: AddressParserFactory.parserChainHandlers(blockchainType: .solana))
        }

        // the parsers here answer synchronously
        var result: Address?
        _ = chain.handle(address: address).subscribe(onSuccess: { result = $0 }, onError: { _ in })
        return result
    }
}
