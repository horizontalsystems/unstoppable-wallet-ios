import SwiftUI
import MarketKit

struct ManageWalletsView: View {
    @StateObject var viewModel: ManageWalletsViewModel2

    @State private var path = NavigationPath()
    @Binding var isPresented: Bool
    @FocusState var searchFocused: Bool

    init(account: Account, isPresented: Binding<Bool>) {
        let service = RestoreSettingsService(manager: Core.shared.restoreSettingsManager)
        _viewModel = .init(wrappedValue: ManageWalletsViewModel2(account: account, restoreSettingsService: service))
        
        _isPresented = isPresented
    }
    
    var body: some View {
        ThemeNavigationStack(path: $path) {
            ThemeView(style: .list) {
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
                    
                    if viewModel.items.isEmpty {
                        PlaceholderViewNew(icon: "warning_filled", subtitle: "manage_wallets.not_found".localized)
                    } else {
                        ManageWalletListView(viewModel: viewModel)
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    BottomSearchBar(text: $viewModel.filter, prompt: "placeholder.search".localized, focused: $searchFocused)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("button.cancel".localized) {
                        isPresented = false
                    }
                }
            }
            .navigationTitle("manage_wallets.title".localized)
        }
    }
}
