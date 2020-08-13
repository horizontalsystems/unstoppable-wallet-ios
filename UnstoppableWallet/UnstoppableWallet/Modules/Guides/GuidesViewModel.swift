import Foundation
import RxSwift
import RxCocoa

class GuidesViewModel {
    private let disposeBag = DisposeBag()

    private let service: GuidesService

    private var filterViewItemsRelay = BehaviorRelay<[String]>(value: [])
    private var viewItemsRelay = BehaviorRelay<[GuideViewItem]>(value: [])
    private var loadingRelay = BehaviorRelay<Bool>(value: true)
    private var errorRelay = BehaviorRelay<Error?>(value: nil)

    private var categories = [GuideCategoryItem]()
    private var currentCategoryIndex: Int = 0

    init(service: GuidesService) {
        self.service = service

        service.categories
                .subscribe(onNext: { [weak self] dataState in
                    self?.handle(dataState: dataState)
                })
                .disposed(by: disposeBag)
    }

    private func handle(dataState: DataState<[GuideCategoryItem]>) {
        if case .loading = dataState {
            loadingRelay.accept(true)
        } else {
            loadingRelay.accept(false)
        }

        if case .success(let categories) = dataState {
            self.categories = categories

            filterViewItemsRelay.accept(categories.map { $0.title })

            syncViewItems()
        }

        if case .error(let error) = dataState {
            errorRelay.accept(error.convertedError)
        } else {
            errorRelay.accept(nil)
        }
    }

    private func syncViewItems() {
        guard categories.count > currentCategoryIndex else {
            return
        }

        let viewItems = categories[currentCategoryIndex].items.map { item in
            GuideViewItem(
                    title: item.title,
                    date: item.date,
                    imageUrl: item.imageUrl,
                    url: item.url
            )
        }

        viewItemsRelay.accept(viewItems)
    }
}

extension GuidesViewModel: IGuidesViewModel {

    var filters: Driver<[String]> {
        filterViewItemsRelay.asDriver()
    }

    var viewItems: Driver<[GuideViewItem]> {
        viewItemsRelay.asDriver()
    }

    var isLoading: Driver<Bool> {
        loadingRelay.asDriver()
    }

    var error: Driver<Error?> {
        errorRelay.asDriver()
    }

    func onSelectFilter(index: Int) {
        currentCategoryIndex = index

        syncViewItems()
    }

}
