import SwiftUI
import UIKit

enum BackupManagerModule {
    static func viewController() -> UIViewController {
        let viewModel = BackupManagerViewModel(passcodeManager: App.shared.passcodeManager)
        return BackupManagerViewController(viewModel: viewModel)
    }
}

struct BackupManagerView: UIViewControllerRepresentable {
    typealias UIViewControllerType = UIViewController

    func makeUIViewController(context _: Context) -> UIViewController {
        BackupManagerModule.viewController()
    }

    func updateUIViewController(_: UIViewController, context _: Context) {}
}
