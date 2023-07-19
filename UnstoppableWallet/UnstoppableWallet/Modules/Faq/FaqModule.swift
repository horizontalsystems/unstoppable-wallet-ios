import Foundation
import UIKit
import LanguageKit

struct FaqModule {

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
