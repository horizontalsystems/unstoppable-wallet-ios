import RxSwift
import RxRelay
import RxCocoa

class AppearanceViewModel {
    private let service: AppearanceService
    private let disposeBag = DisposeBag()

    private let themeModeViewItemsRelay = BehaviorRelay<[ViewItem]>(value: [])
    private let launchScreenViewItemsRelay = BehaviorRelay<[ViewItem]>(value: [])

    init(service: AppearanceService) {
        self.service = service

        subscribe(disposeBag, service.themeModeItemsObservable) { [weak self] in self?.sync(themeModeItems: $0) }
        subscribe(disposeBag, service.launchScreenItemsObservable) { [weak self] in self?.sync(launchScreenItems: $0) }

        sync(themeModeItems: service.themeModeItems)
        sync(launchScreenItems: service.launchScreenItems)
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

}

extension AppearanceViewModel {

    var themeModeViewItemsDriver: Driver<[ViewItem]> {
        themeModeViewItemsRelay.asDriver()
    }

    var launchScreenViewItemsDriver: Driver<[ViewItem]> {
        launchScreenViewItemsRelay.asDriver()
    }

    func onSelectThemeMode(index: Int) {
        service.setThemeMode(index: index)
    }

    func onSelectLaunchScreen(index: Int) {
        service.setLaunchScreen(index: index)
    }

}

extension AppearanceViewModel {

    struct ViewItem {
        let iconName: String
        let title: String
        let selected: Bool
    }

}
