import SwiftUI
import MarketKit

struct BtcBlockchainSettingsModule {

    static func view(blockchain: Blockchain) -> some View {
        let service = BtcBlockchainSettingsService(blockchain: blockchain, btcBlockchainManager: App.shared.btcBlockchainManager)
        let viewModel = BtcBlockchainSettingsViewModel(service: service)
        return BtcBlockchainSettingsView(viewModel: viewModel)
    }

}
