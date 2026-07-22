import BigInt
import Combine
import Foundation
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

    @Test func stopSerializesWithInFlightStartAndRejectsLaterRefresh() throws {
        let spy = ThorChainKitSpy()
        let startEntered = DispatchSemaphore(value: 0)
        let releaseStart = DispatchSemaphore(value: 0)
        spy.startEntered = startEntered
        spy.releaseStart = releaseStart
        let adapter = try ThorChainAdapter(thorChainKitWrapper: ThorChainKitWrapper(thorChainKit: spy), wallet: Self.wallet())
        let startFinished = DispatchSemaphore(value: 0)
        let stopFinished = DispatchSemaphore(value: 0)

        DispatchQueue.global().async {
            adapter.start()
            startFinished.signal()
        }
        #expect(startEntered.wait(timeout: .now() + 1) == .success)

        DispatchQueue.global().async {
            adapter.stop()
            stopFinished.signal()
        }
        #expect(stopFinished.wait(timeout: .now() + 0.1) == .timedOut)

        releaseStart.signal()
        #expect(startFinished.wait(timeout: .now() + 1) == .success)
        #expect(stopFinished.wait(timeout: .now() + 1) == .success)

        adapter.refresh()
        #expect(spy.startCount == 1)
        #expect(spy.stopCount == 1)
        #expect(spy.refreshCount == 0)
    }

    @Test func stopCompletesWhenKitPublishesSynchronously() throws {
        let spy = ThorChainKitSpy()
        spy.emitStateOnStop = true
        let adapter = try ThorChainAdapter(thorChainKitWrapper: ThorChainKitWrapper(thorChainKit: spy), wallet: Self.wallet())
        let stopFinished = DispatchSemaphore(value: 0)

        DispatchQueue.global().async {
            adapter.stop()
            stopFinished.signal()
        }

        #expect(stopFinished.wait(timeout: .now() + 1) == .success)
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

        do {
            _ = try ThorChainAdapter.balanceData(
                baseUnits: BigUInt("100000000000000000000000000000000000000000000000001")!,
                decimals: 8
            )
            Issue.record("precision loss was accepted")
        } catch {
            #expect((error as? ThorChainAdapterError) == .balancePrecisionLoss)
        }
    }

    @Test func syncErrorsMapToClosedDiagnostics() throws {
        let spy = ThorChainKitSpy()
        let adapter = try ThorChainAdapter(thorChainKitWrapper: ThorChainKitWrapper(thorChainKit: spy), wallet: Self.wallet())
        spy.syncStateSubject.send(.notSynced(.rateLimited, cached: nil))

        #expect(adapter.balanceState == .notSynced(error: "rate_limited"))
        #expect(!adapter.debugInfo.contains("rateLimited"))
    }

    @Test func syncErrorsMapToStableCodesAndRetainCachedBalance() throws {
        let errors: [(ThorChainKit.SyncError, String)] = [
            (.noConnection, "no_connection"),
            (.rateLimited, "rate_limited"),
            (.wrongNetwork, "wrong_network"),
            (.nodeUnavailable, "node_unavailable"),
            (.invalidResponse, "invalid_response"),
            (.storageUnavailable, "storage_unavailable"),
            (.internalInvariant, "internal_invariant"),
        ]
        let spy = ThorChainKitSpy()
        spy.runeBalance = 100_000_000
        let adapter = try ThorChainAdapter(thorChainKitWrapper: ThorChainKitWrapper(thorChainKit: spy), wallet: Self.wallet())

        for (error, code) in errors {
            spy.syncStateSubject.send(.notSynced(error, cached: nil))
            #expect(adapter.balanceState == .notSynced(error: code))
            #expect(adapter.balanceData.total == 1)
        }
    }

    @Test func invalidBalanceConversionFailsClosedAndRetainsCachedValue() throws {
        let spy = ThorChainKitSpy()
        spy.runeBalance = 100_000_000
        let adapter = try ThorChainAdapter(thorChainKitWrapper: ThorChainKitWrapper(thorChainKit: spy), wallet: Self.wallet())
        spy.runeBalance = BigUInt("100000000000000000000000000000000000000000000000001")!
        spy.accountStateSubject.send(nil)

        #expect(adapter.balanceData.total == 1)
        #expect(adapter.balanceState == .notSynced(error: ThorChainAdapterError.balanceInvariantCode))
    }

    @Test func depositAddressIsCanonicalKitAddress() throws {
        let spy = ThorChainKitSpy()
        let adapter = try ThorChainAdapter(thorChainKitWrapper: ThorChainKitWrapper(thorChainKit: spy), wallet: Self.wallet())

        #expect(adapter.receiveAddress.raw == spy.address.raw)
    }

    @Test func invalidTokenIdentityFailsBeforeSubscriptions() {
        let spy = ThorChainKitSpy()
        do {
            _ = try ThorChainAdapter(
                thorChainKitWrapper: ThorChainKitWrapper(thorChainKit: spy),
                wallet: Self.wallet(decimals: 7)
            )
            Issue.record("invalid token identity was accepted")
        } catch {
            #expect((error as? ThorChainAdapterError) == .invalidTokenIdentity)
        }
    }

    private static func wallet(decimals: Int = 8) -> Wallet {
        Wallet(
            token: Token(
                coin: Coin(uid: "thorchain", name: "THORChain", code: "RUNE"),
                blockchain: Blockchain(type: .thorChain, name: "THORChain", explorerUrl: nil),
                type: .native,
                decimals: decimals
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
    var startEntered: DispatchSemaphore?
    var releaseStart: DispatchSemaphore?
    var emitStateOnStop = false

    var network: ThorChainKit.Network { address.network }
    var lastBlockHeight: Int64? { nil }
    var syncState: ThorChainKit.SyncState { syncStateSubject.value }
    var accountState: ThorChainKit.AccountState? { nil }
    var accountExists: Bool { false }
    var lastBlockHeightPublisher: AnyPublisher<Int64?, Never> { Just(nil).eraseToAnyPublisher() }
    var syncStatePublisher: AnyPublisher<ThorChainKit.SyncState, Never> { syncStateSubject.eraseToAnyPublisher() }
    var accountStatePublisher: AnyPublisher<ThorChainKit.AccountState?, Never> { accountStateSubject.eraseToAnyPublisher() }

    func start() {
        startEntered?.signal()
        releaseStart?.wait()
        startCount += 1
    }
    func stop() {
        stopCount += 1
        if emitStateOnStop {
            syncStateSubject.send(.idle(cached: false))
        }
    }
    func refresh() { refreshCount += 1 }
}
