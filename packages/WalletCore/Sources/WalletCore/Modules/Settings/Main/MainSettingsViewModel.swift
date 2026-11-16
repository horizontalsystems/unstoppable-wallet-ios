import Combine
import Foundation
import MarketKit
import RxSwift

class MainSettingsViewModel: ObservableObject {
    private let disposeBag = DisposeBag()
    private var cancellables = Set<AnyCancellable>()

    private let backupManager = Core.shared.backupManager
    private let cloudBackupManager = Core.shared.cloudBackupManager
    private let accountRestoreWarningManager = Core.shared.accountRestoreWarningManager
    private let accountManager = Core.shared.accountManager
    private let contactManager = Core.shared.contactManager
    private let passcodeManager = Core.shared.passcodeManager
    private let systemInfoManager = Core.shared.systemInfoManager
    private let walletConnect = Core.shared.walletConnect
    private let rateAppManager = Core.shared.rateAppManager
    private let localStorage = Core.shared.localStorage
    private let testNetManager = Core.shared.testNetManager
    private let purchaseManager = Core.shared.purchaseManager
    private let brandColorManager = Core.shared.brandColorManager
    private let appStateManager = AppStateManager.instance

    @Published var manageWalletsAlert: Bool = false
    @Published var walletConnectPendingRequestCount: Int = 0
    @Published var securityAlert: Bool = false
    @Published var iCloudUnavailable: Bool = false

    @Published var debu: String?

    let showDevTools: Bool
    let approvedIcons: [String] = ["bitcoin", "wallet_scrutiny", "certik"]

    @Published var forceEnableSwap: Bool {
        didSet {
            localStorage.forceEnableSwap = forceEnableSwap
            appStateManager.sync()
        }
    }

    @Published var emulateEvmSwapSend: Bool {
        didSet {
            localStorage.emulateEvmSwapSend = emulateEvmSwapSend
        }
    }

    @Published var simulateFailSwap: SimulateFailSwapMode {
        didSet {
            localStorage.simulateFailSwap = simulateFailSwap
        }
    }

    @Published var emulatePurchase: Bool {
        didSet {
            localStorage.emulatePurchase = emulatePurchase
            purchaseManager.loadProducts()
            purchaseManager.loadPurchases()
        }
    }

    @Published var testNetEnabled: Bool {
        didSet {
            testNetManager.set(testNetEnabled: testNetEnabled)
        }
    }

    @Published var emulateZcashMigration: Bool {
        didSet {
            localStorage.emulateZcashMigration = emulateZcashMigration

            // turning the toggle off clears the migration-history markers so the flow can be re-run
            if !emulateZcashMigration,
               let token = try? Core.shared.coinManager.token(query: .init(blockchainType: .zcash, tokenType: .native)),
               let adapter = Core.shared.adapterManager.adapter(for: token) as? ZcashAdapter
            {
                adapter.clearMigrationHistory()
            }
        }
    }

    @Published var debuggingAmlResult: MultiSwapViewModel.AmlRiskResult? {
        didSet {
            localStorage.debuggingAmlCheckResult = debuggingAmlResult
        }
    }

    /// Temporary dev switch; replaced by the Appearance brand color picker
    @Published var brandColor: BrandColor {
        didSet {
            brandColorManager.set(brandColor: brandColor)
        }
    }

    init() {
        showDevTools = AppConfig.showDevTools
        forceEnableSwap = localStorage.forceEnableSwap
        emulateEvmSwapSend = localStorage.emulateEvmSwapSend
        simulateFailSwap = localStorage.simulateFailSwap
        emulatePurchase = localStorage.emulatePurchase
        testNetEnabled = testNetManager.testNetEnabled
        emulateZcashMigration = localStorage.emulateZcashMigration
        debuggingAmlResult = localStorage.debuggingAmlCheckResult
        brandColor = brandColorManager.brandColor

        subscribe(MainScheduler.instance, disposeBag, backupManager.allBackedUpObservable) { [weak self] _ in self?.syncManageWalletsAlert() }
        if let walletConnect {
            subscribe(&cancellables, walletConnect.pendingRequestCountPublisher) { [weak self] _ in self?.syncWalletConnectPendingRequestCount() }
        }
        subscribe(&cancellables, contactManager.iCloudErrorPublisher) { [weak self] error in
            if error != nil, self?.contactManager.remoteSync ?? false {
                self?.iCloudUnavailable = true
            } else {
                self?.iCloudUnavailable = false
            }
        }

        subscribe(&cancellables, accountRestoreWarningManager.hasNonStandardPublisher) { [weak self] _ in self?.syncManageWalletsAlert() }
        subscribe(&cancellables, passcodeManager.$isPasscodeSet) { [weak self] _ in self?.syncSecurityAlert() }

        syncManageWalletsAlert()
        syncWalletConnectPendingRequestCount()
        syncSecurityAlert()
    }

    private func syncManageWalletsAlert() {
        manageWalletsAlert = !backupManager.allBackedUp || accountRestoreWarningManager.hasNonStandard
    }

    private func syncWalletConnectPendingRequestCount() {
        walletConnectPendingRequestCount = walletConnect?.pendingRequestCount ?? 0
    }

    private func syncSecurityAlert() {
        securityAlert = !passcodeManager.isPasscodeSet
    }
}

extension MainSettingsViewModel {
    var appVersion: String {
        systemInfoManager.appVersion.description
    }

    func rateApp() {
        rateAppManager.forceShow()
    }
}

extension MainSettingsViewModel {
    enum WalletConnectState {
        case noAccount
        case backedUp
        case nonSupportedAccountType(accountType: AccountType)
        case unBackedUpAccount(account: Account)
    }
}
