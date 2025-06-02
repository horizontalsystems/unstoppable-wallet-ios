import Combine
import Foundation
import MarketKit
import RxSwift

class MainSettingsViewModel: ObservableObject {
    private let disposeBag = DisposeBag()
    private var cancellables = Set<AnyCancellable>()

    private let backupManager = App.shared.backupManager
    private let cloudBackupManager = App.shared.cloudBackupManager
    private let accountRestoreWarningManager = App.shared.accountRestoreWarningManager
    private let accountManager = App.shared.accountManager
    private let contactManager = App.shared.contactManager
    private let passcodeManager = App.shared.passcodeManager
    private let termsManager = App.shared.termsManager
    private let systemInfoManager = App.shared.systemInfoManager
    private let walletConnectSessionManager = App.shared.walletConnectSessionManager
    private let rateAppManager = App.shared.rateAppManager
    private let localStorage = App.shared.localStorage
    private let testNetManager = App.shared.testNetManager
    private let purchaseManager = App.shared.purchaseManager

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

        Publishers.CombineLatest3(purchaseManager.$purchaseData, purchaseManager.$productData, purchaseManager.$usedOfferProductIds)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _, _, _ in self?.syncSlides() }
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
        introductoryOffer = title(introductoryOfferType: purchaseManager.introductoryOfferType)
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

    private func title(introductoryOfferType: PurchaseManager.IntroductoryOfferType) -> String? {
        switch introductoryOfferType {
        case .none: return nil
        case .trial: return "premium.cell.try".localized
        case .discount: return "premium.cell.discount".localized
        }
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
