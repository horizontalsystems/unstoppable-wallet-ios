import RxSwift
import RxRelay
import RxCocoa

class MainViewModel {
    private let showService: MainShowService
    private let badgeService: MainBadgeService

    init(showService: MainShowService, badgeService: MainBadgeService) {
        self.showService = showService
        self.badgeService = badgeService
    }

    func onLoad() {
        showService.setMainShownOnce()
    }

    var settingsBadgeDriver: Driver<Bool> {
        badgeService.settingsBadgeObservable.asDriver(onErrorJustReturn: false)
    }

}
