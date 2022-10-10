import Foundation
import UIKit
import RxSwift
import RxCocoa
import LanguageKit

protocol IGuidesViewModel {
    var filters: Driver<[String]> { get }
    var viewItems: Driver<[GuideViewItem]> { get }
    var isLoading: Driver<Bool> { get }
    var error: Driver<Error?> { get }

    func onSelectFilter(index: Int)
}

enum DataState<T> {
    case loading
    case success(result: T)
    case error(error: Error)
}

struct GuideCategoryItem {
    let title: String
    let items: [GuideItem]
}

struct GuideItem {
    let title: String
    var imageUrl: URL?
    let date: Date
    let url: URL?
}

struct GuideViewItem {
    let title: String
    let date: Date
    var imageUrl: URL?
    let url: URL?
}

struct GuidesModule {

    static func instance() -> UIViewController {
        let repository = GuidesRepository(
                appConfigProvider: App.shared.appConfigProvider,
                guidesManager: App.shared.guidesManager,
                reachabilityManager: App.shared.reachabilityManager
        )

        let service = GuidesService(appConfigProvider: App.shared.appConfigProvider, repository: repository, languageManager: LanguageManager.shared)
        let viewModel = GuidesViewModel(service: service)

        return GuidesViewController(viewModel: viewModel)
    }

}
