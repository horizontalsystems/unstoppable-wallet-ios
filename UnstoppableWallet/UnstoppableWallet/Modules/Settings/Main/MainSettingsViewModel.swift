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
    private let termsManager = Core.shared.termsManager
    private let systemInfoManager = Core.shared.systemInfoManager
    private let walletConnectSessionManager = Core.shared.walletConnectSessionManager
    private let rateAppManager = Core.shared.rateAppManager
    private let localStorage = Core.shared.localStorage
    private let testNetManager = Core.shared.testNetManager
    private let purchaseManager = Core.shared.purchaseManager

    @Published var manageWalletsAlert: Bool = false
    @Published var walletConnectSessionCount: Int = 0
    @Published var walletConnectPendingRequestCount: Int = 0
    @Published var securityAlert: Bool = false
    @Published var aboutAlert: Bool = false
    @Published var iCloudUnavailable: Bool = false
    @Published var slides: [Slide] = [.premium, .miniApp]
    @Published var introductoryOffer: String?

    let showTestSwitchers: Bool

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

    init() {
        showTestSwitchers = Bundle.main.object(forInfoDictionaryKey: "ShowTestNetSwitcher") as? String == "true"
        emulatePurchase = localStorage.emulatePurchase
        testNetEnabled = testNetManager.testNetEnabled

        subscribe(MainScheduler.instance, disposeBag, backupManager.allBackedUpObservable) { [weak self] _ in self?.syncManageWalletsAlert() }
        subscribe(MainScheduler.instance, disposeBag, walletConnectSessionManager.sessionsObservable) { [weak self] _ in self?.syncWalletConnectSessionCount() }
        subscribe(MainScheduler.instance, disposeBag, walletConnectSessionManager.activePendingRequestsObservable) { [weak self] _ in self?.syncWalletConnectPendingRequestCount() }
        subscribe(MainScheduler.instance, disposeBag, contactManager.iCloudErrorObservable) { [weak self] error in
            if error != nil, self?.contactManager.remoteSync ?? false {
                self?.iCloudUnavailable = true
            } else {
                self?.iCloudUnavailable = false
            }
        }

        subscribe(&cancellables, accountRestoreWarningManager.hasNonStandardPublisher) { [weak self] _ in self?.syncManageWalletsAlert() }
        subscribe(&cancellables, passcodeManager.$isPasscodeSet) { [weak self] _ in self?.syncSecurityAlert() }
        subscribe(&cancellables, termsManager.$termsAccepted) { [weak self] _ in self?.syncAboutAlert() }

        Publishers.Merge3(
            purchaseManager.$purchaseData.map { _ in () },
            purchaseManager.$productData.map { _ in () },
            purchaseManager.$usedOfferProductIds.map { _ in () }
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] in
            self?.syncIntroductoryOffer()
            self?.syncSlides()
        }
        .store(in: &cancellables)

        syncSlides()
        syncIntroductoryOffer()
        syncManageWalletsAlert()
        syncWalletConnectSessionCount()
        syncWalletConnectPendingRequestCount()
        syncSecurityAlert()
        syncAboutAlert()
    }

    private func syncSlides() {
        var slides: [Slide] = [.miniApp]

        if !purchaseManager.hasActivePurchase {
            slides.insert(.premium, at: 0)
        }

        self.slides = slides
    }

    private func syncIntroductoryOffer() {
        introductoryOffer = purchaseManager.introductoryOfferType.title
    }

    private func syncManageWalletsAlert() {
        manageWalletsAlert = !backupManager.allBackedUp || accountRestoreWarningManager.hasNonStandard
    }

    private func syncWalletConnectSessionCount() {
        walletConnectSessionCount = walletConnectSessionManager.sessions.count
    }

    private func syncWalletConnectPendingRequestCount() {
        walletConnectPendingRequestCount = walletConnectSessionManager.activePendingRequests.count
    }

    private func syncSecurityAlert() {
        securityAlert = !passcodeManager.isPasscodeSet
    }

    private func syncAboutAlert() {
        aboutAlert = !termsManager.termsAccepted
    }
}

extension MainSettingsViewModel {
    var appVersion: String {
        systemInfoManager.appVersion.description
    }

    func rateApp() {
        rateAppManager.forceShow()
    }

    func activated(premiumFeature: PremiumFeature) -> Bool {
        purchaseManager.activated(premiumFeature)
    }
}

extension MainSettingsViewModel {
    enum WalletConnectState {
        case noAccount
        case backedUp
        case nonSupportedAccountType(accountType: AccountType)
        case unBackedUpAccount(account: Account)
    }

    enum Slide {
        case premium
        case miniApp
    }
}
