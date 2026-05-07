import Foundation
import SwiftUI
import UIKit

enum FaqModule {
    static func viewController() -> UIViewController {
        let repository = FaqRepository(
            networkManager: Core.shared.networkManager,
            reachabilityManager: Core.shared.reachabilityManager
        )

        let service = FaqService(
            repository: repository,
            languageManager: LanguageManager.shared
        )

        let viewModel = FaqViewModel(service: service)

        return FaqViewController(viewModel: viewModel)
    }
}

struct FaqView: UIViewControllerRepresentable {
    typealias UIViewControllerType = UIViewController

    func makeUIViewController(context _: Context) -> UIViewController {
        FaqModule.viewController()
    }

    func updateUIViewController(_: UIViewController, context _: Context) {}
}
