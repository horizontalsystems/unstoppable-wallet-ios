import Foundation
import RxSwift
import RxRelay
import RxCocoa

class MainViewModel {
    private let service: MainService
    private let badgeService: MainBadgeService
    private let releaseNotesService: ReleaseNotesService
    private let jailbreakService: JailbreakService
    private let deepLinkService: DeepLinkService
    private let disposeBag = DisposeBag()

    private let balanceTabStateRelay = BehaviorRelay<BalanceTabState>(value: .balance)
    private let transactionsTabEnabledRelay = BehaviorRelay<Bool>(value: true)
    private let showMarketRelay = BehaviorRelay<Bool>(value: true)

    init(service: MainService, badgeService: MainBadgeService, releaseNotesService: ReleaseNotesService, jailbreakService: JailbreakService, deepLinkService: DeepLinkService) {
        self.service = service
        self.badgeService = badgeService
        self.releaseNotesService = releaseNotesService
        self.jailbreakService = jailbreakService
        self.deepLinkService = deepLinkService

        subscribe(disposeBag, service.hasAccountsObservable) { [weak self] in self?.sync(hasAccounts: $0) }
        subscribe(disposeBag, service.hasWalletsObservable) { [weak self] in self?.sync(hasWallets: $0) }
        subscribe(disposeBag, service.showMarketObservable) { [weak self] in self?.sync(showMarket: $0) }

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

}

extension MainViewModel {

    var settingsBadgeDriver: Driver<(Bool, Int)> {
        badgeService.settingsBadgeObservable.asDriver(onErrorJustReturn: (false, 0))
    }

    var releaseNotesUrlDriver: Driver<URL?> {
        releaseNotesService.releaseNotesUrlObservable.asDriver(onErrorJustReturn: nil)
    }

    var showMarket: Bool {
        service.showMarket
    }

    var showMarketDriver: Driver<Bool> {
        showMarketRelay.asDriver()
    }

    var needToShowJailbreakAlert: Bool {
        jailbreakService.needToShowAlert
    }

    var deepLinkDriver: Driver<DeepLinkManager.DeepLink?> {
        deepLinkService.deepLinkObservable.asDriver(onErrorJustReturn: nil)
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
