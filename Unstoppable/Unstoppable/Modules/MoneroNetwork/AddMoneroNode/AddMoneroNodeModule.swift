import Foundation
import MarketKit
import SwiftUI
import UIKit

enum AddMoneroNodeModule {
    static func viewController(blockchainType: BlockchainType) -> UIViewController {
        let service = AddMoneroNodeService(blockchainType: blockchainType, moneroNodeManager: Core.shared.moneroNodeManager)
        let viewModel = AddMoneroNodeViewModel(service: service)
        let viewController = AddMoneroNodeViewController(viewModel: viewModel)

        return ThemeNavigationController(rootViewController: viewController)
    }
}

struct AddMoneroNodeSheetView: UIViewControllerRepresentable {
    let blockchainType: BlockchainType

    func makeUIViewController(context _: Context) -> UIViewController {
        AddMoneroNodeModule.viewController(blockchainType: blockchainType)
    }

    func updateUIViewController(_: UIViewController, context _: Context) {}
}
