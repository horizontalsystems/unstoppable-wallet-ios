import SwiftUI
import ThemeKit
import UIKit

struct TermsModule {
    static func viewController(sourceViewController: UIViewController? = nil, moduleToOpen: UIViewController? = nil) -> UIViewController {
        let service = TermsService(termsManager: App.shared.termsManager)
        let viewModel = TermsViewModel(service: service)
        let viewController = TermsViewController(viewModel: viewModel, sourceViewController: sourceViewController, moduleToOpen: moduleToOpen)

        return ThemeNavigationController(rootViewController: viewController)
    }

    static func view() -> some View {
        TermsView()
    }
}

struct TermsView: UIViewControllerRepresentable {
    typealias UIViewControllerType = UIViewController

    func makeUIViewController(context _: Context) -> UIViewController {
        TermsModule.viewController()
    }

    func updateUIViewController(_: UIViewController, context _: Context) {}
}
