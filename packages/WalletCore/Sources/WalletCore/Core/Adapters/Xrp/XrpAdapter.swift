import Combine
import Foundation
import RxSwift
import XrpKit

class XrpAdapter {
    static let decimals = 6

    let xrpKit: XrpKit.Kit
    private var cancellables = Set<AnyCancellable>()

    private let balanceStateSubject = PublishSubject<AdapterState>()
    private(set) var balanceState: AdapterState {
        didSet {
            balanceStateSubject.onNext(balanceState)
        }
    }

    private let balanceDataSubject = PublishSubject<BalanceData>()
    private(set) var balanceData: BalanceData {
        didSet {
            balanceDataSubject.onNext(balanceData)
        }
    }

    private let receiveAddressSubject = PassthroughSubject<DataStatus<DepositAddress>, Never>()

    init(xrpKit: XrpKit.Kit) {
        self.xrpKit = xrpKit

        balanceState = Self.adapterState(kitSyncState: xrpKit.syncState)
        balanceData = Self.balanceData(xrpKit: xrpKit)

        xrpKit.syncStatePublisher
            .sink { [weak self] in self?.balanceState = Self.adapterState(kitSyncState: $0) }
            .store(in: &cancellables)

        Publishers.Merge(xrpKit.accountStatePublisher.map { _ in () }, xrpKit.ledgerStatePublisher.map { _ in () })
            .sink { [weak self] in
                guard let self else { return }
                balanceData = Self.balanceData(xrpKit: xrpKit)
                receiveAddressSubject.send(.completed(receiveAddress))
            }
            .store(in: &cancellables)
    }

    /// Spendable XRP stops short of the reserve: base reserve plus one increment per owned object.
    private static func balanceData(xrpKit: XrpKit.Kit) -> BalanceData {
        BalanceData(total: xrpKit.balance, available: xrpKit.availableBalance)
    }

    /// Reserve breakdown for the token page.
    var reserveInfo: XrpReserveInfo {
        XrpReserveInfo(
            baseReserve: xrpKit.baseReserve,
            ownerReserve: xrpKit.ownerReserve,
            ownerCount: Int(xrpKit.accountState.ownerCount),
            trustLines: xrpKit.trustLines,
            total: xrpKit.minimumBalance
        )
    }

    var accountActivated: Bool {
        xrpKit.isAccountActivated
    }

    static func adapterState(kitSyncState: XrpKit.SyncState) -> AdapterState {
        switch kitSyncState {
        case .syncing: return .syncing(progress: nil, remaining: nil, lastBlockDate: nil)
        case .synced: return .synced
        case let .notSynced(error):
            if let syncError = error as? XrpKit.SyncError, case .notStarted = syncError {
                return .syncing(progress: nil, remaining: nil, lastBlockDate: nil)
            }
            return .notSynced(error: error.localizedDescription)
        }
    }

    static func clear(except excludedWalletIds: [String]) throws {
        try XrpKit.Kit.clear(exceptFor: excludedWalletIds)
    }
}

extension XrpAdapter: IBaseAdapter {
    var isMainNet: Bool {
        xrpKit.network.isMainNet
    }
}

extension XrpAdapter: IAdapter {
    func start() {
        // started via XrpKitManager
    }

    func stop() {
        // stopped via XrpKitManager
    }

    func refresh() {
        xrpKit.refresh()
    }

    var statusInfo: [(String, Any)] {
        xrpKit.statusInfo()
    }

    var debugInfo: String {
        ""
    }
}

extension XrpAdapter: IBalanceAdapter {
    var balanceStateUpdatedObservable: Observable<AdapterState> {
        balanceStateSubject.asObservable()
    }

    var balanceDataUpdatedObservable: Observable<BalanceData> {
        balanceDataSubject.asObservable()
    }
}

extension XrpAdapter: IDepositAdapter {
    var receiveAddress: DepositAddress {
        XrpDepositAddress(receiveAddress: xrpKit.address, activated: xrpKit.isAccountActivated)
    }

    var receiveAddressPublisher: AnyPublisher<DataStatus<DepositAddress>, Never> {
        receiveAddressSubject.eraseToAnyPublisher()
    }
}

/// Activation state for the receive screen: an account needs its first deposit of at least the base
/// reserve, an issued token needs a trust line. `activationSendData` is the transaction that activates
/// it when the wallet can send one (a TrustSet), nil when only an external deposit can (account).
class XrpDepositAddress: DepositAddress {
    let activated: Bool

    init(receiveAddress: String, activated: Bool) {
        self.activated = activated
        super.init(receiveAddress)
    }
}

struct XrpReserveInfo {
    let baseReserve: Decimal
    let ownerReserve: Decimal
    let ownerCount: Int
    let trustLines: [TrustLine]
    let total: Decimal

    /// Owned objects that are not trust lines (offers, escrows, ...), each costing one increment.
    var otherObjectCount: Int {
        max(0, ownerCount - trustLines.count)
    }
}
