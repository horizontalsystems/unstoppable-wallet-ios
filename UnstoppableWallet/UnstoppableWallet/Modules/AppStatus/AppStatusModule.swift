protocol IAppStatusView: AnyObject {
    func set(logs: [(String, Any)])
}

protocol IAppStatusViewDelegate {
    func viewDidLoad()
    func onCopy(text: String)
}

protocol IAppStatusInteractor {
    var status: [(String, Any)] { get }

    func copyToClipboard(string: String)
}

import UIKit

struct AppStatusModule {

    static func viewController() -> UIViewController {
        let viewModel = AppStatusViewModel()

        return AppStatusViewControllerNew(viewModel: viewModel)
    }

}
