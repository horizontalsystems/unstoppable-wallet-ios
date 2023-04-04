//import Foundation
//import RxSwift
//import MarketKit
//import ZcashLightClientKit
//
//class ZCashAdapterNew {
//    private let serialScheduler = SerialDispatchQueueScheduler(qos: .utility)
//    private let disposeBag = DisposeBag()
//
//    private let token: Token
//
//    private let transactionSource: TransactionSource
//    private let saplingDownloader = DownloadService(queueLabel: "io.SaplingDownloader")
//
//    private let rxSynchronizer: RxSDKSynchronizer
//    private let closureSynchronizer: ClosureSynchronizer
//
//    private var address: UnifiedAddress?
//
//    private let uniqueId: String
//    private let birthday: BlockHeight
//    private let spendingKey: UnifiedSpendingKey // this being a single account does not need to be an array
//
//    private(set) var network: ZcashNetwork
//    private(set) var fee: Decimal
//
//    private let lastBlockUpdatedSubject = PublishSubject<Void>()
//    private let balanceStateSubject = PublishSubject<AdapterState>()
//    private let balanceSubject = PublishSubject<BalanceData>()
//    private let transactionRecordsSubject = PublishSubject<[TransactionRecord]>()
//
//    private var synchronizerState: SynchronizerState? {
//        didSet {
//            print("Did set syncState: \(synchronizerState)")
//            print(" let latestScannedBlock = \(synchronizerState?.latestScannedHeight ?? 0)")
//
//            lastBlockUpdatedSubject.onNext(())
//            balanceSubject.onNext(_balanceData)
//        }
//    }
//
//    // IBalanceAdapter
//    private var _balanceData: BalanceData {
//        guard let synchronizerState = synchronizerState else {
//            return BalanceData(balance: 0)
//        }
//
//        let verifiedBalance: Zatoshi = synchronizerState.shieldedBalance.verified
//        let balance: Zatoshi = synchronizerState.shieldedBalance.total
//        let diff = balance - verifiedBalance
//
//        return BalanceData(
//                balance: verifiedBalance.decimalValue.decimalValue,
//                balanceLocked: diff.decimalValue.decimalValue
//        )
//    }
//
//    var balanceState: AdapterState {
//        state.adapterState
//    }
//
//    private(set) var state: ZCashAdapterState {
//        didSet {
//            balanceStateSubject.onNext(balanceState)
//            syncing = balanceState.syncing
//        }
//    }
//
//    // ITransactionsAdapter
//    private(set) var syncing: Bool = true
//
//
//    // Helpers
//    private func defaultFee(network: ZcashNetwork, height: Int? = nil) -> Zatoshi {
//        let fee: Zatoshi
//        if let lastBlockHeight = height {
//            fee = network.constants.defaultFee(for: lastBlockHeight)
//        } else {
//            fee = network.constants.defaultFee()
//        }
//        return fee
//    }
//
//    private func defaultFeeDecimal(network: ZcashNetwork, height: Int? = nil) -> Decimal {
//        defaultFee(network: network, height: height).decimalValue.decimalValue
//    }
//
//    init(wallet: Wallet, restoreSettings: RestoreSettings) throws {
//        guard let seed = wallet.account.type.mnemonicSeed else {
//            throw AdapterError.unsupportedAccount
//        }
//
//        network = ZcashNetworkBuilder.network(for: .mainnet)
//        fee = network.constants.defaultFee().decimalValue.decimalValue
//
//        let endPoint = "lightwalletd.electriccoin.co" //"mainnet.lightwalletd.com"
//
//        token = wallet.token
//        transactionSource = wallet.transactionSource
//        uniqueId = wallet.account.id
//
//        switch wallet.account.origin {
//        case .created: birthday = Self.newBirthdayHeight(network: network)
//        case .restored:
//            if let height = restoreSettings.birthdayHeight {
//                birthday = max(height, network.constants.saplingActivationHeight)
//            } else {
//                birthday = network.constants.saplingActivationHeight
//            }
//        }
//
//        let seedData = [UInt8](seed)
//        let derivationTool = DerivationTool(networkType: network.networkType)
//
//        guard let unifiedSpendingKey =  try? derivationTool.deriveUnifiedSpendingKey(seed: seedData, accountIndex: 0),
//              let unifiedViewingKey = try? unifiedSpendingKey.deriveFullViewingKey() else {
//            throw AppError.ZcashError.noReceiveAddress
//        }
//
//        let initializer = Initializer(
//                cacheDbURL: nil,
//                fsBlockDbRoot: try ZcashAdapter.fsBlockDbRootURL(uniqueId: uniqueId, network: network),
//                dataDbURL: try ZcashAdapter.dataDbURL(uniqueId: uniqueId, network: network),
//                pendingDbURL: try ZcashAdapter.pendingDbURL(uniqueId: uniqueId, network: network),
//                endpoint: LightWalletEndpoint(address: endPoint, port: 9067, secure: true, streamingCallTimeoutInMillis: 10 * 60 * 60 * 1000),
//                network: network,
//                spendParamsURL: try ZcashAdapter.spendParamsURL(uniqueId: uniqueId),
//                outputParamsURL: try ZcashAdapter.outputParamsURL(uniqueId: uniqueId),
//                saplingParamsSourceURL: SaplingParamsSourceURL.default,
//                alias: .default,
//                logLevel: .debug
//        )
//
//        spendingKey = unifiedSpendingKey
//
//        let synchronizer = SDKSynchronizer(initializer: initializer)
//        rxSynchronizer = RxSDKSynchronizer(synchronizer: synchronizer)
//        closureSynchronizer = ClosureSDKSynchronizer(synchronizer: synchronizer)
//
//        rxSynchronizer
//                .stateStreamObservable
//                .observeOn(serialScheduler)
//                .subscribe { [weak self] state in
//                    self?.sync(state: state)
//                }
//                .disposed(by: disposeBag)
//
//        rxSynchronizer
//                .eventStreamObservable
//                .observeOn(serialScheduler)
//                .subscribe { [weak self] event in
//                    self?.sync(event: event)
//                }
//                .disposed(by: disposeBag)
//
//        state = .preparing
//        prepare(
//                seedData: seedData,
//                viewingKeys: [unifiedViewingKey],
//                walletBirthday: birthday) { [weak self] result in
//            switch result {
//            case .success:
//                self?.finishPreparing()
//            case .failure(let error):
//                self?.state = .notSynced(error: error)
//            }
//        }
//    }
//
//    deinit {
//        NotificationCenter.default.removeObserver(self)
//        closureSynchronizer.stop {
//            print("Syncronizer was stopped")
//        }
//    }
//
//}
//
//extension ZcashAdapterNew {
//    public static func newBirthdayHeight(network: ZcashNetwork) -> Int {
//        BlockHeight.ofLatestCheckpoint(network: network)
//    }
//
//    private static func dataDirectoryUrl() throws -> URL {
//        let fileManager = FileManager.default
//
//        let url = try fileManager
//                .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
//                .appendingPathComponent("z-cash-kit", isDirectory: true)
//
//        try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
//
//        return url
//    }
//
//    private static func fsBlockDbRootURL(uniqueId: String, network: ZcashNetwork) throws -> URL {
//        try dataDirectoryUrl().appendingPathComponent(network.networkType.chainName + uniqueId + ZcashSDK.defaultFsCacheName, isDirectory: true)
//    }
//
//    private static func cacheDbURL(uniqueId: String, network: ZcashNetwork) throws -> URL {
//        try dataDirectoryUrl().appendingPathComponent(network.constants.defaultDbNamePrefix + uniqueId + ZcashSDK.defaultCacheDbName, isDirectory: false)
//    }
//
//    private static func dataDbURL(uniqueId: String, network: ZcashNetwork) throws -> URL {
//        try dataDirectoryUrl().appendingPathComponent(network.constants.defaultDbNamePrefix + uniqueId + ZcashSDK.defaultDataDbName, isDirectory: false)
//    }
//
//    private static func pendingDbURL(uniqueId: String, network: ZcashNetwork) throws -> URL {
//        try dataDirectoryUrl().appendingPathComponent(network.constants.defaultDbNamePrefix + uniqueId + ZcashSDK.defaultPendingDbName, isDirectory: false)
//    }
//
//    private static func spendParamsURL(uniqueId: String) throws -> URL {
//        try dataDirectoryUrl().appendingPathComponent("sapling-spend_\(uniqueId).params")
//    }
//
//    private static func outputParamsURL(uniqueId: String) throws -> URL {
//        try dataDirectoryUrl().appendingPathComponent("sapling-output_\(uniqueId).params")
//    }
//
//    public static func clear(except excludedWalletIds: [String]) throws {
//        let fileManager = FileManager.default
//        let fileUrls = try fileManager.contentsOfDirectory(at: dataDirectoryUrl(), includingPropertiesForKeys: nil)
//
//        for filename in fileUrls {
//            if !excludedWalletIds.contains(where: { filename.lastPathComponent.contains($0) }) {
//                try fileManager.removeItem(at: filename)
//            }
//        }
//    }
//
//}
