import RxSwift
import RxRelay
import RxCocoa

class ThemeSettingsViewModel {
    private let service: ThemeSettingsService
    private let disposeBag = DisposeBag()

    private let sectionViewItemsRelay = BehaviorRelay<[ViewItem]>(value: [])

    private var currentIndices: (sectionIndex: Int, index: Int)?

    init(service: ThemeSettingsService) {
        self.service = service

        service.itemsObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onNext: { [weak self] items in
                    self?.sync(items: items)
                })
                .disposed(by: disposeBag)

        sync(items: service.items)
    }

    private func sync(items: [ThemeSettingsService.Item]) {
        let viewItems = items.map { item in
            ViewItem(
                    title: item.themeMode.description,
                    icon: item.themeMode.iconName,
                    selected: item.selected
            )
        }

        sectionViewItemsRelay.accept(viewItems)
    }

}

extension ThemeSettingsViewModel {

    var sectionViewItemsDriver: Driver<[ViewItem]> {
        sectionViewItemsRelay.asDriver()
    }

    func onSelect(index: Int) {
        service.set(themeMode: service.items[index].themeMode)
    }

}

extension ThemeSettingsViewModel {

    struct ViewItem {
        let title: String
        let icon: String
        let selected: Bool
    }

}
