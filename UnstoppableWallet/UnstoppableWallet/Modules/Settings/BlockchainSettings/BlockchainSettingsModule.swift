import SwiftUI

enum BlockchainSettingsModule {
    static func view() -> some View {
        let viewModel = BlockchainSettingsViewModel(
            btcBlockchainManager: Core.shared.btcBlockchainManager,
            evmBlockchainManager: Core.shared.evmBlockchainManager,
            evmSyncSourceManager: Core.shared.evmSyncSourceManager
        )
        return BlockchainSettingsView(viewModel: viewModel)
    }
}
