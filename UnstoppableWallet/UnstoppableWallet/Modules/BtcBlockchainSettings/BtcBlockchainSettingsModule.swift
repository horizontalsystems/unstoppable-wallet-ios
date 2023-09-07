import SwiftUI
import UIKit
import MarketKit

struct BtcBlockchainSettingsModule {

    static func viewController(blockchain: Blockchain) -> UIViewController {
        let service = BtcBlockchainSettingsService(blockchain: blockchain, btcBlockchainManager: App.shared.btcBlockchainManager)
        let viewModel = BtcBlockchainSettingsViewModel(service: service)
        let view = BtcBlockchainSettingsView(viewModel: viewModel)

        return UIHostingController(rootView: view)
    }

}
