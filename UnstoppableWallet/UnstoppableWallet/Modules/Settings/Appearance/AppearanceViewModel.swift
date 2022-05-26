import RxSwift
import RxRelay
import RxCocoa

class AppearanceViewModel {
    private let service: AppearanceService
    private let disposeBag = DisposeBag()

    private let themeModeViewItemsRelay = BehaviorRelay<[ViewItem]>(value: [])
    private let launchScreenViewItemsRelay = BehaviorRelay<[ViewItem]>(value: [])
    private let balanceValueViewItemsRelay = BehaviorRelay<[BalanceValueViewItem]>(value: [])

    init(service: AppearanceService) {
        self.service = service

        subscribe(disposeBag, service.themeModeItemsObservable) { [weak self] in self?.sync(themeModeItems: $0) }
        subscribe(disposeBag, service.launchScreenItemsObservable) { [weak self] in self?.sync(launchScreenItems: $0) }
        subscribe(disposeBag, service.balancePrimaryValueItemsObservable) { [weak self] in self?.sync(balancePrimaryValueItems: $0) }

        sync(themeModeItems: service.themeModeItems)
        sync(launchScreenItems: service.launchScreenItems)
        sync(balancePrimaryValueItems: service.balancePrimaryValueItems)
    }

    private func sync(themeModeItems: [AppearanceService.ThemeModeItem]) {
        let viewItems = themeModeItems.map { item in
            ViewItem(
                    iconName: item.themeMode.iconName,
                    title: item.themeMode.title,
                    selected: item.current
            )
        }
        themeModeViewItemsRelay.accept(viewItems)
    }

    private func sync(launchScreenItems: [AppearanceService.LaunchScreenItem]) {
        let viewItems = launchScreenItems.map { item in
            ViewItem(
                    iconName: item.launchScreen.iconName,
                    title: item.launchScreen.title,
                    selected: item.current
            )
        }
        launchScreenViewItemsRelay.accept(viewItems)
    }

    private func sync(balancePrimaryValueItems: [AppearanceService.BalancePrimaryValueItem]) {
        let viewItems = balancePrimaryValueItems.map { item in
            BalanceValueViewItem(
                    title: item.value.title,
                    subtitle: item.value.subtitle,
                    selected: item.current
            )
        }
        balanceValueViewItemsRelay.accept(viewItems)
    }

}

extension AppearanceViewModel {

    var themeModeViewItemsDriver: Driver<[ViewItem]> {
        themeModeViewItemsRelay.asDriver()
    }

    var launchScreenViewItemsDriver: Driver<[ViewItem]> {
        launchScreenViewItemsRelay.asDriver()
    }

    var balanceValueViewItemsDriver: Driver<[BalanceValueViewItem]> {
        balanceValueViewItemsRelay.asDriver()
    }

    func onSelectThemeMode(index: Int) {
        service.setThemeMode(index: index)
    }

    func onSelectLaunchScreen(index: Int) {
        service.setLaunchScreen(index: index)
    }

    func onSelectBalanceValue(index: Int) {
        service.setBalancePrimaryValue(index: index)
    }

}

extension AppearanceViewModel {

    struct ViewItem {
        let iconName: String
        let title: String
        let selected: Bool
    }

    struct BalanceValueViewItem {
        let title: String
        let subtitle: String
        let selected: Bool
    }

}
