import Foundation
import RxCocoa
import RxRelay
import RxSwift

class MainViewModel {
    private let service: MainService
    private let badgeService: MainBadgeService
    private let releaseNotesService: ReleaseNotesService
    private let jailbreakService: JailbreakService
    private let deepLinkService: DeepLinkService
    private let eventHandler: IEventHandler
    private let disposeBag = DisposeBag()

    private let balanceTabStateRelay = BehaviorRelay<BalanceTabState>(value: .balance)
    private let transactionsTabEnabledRelay = BehaviorRelay<Bool>(value: true)
    private let showMarketRelay = BehaviorRelay<Bool>(value: true)

    private let showReleaseNotesRelay = PublishRelay<URL?>()
    private let showJailbreakRelay = PublishRelay<Void>()
    private let showEventRelay = PublishRelay<Any>()

    init(service: MainService, badgeService: MainBadgeService, releaseNotesService: ReleaseNotesService, jailbreakService: JailbreakService, deepLinkService: DeepLinkService, eventHandler: IEventHandler) {
        self.service = service
        self.badgeService = badgeService
        self.releaseNotesService = releaseNotesService
        self.jailbreakService = jailbreakService
        self.deepLinkService = deepLinkService
        self.eventHandler = eventHandler

        subscribe(disposeBag, service.hasAccountsObservable) { [weak self] in self?.sync(hasAccounts: $0) }
        subscribe(disposeBag, service.hasWalletsObservable) { [weak self] in self?.sync(hasWallets: $0) }
        subscribe(disposeBag, service.showMarketObservable) { [weak self] in self?.sync(showMarket: $0) }
        subscribe(disposeBag, service.handleAlertsObservable) { [weak self] in
            DispatchQueue.main.async {
                self?.handleNextAlert()
            }
        }

        sync(hasAccounts: service.hasAccounts)
    }

    private func sync(hasAccounts: Bool) {
        balanceTabStateRelay.accept(hasAccounts ? .balance : .onboarding)
        transactionsTabEnabledRelay.accept(hasAccounts && service.hasWallets)
    }

    private func sync(hasWallets: Bool) {
        transactionsTabEnabledRelay.accept(service.hasAccounts && hasWallets)
    }

    private func sync(showMarket: Bool) {
        showMarketRelay.accept(showMarket)
    }

    private func handleDeepLink(deepLink: DeepLinkManager.DeepLink) {
        deepLinkService.setDeepLinkShown()
        Task {
            do {
                try await eventHandler.handle(event: deepLink, eventType: .walletConnectDeepLink)
            } catch {
                print("Can't handle Deep Link \(error)")
            }
        }
    }

    func handleNextAlert() {
        if let releaseNotesUrl = releaseNotesService.releaseNotesUrl {
            showReleaseNotesRelay.accept(releaseNotesUrl)
        } else if jailbreakService.needToShowAlert {
            showJailbreakRelay.accept(())
        } else if let deepLink = deepLinkService.deepLink {
            handleDeepLink(deepLink: deepLink)
        }
    }
}

extension MainViewModel {
    var settingsBadgeDriver: Driver<(Bool, Int)> {
        badgeService.settingsBadgeObservable.asDriver(onErrorJustReturn: (false, 0))
    }

    var showMarket: Bool {
        service.showMarket
    }

    var showMarketDriver: Driver<Bool> {
        showMarketRelay.asDriver()
    }

    var showReleaseNotesDriver: Driver<URL?> {
        showReleaseNotesRelay.asDriver(onErrorJustReturn: nil)
    }

    var showJailbreakDriver: Driver<Void> {
        showJailbreakRelay.asDriver(onErrorJustReturn: ())
    }

    var needToShowJailbreakAlert: Bool {
        jailbreakService.needToShowAlert
    }

    var balanceTabState: BalanceTabState {
        service.hasAccounts ? .balance : .onboarding
    }

    var balanceTabStateDriver: Driver<BalanceTabState> {
        balanceTabStateRelay.asDriver()
    }

    var transactionsTabEnabledDriver: Driver<Bool> {
        transactionsTabEnabledRelay.asDriver()
    }

    var initialTab: MainModule.Tab {
        service.initialTab
    }

    func onLoad() {
        service.setMainShownOnce()
    }

    func onSuccessJailbreakAlert() {
        jailbreakService.setAlertShown()
    }

    func onSwitch(tab: MainModule.Tab) {
        service.set(tab: tab)
    }
}

extension MainViewModel {
    enum BalanceTabState {
        case balance
        case onboarding
    }
}
