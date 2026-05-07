import Foundation
import MarketKit
import SwiftUI
import UIKit

enum AddZanoNodeModule {
    static func viewController(blockchainType: BlockchainType) -> UIViewController {
        let service = AddZanoNodeService(blockchainType: blockchainType, zanoNodeManager: Core.shared.zanoNodeManager)
        let viewModel = AddZanoNodeViewModel(service: service)
        let viewController = AddZanoNodeViewController(viewModel: viewModel)

        return ThemeNavigationController(rootViewController: viewController)
    }
}

struct AddZanoNodeSheetView: UIViewControllerRepresentable {
    let blockchainType: BlockchainType

    func makeUIViewController(context _: Context) -> UIViewController {
        AddZanoNodeModule.viewController(blockchainType: blockchainType)
    }

    func updateUIViewController(_: UIViewController, context _: Context) {}
}
