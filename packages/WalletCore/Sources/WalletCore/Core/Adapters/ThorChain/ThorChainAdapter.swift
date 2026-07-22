import BigInt
import Combine
import Foundation
import MarketKit
import RxSwift
import ThorChainKit

final class ThorChainAdapter: IAdapter, IBalanceAdapter, IDepositAdapter {
    private let thorChainKitWrapper: ThorChainKitWrapper
    private let wallet: Wallet
    private let disposeBag = DisposeBag()
    private let lifecycleLock = NSLock()
    private let balanceStateSubject = PublishSubject<AdapterState>()
    private let balanceDataSubject = PublishSubject<BalanceData>()
    private var stopped = false
    private var cachedBalance = BalanceData(balance: 0)
    private var conversionFailure = false

    init(thorChainKitWrapper: ThorChainKitWrapper, wallet: Wallet) throws {
        guard wallet.token.blockchainType == .thorChain,
              wallet.token.type == .native,
              wallet.token.decimals == 8
        else {
            throw ThorChainAdapterError.invalidTokenIdentity
        }

        self.thorChainKitWrapper = thorChainKitWrapper
        self.wallet = wallet
        cachedBalance = try Self.balanceData(baseUnits: thorChainKitWrapper.thorChainKit.runeBalance, decimals: wallet.token.decimals)

        thorChainKitWrapper.thorChainKit.syncStatePublisher
            .asObservable()
            .subscribe(onNext: { [weak self] _ in self?.publishState() })
            .disposed(by: disposeBag)
        thorChainKitWrapper.thorChainKit.accountStatePublisher
            .asObservable()
            .subscribe(onNext: { [weak self] _ in self?.publishBalance() })
            .disposed(by: disposeBag)
    }

    var isMainNet: Bool {
        thorChainKitWrapper.thorChainKit.network.environment == .mainnet
    }

    var statusInfo: [(String, Any)] {
        [
            ("syncState", syncStateCode),
            ("lastBlockHeight", thorChainKitWrapper.thorChainKit.lastBlockHeight as Any),
            ("chainId", thorChainKitWrapper.thorChainKit.network.expectedChainId),
            ("endpointFamilyId", "managed"),
        ]
    }

    var debugInfo: String {
        "thorchain:\(syncStateCode):\(thorChainKitWrapper.thorChainKit.network.expectedChainId)"
    }

    func start() {
        guard admitLifecycleCall() else { return }
        thorChainKitWrapper.thorChainKit.start()
    }

    func stop() {
        lifecycleLock.lock()
        guard !stopped else {
            lifecycleLock.unlock()
            return
        }
        stopped = true
        lifecycleLock.unlock()
        thorChainKitWrapper.thorChainKit.stop()
    }

    func refresh() {
        guard admitLifecycleCall() else { return }
        thorChainKitWrapper.thorChainKit.refresh()
    }

    var balanceState: AdapterState {
        if conversionFailure {
            return .notSynced(error: ThorChainAdapterError.balanceInvariantCode)
        }
        return adapterState(syncState: thorChainKitWrapper.thorChainKit.syncState)
    }

    var balanceStateUpdatedObservable: Observable<AdapterState> {
        balanceStateSubject.startWith(balanceState)
    }

    var balanceData: BalanceData {
        cachedBalance
    }

    var balanceDataUpdatedObservable: Observable<BalanceData> {
        balanceDataSubject.startWith(cachedBalance)
    }

    var receiveAddress: DepositAddress {
        DepositAddress(thorChainKitWrapper.thorChainKit.address.raw)
    }

    deinit {
        stop()
    }

    private var syncStateCode: String {
        switch thorChainKitWrapper.thorChainKit.syncState {
        case .idle(cached: false): return "idle"
        case .idle(cached: true): return "idle_cached"
        case .syncing: return "syncing"
        case .synced: return "synced"
        case let .notSynced(error, cached: _): return Self.syncErrorCode(error)
        }
    }

    private func adapterState(syncState: ThorChainKit.SyncState) -> AdapterState {
        switch syncState {
        case .idle(cached: false), .idle(cached: true):
            return .notSynced(error: syncStateCode)
        case .syncing:
            return .syncing(progress: nil, remaining: nil, lastBlockDate: nil)
        case .synced:
            return .synced
        case let .notSynced(error, cached: _):
            return .notSynced(error: Self.syncErrorCode(error))
        }
    }

    private func publishState() {
        guard !isStopped else { return }
        balanceStateSubject.onNext(balanceState)
    }

    private func publishBalance() {
        guard !isStopped else { return }
        do {
            cachedBalance = try Self.balanceData(
                baseUnits: thorChainKitWrapper.thorChainKit.runeBalance,
                decimals: wallet.token.decimals
            )
            conversionFailure = false
            balanceDataSubject.onNext(cachedBalance)
        } catch {
            conversionFailure = true
            balanceStateSubject.onNext(balanceState)
        }
    }

    private func admitLifecycleCall() -> Bool {
        lifecycleLock.lock()
        defer { lifecycleLock.unlock() }
        return !stopped
    }

    private var isStopped: Bool {
        lifecycleLock.lock()
        defer { lifecycleLock.unlock() }
        return stopped
    }

    static func balanceData(baseUnits: BigUInt, decimals: Int) throws -> BalanceData {
        guard (0...38).contains(decimals) else {
            throw ThorChainAdapterError.invalidDecimals
        }

        guard var raw = Decimal(string: baseUnits.description) else {
            throw ThorChainAdapterError.balanceConversionOverflow
        }
        var divisor = Decimal(1)
        let ten = Decimal(10)
        for _ in 0..<decimals {
            var next = Decimal()
            guard NSDecimalMultiply(&next, &divisor, &ten, .plain) == .noError else {
                throw ThorChainAdapterError.balanceConversionOverflow
            }
            divisor = next
        }

        var converted = Decimal()
        guard NSDecimalDivide(&converted, &raw, &divisor, .plain) == .noError else {
            throw ThorChainAdapterError.balanceConversionOverflow
        }
        var reconstructed = Decimal()
        guard NSDecimalMultiply(&reconstructed, &converted, &divisor, .plain) == .noError else {
            throw ThorChainAdapterError.balanceConversionOverflow
        }
        guard NSDecimalCompare(&reconstructed, &raw) == .orderedSame else {
            throw ThorChainAdapterError.balancePrecisionLoss
        }
        return BalanceData(balance: converted)
    }

    private static func syncErrorCode(_ error: ThorChainKit.SyncError) -> String {
        switch error {
        case .noConnection: return "no_connection"
        case .rateLimited: return "rate_limited"
        case .wrongNetwork: return "wrong_network"
        case .nodeUnavailable: return "node_unavailable"
        case .invalidResponse: return "invalid_response"
        case .storageUnavailable: return "storage_unavailable"
        case .internalInvariant: return "internal_invariant"
        }
    }
}

enum ThorChainAdapterError: Error, Equatable {
    case invalidTokenIdentity
    case invalidDecimals
    case balanceConversionOverflow
    case balancePrecisionLoss

    static let balanceInvariantCode = "balance_invariant"
}
