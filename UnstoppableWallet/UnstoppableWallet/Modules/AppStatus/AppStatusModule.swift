import SwiftUI

enum AppStatusModule {
    static func view() -> some View {
        let viewModel = AppStatusViewModel(
            systemInfoManager: Core.shared.systemInfoManager,
            appVersionStorage: Core.shared.appVersionStorage,
            accountManager: Core.shared.accountManager,
            walletManager: Core.shared.walletManager,
            adapterManager: Core.shared.adapterManager,
            logRecordManager: Core.shared.logRecordManager,
            evmBlockchainManager: Core.shared.evmBlockchainManager,
            marketKit: Core.shared.marketKit
        )

        return AppStatusView(viewModel: viewModel)
    }
}
