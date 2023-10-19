import SwiftUI

struct AppStatusModule {
    static func view() -> some View {
        let viewModel = AppStatusViewModel(
            systemInfoManager: App.shared.systemInfoManager,
            appVersionStorage: App.shared.appVersionStorage,
            accountManager: App.shared.accountManager,
            walletManager: App.shared.walletManager,
            adapterManager: App.shared.adapterManager,
            logRecordManager: App.shared.logRecordManager,
            evmBlockchainManager: App.shared.evmBlockchainManager,
            binanceKitManager: App.shared.binanceKitManager,
            marketKit: App.shared.marketKit
        )

        return AppStatusView(viewModel: viewModel)
    }
}
