import Foundation
import RxSwift
import RxRelay
import HsToolKit
import LanguageKit

class GuidesService {
    private let disposeBag = DisposeBag()

    private let appConfigProvider: AppConfigProvider
    private let repository: GuidesRepository
    private let languageManager: LanguageManager

    init(appConfigProvider: AppConfigProvider, repository: GuidesRepository, languageManager: LanguageManager) {
        self.appConfigProvider = appConfigProvider
        self.repository = repository
        self.languageManager = languageManager
    }

    private func categoryItem(category: GuideCategory) -> GuideCategoryItem? {
        guard let title = category.title(language: languageManager.currentLanguage, fallbackLanguage: LanguageManager.fallbackLanguage) else {
            return nil
        }

        let guides = category.guides(language: languageManager.currentLanguage, fallbackLanguage: LanguageManager.fallbackLanguage)

        return GuideCategoryItem(
                title: title,
                items: guides.map { guideItem(guide: $0) }
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
