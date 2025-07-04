import SwiftUI
import UIKit

enum RecoveryPhraseModule {
    static func viewController(account: Account) -> UIViewController? {
        guard let service = RecoveryPhraseService(account: account) else {
            return nil
        }

        let viewModel = RecoveryPhraseViewModel(service: service)
        return RecoveryPhraseViewController(viewModel: viewModel)
    }
}

struct RecoveryPhraseView: UIViewControllerRepresentable {
    typealias UIViewControllerType = UIViewController

    private let account: Account

    init(account: Account) {
        self.account = account
    }

    func makeUIViewController(context _: Context) -> UIViewController {
        RecoveryPhraseModule.viewController(account: account) ?? UIViewController()
    }

    func updateUIViewController(_: UIViewController, context _: Context) {}
}
