import BigInt
import Combine
import Foundation
import RxSwift
import StellarKit
import stellarsdk

class StellarAdapter {
    static let maxValue = Decimal(Int64.max) / 10000000
    private static let decimals = 7

    private let stellarKit: StellarKit.Kit
    let asset: StellarKit.Asset
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

    private let transactionRecordsSubject = PublishSubject<[TonTransactionRecord]>()

    init?(stellarKit: StellarKit.Kit, asset: StellarKit.Asset) {
        self.stellarKit = stellarKit
        self.asset = asset

        balanceState = Self.adapterState(kitSyncState: stellarKit.syncState)
        balanceData = BalanceData(available: stellarKit.assetBalances[asset] ?? 0)

        stellarKit.syncStatePublisher
            .sink { [weak self] in self?.balanceState = Self.adapterState(kitSyncState: $0) }
            .store(in: &cancellables)

        stellarKit.assetBalancePublisher
            .sink { [weak self] in self?.balanceData = BalanceData(available: $0[asset] ?? 0) }
            .store(in: &cancellables)
    }
}

extension StellarAdapter: IBaseAdapter {
    var isMainNet: Bool {
        true
    }
}

extension StellarAdapter: IAdapter {
    func start() {
        // started via StellarKitManager
    }

    func stop() {
        // stopped via StellarKitManager
    }

    func refresh() {
        // refreshed via StellarKitManager
    }

    var statusInfo: [(String, Any)] {
        [
            ("Sync State", "\(stellarKit.syncState)"),
            ("Operation Sync State", "\(stellarKit.operationSyncState)"),
        ]
    }

    var debugInfo: String {
        ""
    }
}

extension StellarAdapter: IBalanceAdapter {
    var balanceStateUpdatedObservable: Observable<AdapterState> {
        balanceStateSubject.asObservable()
    }

    var balanceDataUpdatedObservable: Observable<BalanceData> {
        balanceDataSubject.asObservable()
    }
}

extension StellarAdapter: IDepositAdapter {
    var receiveAddress: DepositAddress {
        DepositAddress(stellarKit.receiveAddress)
    }
}

extension StellarAdapter {
    func paymentOperations(recipient: String, amount: Decimal) throws -> [stellarsdk.Operation] {
        try stellarKit.paymentOperations(asset: asset, destinationAccountId: recipient, amount: amount)
    }
}

extension StellarAdapter {
    private static func adapterState(kitSyncState: StellarKit.SyncState) -> AdapterState {
        switch kitSyncState {
        case .syncing: return .syncing(progress: nil, lastBlockDate: nil)
        case .synced: return .synced
        case let .notSynced(error): return .notSynced(error: error)
        }
    }
}
