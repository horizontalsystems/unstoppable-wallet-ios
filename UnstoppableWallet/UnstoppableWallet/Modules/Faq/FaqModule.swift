import Foundation
import UIKit

enum FaqModule {
    static func viewController() -> UIViewController {
        let repository = FaqRepository(
            networkManager: App.shared.networkManager,
            reachabilityManager: App.shared.reachabilityManager
        )

        let service = FaqService(
            repository: repository,
            languageManager: LanguageManager.shared
        )

        let viewModel = FaqViewModel(service: service)

        return FaqViewController(viewModel: viewModel)
    }
}
