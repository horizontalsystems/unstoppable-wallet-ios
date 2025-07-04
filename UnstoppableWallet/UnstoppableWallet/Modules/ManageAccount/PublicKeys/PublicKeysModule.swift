import SwiftUI
import UIKit

enum PublicKeysModule {
    static func viewController(account: Account) -> UIViewController {
        let service = PublicKeysService(account: account)
        let viewModel = PublicKeysViewModel(service: service)
        return PublicKeysViewController(viewModel: viewModel)
    }
}

struct PublicKeysView: UIViewControllerRepresentable {
    typealias UIViewControllerType = UIViewController

    private let account: Account

    init(account: Account) {
        self.account = account
    }

    func makeUIViewController(context _: Context) -> UIViewController {
        PublicKeysModule.viewController(account: account)
    }

    func updateUIViewController(_: UIViewController, context _: Context) {}
}
