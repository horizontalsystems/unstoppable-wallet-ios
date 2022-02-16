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
    private let showSessionRequestRelay = PublishRelay<WalletConnectRequest>()

    init(service: MainService, badgeService: MainBadgeService, releaseNotesService: ReleaseNotesService, jailbreakService: JailbreakService, deepLinkService: DeepLinkService) {
        self.service = service
        self.badgeService = badgeService
        self.releaseNotesService = releaseNotesService
        self.jailbreakService = jailbreakService
        self.deepLinkService = deepLinkService

        subscribe(disposeBag, service.hasAccountsObservable) { [weak self] in self?.sync(hasAccounts: $0) }
        subscribe(disposeBag, service.showSessionRequestObservable) { [weak self] in self?.showSession(request: $0) }

        sync(hasAccounts: service.hasAccounts)
    }

    private func sync(hasAccounts: Bool) {
        balanceTabStateRelay.accept(hasAccounts ? .balance : .onboarding)
        transactionsTabEnabledRelay.accept(hasAccounts)
    }

    private func showSession(request: WalletConnectRequest) {
        showSessionRequestRelay.accept(request)
    }

}

extension MainViewModel {

    var settingsBadgeDriver: Driver<Bool> {
        badgeService.settingsBadgeObservable.asDriver(onErrorJustReturn: false)
    }

    var releaseNotesUrlDriver: Driver<URL?> {
        releaseNotesService.releaseNotesUrlObservable.asDriver(onErrorJustReturn: nil)
    }

    var needToShowJailbreakAlert: Bool {
        jailbreakService.needToShowAlert
    }

    var deepLinkDriver: Driver<DeepLinkManager.DeepLink?> {
        deepLinkService.deepLinkObservable.asDriver(onErrorJustReturn: nil)
    }

    var balanceTabStateDriver: Driver<BalanceTabState> {
        balanceTabStateRelay.asDriver()
    }

    var transactionsTabEnabledDriver: Driver<Bool> {
        transactionsTabEnabledRelay.asDriver()
    }

    var showSessionRequestSignal: Signal<WalletConnectRequest> {
        showSessionRequestRelay.asSignal()
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
