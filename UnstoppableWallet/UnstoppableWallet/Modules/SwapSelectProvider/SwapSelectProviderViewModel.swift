import RxSwift
import RxRelay
import RxCocoa
import CoinKit

class SwapSelectProviderViewModel {
    private let service: SwapSelectProviderService
    private let disposeBag = DisposeBag()

    private let sectionViewItemsRelay = BehaviorRelay<[ViewItem]>(value: [])

    private var currentIndices: (sectionIndex: Int, index: Int)?

    init(service: SwapSelectProviderService) {
        self.service = service

        service.itemsObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onNext: { [weak self] items in
                    self?.sync(items: items)
                })
                .disposed(by: disposeBag)

        sync(items: service.items)
    }

    private func sync(items: [SwapSelectProviderService.Item]) {
        let viewItems = items.map { item in
            ViewItem(
                    title: item.provider.rawValue,
                    icon: item.provider.icon,
                    selected: item.selected
            )
        }

        sectionViewItemsRelay.accept(viewItems)
    }

}

extension SwapSelectProviderViewModel {

    var sectionViewItemsDriver: Driver<[ViewItem]> {
        sectionViewItemsRelay.asDriver()
    }

    func onSelect(index: Int) {
        service.set(provider: service.items[index].provider)
    }

}

extension SwapSelectProviderViewModel {

    struct ViewItem {
        let title: String
        let icon: String
        let selected: Bool
    }

}

extension SwapModuleNew.DexNew.Provider {

    var icon: String {
        switch self {
        case .oneInch: return "one-inch-logo"
        case .uniswap: return "uniswap-logo"
        case .pancake: return "pancake-logo"
        }
    }

}