import MarketKit
import SwiftUI

struct ManageWalletsView: View {
    @StateObject var viewModel: ManageWalletsViewModel

    @State private var path = NavigationPath()
    @Binding var isPresented: Bool

    private let restoreSettingsView: RestoreSettingsView

    init(account: Account, isPresented: Binding<Bool>) {
        let (service, restoreSettingsView) = RestoreSettingsModule.module(statPage: .coinManager)
        self.restoreSettingsView = restoreSettingsView
        _viewModel = .init(wrappedValue: ManageWalletsViewModel(account: account, restoreSettingsService: service))

        _isPresented = isPresented
    }

    var body: some View {
        ThemeNavigationStack(path: $path) {
            VStack(spacing: 0) {
                ScrollableTabHeaderView(
                    tabs: ["filter.all".localized] + viewModel.blockchains.map(\.name),
                    currentTabIndex: Binding(
                        get: {
                            viewModel.blockchainFilterIndex
                        },
                        set: { index in
                            viewModel.setBlockchainFilter(index: index)
                        }
                    )
                )
                ScrollableThemeView(style: .list) {
                    if !viewModel.filter.isEmpty, viewModel.items.isEmpty {
                        PlaceholderViewNew(icon: "warning_filled", subtitle: "manage_wallets.not_found".localized)
                    } else {
                        ManageWalletListView(viewModel: viewModel)
                    }
                }
            }
            .navigationTitle("manage_wallets.title".localized)
            .searchBar(text: $viewModel.filter, prompt: "placeholder.search".localized)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: {
                        isPresented = false
                    }) {
                        Image("close")
                    }
                }

                if viewModel.canAddToken {
                    ToolbarItem(placement: .primaryAction) {
                        Button(action: {
                            openAddToken()
                        }) {
                            Image("plus")
                        }
                    }
                }
            }
        }
    }

    private func openAddToken() {
        guard let (account, items) = AddTokenModule.items() else {
            return
        }

        let viewModel = AddTokenViewModel(account: account, items: items, coinManager: Core.shared.coinManager, walletManager: Core.shared.walletManager)

        Coordinator.shared.present { isPresented in
            AddTokenView(viewModel: viewModel, isPresented: isPresented)
        }

        stat(page: .coinManager, event: .open(page: .addToken))
    }
}
