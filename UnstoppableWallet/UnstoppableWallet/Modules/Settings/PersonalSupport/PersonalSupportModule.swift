import SwiftUI
import UIKit

enum PersonalSupportModule {
    static func viewController() -> UIViewController {
        let localStorage = App.shared.localStorage
        let service = PersonalSupportService(marketKit: App.shared.marketKit, localStorage: localStorage)
        let viewModel = PersonalSupportViewModel(service: service)
        return PersonalSupportViewController(viewModel: viewModel)
    }
}

struct PersonalSupportView: UIViewControllerRepresentable {
    typealias UIViewControllerType = UIViewController

    func makeUIViewController(context _: Context) -> UIViewController {
        PersonalSupportModule.viewController()
    }

    func updateUIViewController(_: UIViewController, context _: Context) {}
}
