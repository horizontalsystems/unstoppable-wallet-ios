import RxSwift
import RxRelay
import RxCocoa

class MainViewModel {
    private let service: MainService
    private let badgeService: MainBadgeService
    private let disposeBag = DisposeBag()

    private let balanceTabStateRelay = BehaviorRelay<BalanceTabState>(value: .balance)
    private let transactionsTabEnabledRelay = BehaviorRelay<Bool>(value: true)

    init(service: MainService, badgeService: MainBadgeService) {
        self.service = service
        self.badgeService = badgeService

        subscribe(disposeBag, service.hasAccountsObservable) { [weak self] in self?.sync(hasAccounts: $0) }

        sync(hasAccounts: service.hasAccounts)
    }

    private func sync(hasAccounts: Bool) {
        balanceTabStateRelay.accept(hasAccounts ? .balance : .onboarding)
        transactionsTabEnabledRelay.accept(hasAccounts)
    }

}

extension MainViewModel {

    var settingsBadgeDriver: Driver<Bool> {
        badgeService.settingsBadgeObservable.asDriver(onErrorJustReturn: false)
    }

    var balanceTabStateDriver: Driver<BalanceTabState> {
        balanceTabStateRelay.asDriver()
    }

    var transactionsTabEnabledDriver: Driver<Bool> {
        transactionsTabEnabledRelay.asDriver()
    }

    func onLoad() {
        service.setMainShownOnce()
    }

}

extension MainViewModel {

    enum BalanceTabState {
        case balance
        case onboarding
    }

}
