import Combine
import Foundation
import RxSwift
import UIKit
import WidgetKit

class AppManager {
    private let accountManager: AccountManager
    private let walletManager: WalletManager
    private let adapterManager: AdapterManager
    private let lockManager: LockManager
    private let keychainManager: KeychainManager
    private let passcodeLockManager: PasscodeLockManager
    private let coverManager: CoverManager
    private let kitCleaner: KitCleaner
    private let appVersionManager: AppVersionManager
    private let rateAppManager: RateAppManager
    private let logRecordManager: LogRecordManager
    private let deeplinkStorage: DeeplinkStorage
    private let evmLabelManager: EvmLabelManager
    private let balanceHiddenManager: BalanceHiddenManager
    private let statManager: StatManager
    private let walletConnectSocketConnectionService: WalletConnectSocketConnectionService
    private let nftMetadataSyncer: NftMetadataSyncer
    private let tonKitManager: TonKitManager
    private let stellarKitManager: StellarKitManager

    private let didBecomeActiveSubjectOld = PublishSubject<Void>()
    private let willEnterForegroundSubjectOld = PublishSubject<Void>()

    private let didBecomeActiveSubject = PassthroughSubject<Void, Never>()
    private let willResignActiveSubject = PassthroughSubject<Void, Never>()
    private let didEnterBackgroundSubject = PassthroughSubject<Void, Never>()
    private let willEnterForegroundSubject = PassthroughSubject<Void, Never>()

    init(accountManager: AccountManager, walletManager: WalletManager, adapterManager: AdapterManager, lockManager: LockManager,
         keychainManager: KeychainManager, passcodeLockManager: PasscodeLockManager,
         kitCleaner: KitCleaner, coverManager: CoverManager,
         appVersionManager: AppVersionManager, rateAppManager: RateAppManager,
         logRecordManager: LogRecordManager, deeplinkStorage: DeeplinkStorage,
         evmLabelManager: EvmLabelManager, balanceHiddenManager: BalanceHiddenManager, statManager: StatManager,
         walletConnectSocketConnectionService: WalletConnectSocketConnectionService, nftMetadataSyncer: NftMetadataSyncer, tonKitManager: TonKitManager,
         stellarKitManager: StellarKitManager)
    {
        self.accountManager = accountManager
        self.walletManager = walletManager
        self.adapterManager = adapterManager
        self.lockManager = lockManager
        self.keychainManager = keychainManager
        self.passcodeLockManager = passcodeLockManager
        self.kitCleaner = kitCleaner
        self.coverManager = coverManager
        self.appVersionManager = appVersionManager
        self.rateAppManager = rateAppManager
        self.logRecordManager = logRecordManager
        self.deeplinkStorage = deeplinkStorage
        self.evmLabelManager = evmLabelManager
        self.balanceHiddenManager = balanceHiddenManager
        self.statManager = statManager
        self.walletConnectSocketConnectionService = walletConnectSocketConnectionService
        self.nftMetadataSyncer = nftMetadataSyncer
        self.tonKitManager = tonKitManager
        self.stellarKitManager = stellarKitManager
    }

    private func warmUp() {
        DispatchQueue.global(qos: .userInitiated).async {
            _ = UIImage.qrCodeImage(qrCodeString: "", size: .margin48)
        }
    }
}

extension AppManager {
    func didFinishLaunching() {
        warmUp()

        keychainManager.handleLaunch()
        accountManager.handleLaunch()
        walletManager.preloadWallets()
        kitCleaner.clear()

        rateAppManager.onLaunch()

        evmLabelManager.sync()

        statManager.sendStats()
    }

    func willResignActive() {
        willResignActiveSubject.send()

        coverManager.willResignActive()
        rateAppManager.onResignActive()
    }

    func didBecomeActive() {
        didBecomeActiveSubject.send()
        didBecomeActiveSubjectOld.onNext(())

        coverManager.didBecomeActive()
        rateAppManager.onBecomeActive()
        logRecordManager.onBecomeActive()
    }

    func didEnterBackground() {
        didEnterBackgroundSubject.send()

        lockManager.didEnterBackground()
        walletConnectSocketConnectionService.didEnterBackground()
        balanceHiddenManager.didEnterBackground()

        tonKitManager.tonKit?.stopListener()
        stellarKitManager.stellarKit?.stopListener()
    }

    func willEnterForeground() {
        accountManager.handleForeground()

        willEnterForegroundSubject.send()
        willEnterForegroundSubjectOld.onNext(())

        coverManager.willEnterForeground()
        passcodeLockManager.handleForeground()
        lockManager.willEnterForeground()
        adapterManager.refresh()
        walletConnectSocketConnectionService.willEnterForeground()

        statManager.sendStats()

        nftMetadataSyncer.sync()

        tonKitManager.tonKit?.startListener()
        stellarKitManager.stellarKit?.startListener()

        AppWidgetConstants.allKinds.forEach { WidgetCenter.shared.reloadTimelines(ofKind: $0) }
    }

    func didReceive(url: URL) {
        deeplinkStorage.deepLinkUrl = url
    }
}

extension AppManager {
    var didBecomeActivePublisher: AnyPublisher<Void, Never> {
        didBecomeActiveSubject.eraseToAnyPublisher()
    }

    var willResignActivePublisher: AnyPublisher<Void, Never> {
        willResignActiveSubject.eraseToAnyPublisher()
    }

    var didEnterBackgroundPublisher: AnyPublisher<Void, Never> {
        didEnterBackgroundSubject.eraseToAnyPublisher()
    }

    var willEnterForegroundPublisher: AnyPublisher<Void, Never> {
        willEnterForegroundSubject.eraseToAnyPublisher()
    }
}

extension AppManager: IAppManager {
    var didBecomeActiveObservable: Observable<Void> {
        didBecomeActiveSubjectOld.asObservable()
    }

    var willEnterForegroundObservable: Observable<Void> {
        willEnterForegroundSubjectOld.asObservable()
    }
}
