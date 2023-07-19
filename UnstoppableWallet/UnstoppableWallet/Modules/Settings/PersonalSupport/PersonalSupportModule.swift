import UIKit

struct PersonalSupportModule {

    static func viewController() -> UIViewController {
        let service = PersonalSupportService(marketKit: App.shared.marketKit)
        let viewModel = PersonalSupportViewModel(service: service)
        return PersonalSupportViewController(viewModel: viewModel)
    }

}
