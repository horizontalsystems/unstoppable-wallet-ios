import MarketKit
import SwiftUI

enum BtcBlockchainSettingsModule {
    static func view(blockchain: Blockchain) -> some View {
        let service = BtcBlockchainSettingsService(blockchain: blockchain, btcBlockchainManager: App.shared.btcBlockchainManager)
        let viewModel = BtcBlockchainSettingsViewModel(service: service)
        return BtcBlockchainSettingsView(viewModel: viewModel)
    }
}
