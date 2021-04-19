import Foundation
import RxSwift
import RxRelay
import RxCocoa

class MainViewModel {
    private let service: MainService
    private let badgeService: MainBadgeService
    private let whatsNewService: WhatsNewService
    private let disposeBag = DisposeBag()

    private let balanceTabStateRelay = BehaviorRelay<BalanceTabState>(value: .balance)
    private let transactionsTabEnabledRelay = BehaviorRelay<Bool>(value: true)

    init(service: MainService, badgeService: MainBadgeService, whatsNewService: WhatsNewService) {
        self.service = service
        self.badgeService = badgeService
        self.whatsNewService = whatsNewService

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

    var whatsNewDriver: Driver<URL?> {
        whatsNewService
                .whatsNewObservable
                .flatMap { appVersion -> Observable<URL?> in
                    guard let version = appVersion?.version else {
                        return Observable.just(nil)
                    }

                    return Observable.just(URL(string: "https://api.github.com/repos/horizontalsystems/unstoppable-wallet-ios/releases/tags/\(version)"))
                }
                .asDriver(onErrorJustReturn: nil)
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
