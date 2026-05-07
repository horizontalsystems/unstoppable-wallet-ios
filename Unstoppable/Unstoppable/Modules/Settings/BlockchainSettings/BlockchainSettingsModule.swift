import SwiftUI

enum BlockchainSettingsModule {
    static func view() -> some View {
        let viewModel = BlockchainSettingsViewModel(
            btcBlockchainManager: Core.shared.btcBlockchainManager,
            evmBlockchainManager: Core.shared.evmBlockchainManager,
            evmSyncSourceManager: Core.shared.evmSyncSourceManager,
            moneroNodeManager: Core.shared.moneroNodeManager,
            zanoNodeManager: Core.shared.zanoNodeManager,
            marketKit: Core.shared.marketKit
        )
        return BlockchainSettingsView(viewModel: viewModel)
    }
}
