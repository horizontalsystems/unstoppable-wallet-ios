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
    private let walletConnectSocketConnectionService: WalletConnectSocketConnectionService
    private let nftMetadataSyncer: NftMetadataSyncer

    private let didBecomeActiveSubject = PublishSubject<Void>()
    private let willEnterForegroundSubject = PublishSubject<Void>()

    init(accountManager: AccountManager, walletManager: WalletManager, adapterManager: AdapterManager, lockManager: LockManager,
         keychainManager: KeychainManager, passcodeLockManager: PasscodeLockManager, blurManager: BlurManager,
         kitCleaner: KitCleaner, debugLogger: DebugLogger?,
         appVersionManager: AppVersionManager, rateAppManager: RateAppManager,
         logRecordManager: LogRecordManager,
         deepLinkManager: DeepLinkManager, evmLabelManager: EvmLabelManager, balanceHiddenManager: BalanceHiddenManager,
         walletConnectSocketConnectionService: WalletConnectSocketConnectionService, nftMetadataSyncer: NftMetadataSyncer)
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
        self.walletConnectSocketConnectionService = walletConnectSocketConnectionService
        self.nftMetadataSyncer = nftMetadataSyncer
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

        lockManager.didEnterBackground()
        walletConnectSocketConnectionService.didEnterBackground()
        balanceHiddenManager.didEnterBackground()
    }

    func willEnterForeground() {
        accountManager.handleForeground()

        blurManager.willEnterForeground()
        debugBackgroundLogger?.logEnterForeground()
        willEnterForegroundSubject.onNext(())

        passcodeLockManager.handleForeground()
        lockManager.willEnterForeground()
        adapterManager.refresh()
        walletConnectSocketConnectionService.willEnterForeground()

        nftMetadataSyncer.sync()

        AppWidgetConstants.allKinds.forEach { WidgetCenter.shared.reloadTimelines(ofKind: $0) }
    }

    func willTerminate() {
        debugBackgroundLogger?.logTerminate()
    }

    func didReceive(url: URL) -> Bool {
        deepLinkManager.handle(url: url)
    }
}

extension AppManager: IAppManager {
    var didBecomeActiveObservable: Observable<Void> {
        didBecomeActiveSubject.asObservable()
    }

    var willEnterForegroundObservable: Observable<Void> {
        willEnterForegroundSubject.asObservable()
    }
}
