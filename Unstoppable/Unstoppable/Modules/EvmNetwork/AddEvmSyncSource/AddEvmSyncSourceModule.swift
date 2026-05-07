import Foundation
import MarketKit
import SwiftUI
import UIKit

enum AddEvmSyncSourceModule {
    static func viewController(blockchainType: BlockchainType) -> UIViewController {
        let service = AddEvmSyncSourceService(blockchainType: blockchainType, evmSyncSourceManager: Core.shared.evmSyncSourceManager)
        let viewModel = AddEvmSyncSourceViewModel(service: service)
        let viewController = AddEvmSyncSourceViewController(viewModel: viewModel)

        return ThemeNavigationController(rootViewController: viewController)
    }
}

struct AddEvmSyncSourceSheetView: UIViewControllerRepresentable {
    let blockchainType: BlockchainType

    func makeUIViewController(context _: Context) -> UIViewController {
        AddEvmSyncSourceModule.viewController(blockchainType: blockchainType)
    }

    func updateUIViewController(_: UIViewController, context _: Context) {}
}
