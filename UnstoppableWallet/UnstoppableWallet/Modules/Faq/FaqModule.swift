import Foundation
import UIKit
import LanguageKit

struct FaqModule {

    static func viewController() -> UIViewController {
        let repository = FaqRepository(
                networkManager: App.shared.networkManager,
                appConfigProvider: App.shared.appConfigProvider,
                reachabilityManager: App.shared.reachabilityManager
        )

        let service = FaqService(
                appConfigProvider: App.shared.appConfigProvider,
                repository: repository,
                languageManager: LanguageManager.shared
        )

        let viewModel = FaqViewModel(service: service)

        return FaqViewController(viewModel: viewModel)
    }

}
