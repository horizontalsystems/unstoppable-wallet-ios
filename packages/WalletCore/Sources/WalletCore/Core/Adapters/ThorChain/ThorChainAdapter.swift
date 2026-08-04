import BigInt
import Combine
import Foundation
import MarketKit
import RxSwift
import ThorChainKit

final class ThorChainAdapter: IAdapter, IBalanceAdapter, IDepositAdapter {
    private static let decimals = ThorChainKit.Denom.decimals

    let thorChainKitWrapper: ThorChainKitWrapper
    // One account read carries every denom, so RUNE and every THORChain asset share a
    // single kit; the adapter only picks its own denom out of that state.
    private let denom: ThorChainKit.Denom

    // The network fee is fixed chain-wide; start() refreshes the cached value. The
    // refresh runs off a task and the fee is read from wherever a screen asks, so the
    // two are kept apart by a lock rather than by hoping they never overlap.
    private let feeLock = NSLock()
    private var storedFee: BigUInt = 2_000_000
    private var feeTask: Task<Void, Never>?

    private var cachedFee: BigUInt {
        get { feeLock.lock(); defer { feeLock.unlock() }; return storedFee }
        set { feeLock.lock(); storedFee = newValue; feeLock.unlock() }
    }

    init(thorChainKitWrapper: ThorChainKitWrapper, denom: ThorChainKit.Denom = .rune) throws {
        self.thorChainKitWrapper = thorChainKitWrapper
        self.denom = denom
    }

    var fee: Decimal {
        balanceData(baseUnits: cachedFee).available
    }

    var availableBalance: Decimal {
        balanceData.available
    }

    var runeAvailableBalance: Decimal {
        balanceData(baseUnits: thorChainKitWrapper.thorChainKit.balance(denom: .rune)).available
    }

    var isNativeCoin: Bool {
        denom == .rune
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
        // The kit itself is started by ThorChainKitManager; only the fee cache is ours.
        feeTask = Task { [weak self] in
            guard let fee = try? await self?.thorChainKitWrapper.thorChainKit.estimateFee() else { return }
            self?.cachedFee = fee
        }
    }

    func stop() {
        feeTask?.cancel()
        feeTask = nil
    }

    func refresh() {}

    var balanceState: AdapterState {
        adapterState(syncState: thorChainKitWrapper.thorChainKit.syncState)
    }

    var balanceStateUpdatedObservable: Observable<AdapterState> {
        thorChainKitWrapper.thorChainKit.syncStatePublisher.asObservable().map { [weak self] in
            self?.adapterState(syncState: $0) ?? .syncing(progress: nil, remaining: nil, lastBlockDate: nil)
        }
    }

    var balanceData: BalanceData {
        balanceData(baseUnits: thorChainKitWrapper.thorChainKit.balance(denom: denom))
    }

    var balanceDataUpdatedObservable: Observable<BalanceData> {
        thorChainKitWrapper.thorChainKit.balancePublisher(denom: denom).asObservable().map { [weak self] in
            self?.balanceData(baseUnits: $0) ?? BalanceData(balance: 0)
        }
    }

    var receiveAddress: DepositAddress {
        DepositAddress(thorChainKitWrapper.thorChainKit.address.raw)
    }

    private var syncStateCode: String {
        Self.stateCode(thorChainKitWrapper.thorChainKit.syncState)
    }

    private static func stateCode(_ syncState: ThorChainKit.SyncState) -> String {
        switch syncState {
        case .idle(cached: false): return "idle"
        case .idle(cached: true): return "idle_cached"
        case .syncing: return "syncing"
        case .synced: return "synced"
        case let .notSynced(error, cached: _): return syncErrorCode(error)
        }
    }

    private func adapterState(syncState: ThorChainKit.SyncState) -> AdapterState {
        switch syncState {
        case .idle:
            return .notSynced(error: Self.stateCode(syncState))
        case .syncing:
            return .syncing(progress: nil, remaining: nil, lastBlockDate: nil)
        case .synced:
            return .synced
        case let .notSynced(error, cached: _):
            return .notSynced(error: Self.syncErrorCode(error))
        }
    }

    private func balanceData(baseUnits: BigUInt) -> BalanceData {
        (try? Self.balanceData(baseUnits: baseUnits, decimals: Self.decimals)) ?? BalanceData(balance: 0)
    }

    static func balanceData(baseUnits: BigUInt, decimals: Int) throws -> BalanceData {
        guard (0 ... 38).contains(decimals) else {
            throw ThorChainAdapterError.invalidDecimals
        }

        let baseUnitsDescription = baseUnits.description
        let significantDigits = baseUnitsDescription.reversed().drop(while: { $0 == "0" }).count
        guard significantDigits <= 38 else {
            throw ThorChainAdapterError.balancePrecisionLoss
        }

        guard var raw = Decimal(string: baseUnitsDescription) else {
            throw ThorChainAdapterError.balanceConversionOverflow
        }
        var divisor = Decimal(1)
        var ten = Decimal(10)
        for _ in 0 ..< decimals {
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
    case invalidDecimals
    case balancePrecisionLoss
    case balanceConversionOverflow

    static let balanceInvariantCode = "balance_invariant"
}
