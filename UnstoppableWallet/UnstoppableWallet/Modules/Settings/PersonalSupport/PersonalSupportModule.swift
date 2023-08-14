import UIKit

struct PersonalSupportModule {

    static func viewController() -> UIViewController {
        let localStorage = App.shared.localStorage
        let service = PersonalSupportService(marketKit: App.shared.marketKit, localStorage: localStorage)
        let viewModel = PersonalSupportViewModel(service: service)
        return PersonalSupportViewController(viewModel: viewModel)
    }

}
