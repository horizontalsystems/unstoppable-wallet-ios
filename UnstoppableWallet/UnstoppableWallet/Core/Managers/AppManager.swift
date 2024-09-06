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
    private let blurManager: BlurManager
    private let kitCleaner: KitCleaner
    private let debugBackgroundLogger: DebugLogger?
    private let appVersionManager: AppVersionManager
    private let rateAppManager: RateAppManager
    private let logRecordManager: LogRecordManager
    private let deepLinkManager: DeepLinkManager
    private let evmLabelManager: EvmLabelManager
    private let balanceHiddenManager: BalanceHiddenManager
    private let statManager: StatManager
    private let walletConnectSocketConnectionService: WalletConnectSocketConnectionService
    private let nftMetadataSyncer: NftMetadataSyncer
    private let tonKitManager: TonKitManager

    private let didBecomeActiveSubject = PublishSubject<Void>()
    private let willEnterForegroundSubjectOld = PublishSubject<Void>()
    private let didEnterBackgroundSubject = PassthroughSubject<Void, Never>()
    private let willEnterForegroundSubject = PassthroughSubject<Void, Never>()

    init(accountManager: AccountManager, walletManager: WalletManager, adapterManager: AdapterManager, lockManager: LockManager,
         keychainManager: KeychainManager, passcodeLockManager: PasscodeLockManager, blurManager: BlurManager,
         kitCleaner: KitCleaner, debugLogger: DebugLogger?,
         appVersionManager: AppVersionManager, rateAppManager: RateAppManager,
         logRecordManager: LogRecordManager,
         deepLinkManager: DeepLinkManager, evmLabelManager: EvmLabelManager, balanceHiddenManager: BalanceHiddenManager, statManager: StatManager,
         walletConnectSocketConnectionService: WalletConnectSocketConnectionService, nftMetadataSyncer: NftMetadataSyncer, tonKitManager: TonKitManager)
    {
        self.accountManager = accountManager
        self.walletManager = walletManager
        self.adapterManager = adapterManager
        self.lockManager = lockManager
        self.keychainManager = keychainManager
        self.passcodeLockManager = passcodeLockManager
        self.blurManager = blurManager
        self.kitCleaner = kitCleaner
        debugBackgroundLogger = debugLogger
        self.appVersionManager = appVersionManager
        self.rateAppManager = rateAppManager
        self.logRecordManager = logRecordManager
        self.deepLinkManager = deepLinkManager
        self.evmLabelManager = evmLabelManager
        self.balanceHiddenManager = balanceHiddenManager
        self.statManager = statManager
        self.walletConnectSocketConnectionService = walletConnectSocketConnectionService
        self.nftMetadataSyncer = nftMetadataSyncer
        self.tonKitManager = tonKitManager
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
        debugBackgroundLogger?.logFinishLaunching()

        keychainManager.handleLaunch()
        passcodeLockManager.handleLaunch()
        accountManager.handleLaunch()
        walletManager.preloadWallets()
        kitCleaner.clear()

        rateAppManager.onLaunch()

        evmLabelManager.sync()

        statManager.sendStats()
    }

    func willResignActive() {
        blurManager.willResignActive()
        rateAppManager.onResignActive()
    }

    func didBecomeActive() {
        didBecomeActiveSubject.onNext(())

        blurManager.didBecomeActive()
        rateAppManager.onBecomeActive()
        logRecordManager.onBecomeActive()
    }

    func didEnterBackground() {
        debugBackgroundLogger?.logEnterBackground()

        didEnterBackgroundSubject.send()

        lockManager.didEnterBackground()
        walletConnectSocketConnectionService.didEnterBackground()
        balanceHiddenManager.didEnterBackground()

        tonKitManager.tonKit?.stopListener()
    }

    func willEnterForeground() {
        accountManager.handleForeground()

        blurManager.willEnterForeground()
        debugBackgroundLogger?.logEnterForeground()

        willEnterForegroundSubjectOld.onNext(())
        willEnterForegroundSubject.send()

        passcodeLockManager.handleForeground()
        lockManager.willEnterForeground()
        adapterManager.refresh()
        walletConnectSocketConnectionService.willEnterForeground()

        statManager.sendStats()

        nftMetadataSyncer.sync()

        tonKitManager.tonKit?.startListener()

        AppWidgetConstants.allKinds.forEach { WidgetCenter.shared.reloadTimelines(ofKind: $0) }
    }

    func willTerminate() {
        debugBackgroundLogger?.logTerminate()
    }

    func didReceive(url: URL) -> Bool {
        deepLinkManager.handle(url: url)
    }
}

extension AppManager {
    var didEnterBackgroundPublisher: AnyPublisher<Void, Never> {
        didEnterBackgroundSubject.eraseToAnyPublisher()
    }

    var willEnterForegroundPublisher: AnyPublisher<Void, Never> {
        willEnterForegroundSubject.eraseToAnyPublisher()
    }
}

extension AppManager: IAppManager {
    var didBecomeActiveObservable: Observable<Void> {
        didBecomeActiveSubject.asObservable()
    }

    var willEnterForegroundObservable: Observable<Void> {
        willEnterForegroundSubjectOld.asObservable()
    }
}
