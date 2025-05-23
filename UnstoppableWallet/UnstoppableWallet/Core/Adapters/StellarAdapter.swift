import BigInt
import Combine
import Foundation
import RxSwift
import StellarKit
import stellarsdk

class StellarAdapter {
    static let maxValue = Decimal(Int64.max) / 10_000_000
    private static let decimals = 7

    let stellarKit: StellarKit.Kit
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
    private let receiveAddressSubject = PassthroughSubject<DataStatus<DepositAddress>, Never>()

    init?(stellarKit: StellarKit.Kit, asset: StellarKit.Asset) {
        self.stellarKit = stellarKit
        self.asset = asset

        balanceState = Self.adapterState(kitSyncState: stellarKit.syncState)
        balanceData = Self.balanceData(asset: asset, account: stellarKit.account)

        stellarKit.syncStatePublisher
            .sink { [weak self] in self?.balanceState = Self.adapterState(kitSyncState: $0) }
            .store(in: &cancellables)

        stellarKit.accountPublisher
            .sink { [weak self] in
                self?.balanceData = Self.balanceData(asset: asset, account: $0)
                self?.syncReceiveAddress()
            }
            .store(in: &cancellables)
    }

    private func syncReceiveAddress() {
        receiveAddressSubject.send(.completed(receiveAddress))
    }

    private var assetActivated: Bool {
        if asset.isNative {
            return true
        } else {
            return stellarKit.account?.assetBalanceMap[asset] != nil
        }
    }

    private static func balanceData(asset: StellarKit.Asset, account: StellarKit.Account?) -> BalanceData {
        let balance = account?.assetBalanceMap[asset]?.balance ?? 0

        if asset.isNative {
            return StellarBalanceData(
                balance: balance,
                locked: account?.lockedBalance ?? 0,
                assets: account
                    .map { Array($0.assetBalanceMap.keys)
                        .filter { !$0.isNative }
                        .map(\.code).sorted()
                    } ?? []
            )
        } else {
            return BalanceData(available: balance)
        }
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
        StellarDepositAddress(receiveAddress: stellarKit.receiveAddress, assetActivated: assetActivated)
    }

    var receiveAddressPublisher: AnyPublisher<DataStatus<DepositAddress>, Never> {
        receiveAddressSubject.eraseToAnyPublisher()
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

class StellarDepositAddress: DepositAddress {
    let assetActivated: Bool

    init(receiveAddress: String, assetActivated: Bool) {
        self.assetActivated = assetActivated
        super.init(receiveAddress)
    }
}

class StellarBalanceData: BalanceData {
    let locked: Decimal
    let assets: [String]

    init(balance: Decimal, locked: Decimal, assets: [String]) {
        self.locked = locked
        self.assets = assets
        super.init(available: balance - locked)
    }

    enum CodingKeys: String, CodingKey {
        case locked, assets
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        locked = try container.decode(Decimal.self, forKey: .locked)
        assets = try container.decode([String].self, forKey: .assets)

        try super.init(from: decoder)
    }

    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)

        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(locked, forKey: .locked)
        try container.encode(assets, forKey: .assets)
    }

    override var balanceTotal: Decimal {
        super.balanceTotal + locked
    }

    override var customStates: [CustomState] {
        var states = super.customStates
        if !locked.isZero {
            var description = "\("balance.token.locked.stellar.description".localized)\n\n\("balance.token.locked.stellar.description.currently_locked".localized)\n • 1 XLM - \("balance.token.locked.stellar.description.wallet_activation".localized)"

            for asset in assets {
                description += "\n • 0.5 XLM - \(asset)"
            }

            states.append(
                CustomState(
                    title: "balance.token.locked".localized,
                    value: locked,
                    infoTitle: "balance.token.locked.stellar.title".localized,
                    infoDescription: description
                )
            )
        }
        return states
    }

    static func == (lhs: StellarBalanceData, rhs: StellarBalanceData) -> Bool {
        lhs.available == rhs.available && lhs.locked == rhs.locked
    }
}
