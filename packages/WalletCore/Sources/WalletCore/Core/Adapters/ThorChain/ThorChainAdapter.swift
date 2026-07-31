import BigInt
import Combine
import Foundation
import MarketKit
import RxSwift
import ThorChainKit

final class ThorChainAdapter: IAdapter, IBalanceAdapter, IDepositAdapter {
    private static let decimals = 8

    let thorChainKitWrapper: ThorChainKitWrapper
    private let disposeBag = DisposeBag()
    private let balanceStateSubject = PublishSubject<AdapterState>()
    private let balanceDataSubject = PublishSubject<BalanceData>()
    private var cachedBalance = BalanceData(balance: 0)
    private var conversionFailure = false

    init(thorChainKitWrapper: ThorChainKitWrapper) throws {
        self.thorChainKitWrapper = thorChainKitWrapper
        cachedBalance = try Self.balanceData(baseUnits: thorChainKitWrapper.thorChainKit.runeBalance, decimals: Self.decimals)

        thorChainKitWrapper.thorChainKit.syncStatePublisher
            .asObservable()
            .subscribe(onNext: { [weak self] _ in self?.publishState() })
            .disposed(by: disposeBag)
        thorChainKitWrapper.thorChainKit.accountStatePublisher
            .asObservable()
            .subscribe(onNext: { [weak self] _ in
                self?.publishBalance()
            })
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

    func start() {}
    func stop() {
        thorChainKitWrapper.thorChainKit.stop()
    }

    func refresh() {}

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
        balanceStateSubject.onNext(balanceState)
    }

    private func publishBalance() {
        do {
            cachedBalance = try Self.balanceData(
                baseUnits: thorChainKitWrapper.thorChainKit.runeBalance,
                decimals: Self.decimals
            )
            conversionFailure = false
            balanceDataSubject.onNext(cachedBalance)
        } catch {
            conversionFailure = true
            balanceStateSubject.onNext(balanceState)
        }
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
