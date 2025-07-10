import SwiftUI
import UIKit

enum RestoreTypeModule {
    static func viewController(type: BackupModule.Source.Abstract, onRestore: @escaping () -> Void) -> UIViewController {
        let viewModel = RestoreTypeViewModel(cloudAccountBackupManager: Core.shared.cloudBackupManager, sourceType: type)
        let viewController = RestoreTypeViewController(viewModel: viewModel, onRestore: onRestore)
        return ThemeNavigationController(rootViewController: viewController)
    }
}

extension RestoreTypeModule {
    enum RestoreType: CaseIterable {
        case recoveryOrPrivateKey
        case cloudRestore
        case fileRestore
    }
}

struct RestoreTypeView: View {
    let type: BackupModule.Source.Abstract
    var onRestore: (() -> Void)? = nil
    @Binding var isPresented: Bool

    var body: some View {
        RestoreTypeViewOld(type: type) {
            if let onRestore {
                onRestore()
            } else {
                isPresented = false
            }
        }
        .ignoresSafeArea()
    }
}

struct RestoreTypeViewOld: UIViewControllerRepresentable {
    typealias UIViewControllerType = UIViewController

    let type: BackupModule.Source.Abstract
    let onRestore: () -> Void

    func makeUIViewController(context _: Context) -> UIViewController {
        RestoreTypeModule.viewController(type: type, onRestore: onRestore)
    }

    func updateUIViewController(_: UIViewController, context _: Context) {}
}
