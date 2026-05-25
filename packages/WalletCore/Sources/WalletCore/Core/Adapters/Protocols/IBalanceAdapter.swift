import Foundation
import RxSwift

public protocol IBalanceAdapter: IBaseAdapter {
    var balanceState: AdapterState { get }
    var balanceStateUpdatedObservable: Observable<AdapterState> { get }
    var spendMode: BalanceAdapterSpendMode { get }
    var balanceData: BalanceData { get }
    var balanceDataUpdatedObservable: Observable<BalanceData> { get }
    var caution: CautionNew? { get }
    var cautionUpdatedObservable: Observable<CautionNew?> { get }
}

public extension IBalanceAdapter {
    var caution: CautionNew? {
        nil
    }

    var cautionUpdatedObservable: Observable<CautionNew?> {
        .just(nil)
    }

    var spendMode: BalanceAdapterSpendMode {
        .fromBalanceState
    }
}

public enum BalanceAdapterSpendMode {
    case fromBalanceState
    case allowedWhenSyncing

    public func spendAllowed(state: AdapterState) -> Bool {
        switch self {
        case .fromBalanceState:
            state.isSynced
        case .allowedWhenSyncing:
            state.isSynced || state.syncing
        }
    }
}
