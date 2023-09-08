import SwiftUI

struct BlockchainSettingsModule {
    static func view() -> some View {
        let viewModel = BlockchainSettingsViewModel(
            btcBlockchainManager: App.shared.btcBlockchainManager,
            evmBlockchainManager: App.shared.evmBlockchainManager,
            evmSyncSourceManager: App.shared.evmSyncSourceManager
        )
        return BlockchainSettingsView(viewModel: viewModel)
    }
}
