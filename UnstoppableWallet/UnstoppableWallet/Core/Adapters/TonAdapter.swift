import Combine
import Foundation
import HdWalletKit
import RxSwift
import TonKitKmm

class TonAdapter {
    private static let coinRate: Decimal = 1_000_000_000

    private let tonKit: TonKit
    private var cancellables = Set<AnyCancellable>()

    private let balanceStateSubject = PublishSubject<AdapterState>()
    private let balanceDataSubject = PublishSubject<BalanceData>()

    private(set) var balanceState: AdapterState {
        didSet {
            balanceStateSubject.onNext(balanceState)
        }
    }

    private(set) var balanceData: BalanceData {
        didSet {
            balanceDataSubject.onNext(balanceData)
        }
    }

    init(wallet: Wallet) throws {
        guard let seed = wallet.account.type.mnemonicSeed else {
            throw AdapterError.unsupportedAccount
        }

        let hdWallet = HDWallet(seed: seed, coinType: 607, xPrivKey: 0, curve: .ed25519)
        let privateKey = try hdWallet.privateKey(account: 0)

        tonKit = TonKitFactory(driverFactory: DriverFactory()).create(seed: privateKey.raw.toKotlinByteArray())

        balanceState = Self.balanceState(kitSyncState: tonKit.balanceSyncState)
        balanceData = Self.balanceData(kitBalance: tonKit.balance)

        collect(tonKit.balancePublisher)
            .completeOnFailure()
            .sink { [weak self] balance in
                self?.balanceData = Self.balanceData(kitBalance: balance)
            }
            .store(in: &cancellables)

        collect(tonKit.balanceSyncStatePublisher)
            .completeOnFailure()
            .sink { [weak self] syncState in
                self?.balanceState = Self.balanceState(kitSyncState: syncState)
            }
            .store(in: &cancellables)
    }

    private static func balanceState(kitSyncState: AnyObject) -> AdapterState {
        switch kitSyncState {
        case is TonKitKmm.SyncState.Syncing: return .syncing(progress: nil, lastBlockDate: nil)
        case is TonKitKmm.SyncState.Synced: return .synced
        case let notSyncedState as TonKitKmm.SyncState.NotSynced:
            print(notSyncedState.error)
            return .notSynced(error: notSyncedState.error)
        default: return .notSynced(error: AppError.unknownError)
        }
    }

    private static func balanceData(kitBalance: String?) -> BalanceData {
        guard let kitBalance, let decimal = Decimal(string: kitBalance) else {
            return BalanceData(available: 0)
        }

        return BalanceData(available: decimal / coinRate)
    }
}

extension TonAdapter: IBaseAdapter {
    var isMainNet: Bool {
        true
    }
}

extension TonAdapter: IAdapter {
    func start() {
        tonKit.start()
    }

    func stop() {
        tonKit.stop()
    }

    func refresh() {}

    var statusInfo: [(String, Any)] {
        []
    }

    var debugInfo: String {
        ""
    }
}

extension TonAdapter: IBalanceAdapter {
    var balanceStateUpdatedObservable: Observable<AdapterState> {
        balanceStateSubject.asObservable()
    }

    var balanceDataUpdatedObservable: Observable<BalanceData> {
        balanceDataSubject.asObservable()
    }
}

extension TonAdapter: IDepositAdapter {
    var receiveAddress: DepositAddress {
        DepositAddress(tonKit.receiveAddress)
    }
}
