import RxSwift
import RxRelay
import HsToolKit

class GuidesService {
    private let disposeBag = DisposeBag()

    private let appConfigProvider: IAppConfigProvider
    private let repository: GuidesRepository

    init(appConfigProvider: IAppConfigProvider, repository: GuidesRepository) {
        self.appConfigProvider = appConfigProvider
        self.repository = repository
    }

    private func categoryItem(category: GuideCategory) -> GuideCategoryItem {
        GuideCategoryItem(
                title: category.title,
                items: category.guides.map { guideItem(guide: $0) }
        )
    }

    private func guideItem(guide: Guide) -> GuideItem {
        let guidesIndexUrl = appConfigProvider.guidesIndexUrl

        return GuideItem(
                title: guide.title,
                imageUrl: guide.imageUrl.flatMap { URL(string: $0, relativeTo: guidesIndexUrl) },
                date: guide.date,
                url: URL(string: guide.fileUrl, relativeTo: guidesIndexUrl)
        )
    }

    var categories: Observable<DataState<[GuideCategoryItem]>> {
        repository.categories.map { [weak self] dataState -> DataState<[GuideCategoryItem]> in
            switch dataState {
            case .loading:
                return .loading
            case .success(let categories):
                let categoryItems = categories.compactMap {
                    self?.categoryItem(category: $0)
                }
                return .success(result: categoryItems)
            case .error(let error):
                return .error(error: error)
            }
        }
    }

}
