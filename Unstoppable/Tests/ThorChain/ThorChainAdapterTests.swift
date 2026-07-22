import BigInt
import Combine
import MarketKit
import Testing
import ThorChainKit
@testable import WalletCore

struct ThorChainAdapterTests {
    @Test func lifecycleForwardsExactlyOnceAndStopIsIdempotent() throws {
        let spy = ThorChainKitSpy()
        let adapter = try ThorChainAdapter(thorChainKitWrapper: ThorChainKitWrapper(thorChainKit: spy), wallet: Self.wallet())

        adapter.start()
        adapter.refresh()
        adapter.stop()
        adapter.stop()

        #expect(spy.startCount == 1)
        #expect(spy.refreshCount == 1)
        #expect(spy.stopCount == 1)
    }

    @Test func runeConversionUsesEightDecimalsWithoutDouble() throws {
        let oneRune = try ThorChainAdapter.balanceData(baseUnits: 100_000_000, decimals: 8)
        #expect(oneRune.total == 1)

        let oneBaseUnit = try ThorChainAdapter.balanceData(baseUnits: 1, decimals: 8)
        #expect(oneBaseUnit.total == Decimal(string: "0.00000001"))
        do {
            _ = try ThorChainAdapter.balanceData(baseUnits: 1, decimals: 39)
            Issue.record("invalid decimals were accepted")
        } catch {
            #expect((error as? ThorChainAdapterError) == .invalidDecimals)
        }
    }

    @Test func syncErrorsMapToClosedDiagnostics() throws {
        let spy = ThorChainKitSpy()
        let adapter = try ThorChainAdapter(thorChainKitWrapper: ThorChainKitWrapper(thorChainKit: spy), wallet: Self.wallet())
        spy.syncStateSubject.send(.notSynced(.rateLimited, cached: nil))

        #expect(adapter.balanceState == .notSynced(error: "rate_limited"))
        #expect(!adapter.debugInfo.contains("rateLimited"))
    }

    private static func wallet() -> Wallet {
        Wallet(
            token: Token(
                coin: Coin(uid: "thorchain", name: "THORChain", code: "RUNE"),
                blockchain: Blockchain(type: .thorChain, name: "THORChain", explorerUrl: nil),
                type: .native,
                decimals: 8
            ),
            account: Account(
                id: "thorchain-test-account",
                level: 0,
                name: "Test",
                type: .mnemonic(words: [], salt: "", bip39Compliant: true),
                origin: .created,
                backedUp: false,
                fileBackedUp: false
            )
        )
    }
}

private final class ThorChainKitSpy: IThorChainKit {
    let address = try! ThorChainKit.Address(
        "thor1x0jkvqdh2hlpeztd5zyyk70n3efx6mhudkmnn2",
        network: .mainnet
    )
    let syncStateSubject = CurrentValueSubject<ThorChainKit.SyncState, Never>(.idle(cached: false))
    let accountStateSubject = CurrentValueSubject<ThorChainKit.AccountState?, Never>(nil)
    var runeBalance: BigUInt = 0
    var startCount = 0
    var stopCount = 0
    var refreshCount = 0

    var network: ThorChainKit.Network { address.network }
    var lastBlockHeight: Int64? { nil }
    var syncState: ThorChainKit.SyncState { syncStateSubject.value }
    var accountState: ThorChainKit.AccountState? { nil }
    var accountExists: Bool { false }
    var lastBlockHeightPublisher: AnyPublisher<Int64?, Never> { Just(nil).eraseToAnyPublisher() }
    var syncStatePublisher: AnyPublisher<ThorChainKit.SyncState, Never> { syncStateSubject.eraseToAnyPublisher() }
    var accountStatePublisher: AnyPublisher<ThorChainKit.AccountState?, Never> { accountStateSubject.eraseToAnyPublisher() }

    func start() { startCount += 1 }
    func stop() { stopCount += 1 }
    func refresh() { refreshCount += 1 }
}
