import SwiftUI

struct PreSendView: View {
    @StateObject var viewModel: PreSendTabsViewModel
    private let addressVisible: Bool

    @Binding var path: NavigationPath
    @Binding var isPresented: Bool

    init(wallet: Wallet, predefinedAddress: ResolvedAddress? = nil, amount: Decimal? = nil, memo: String? = nil, addressVisible: Bool = true, path: Binding<NavigationPath>, isPresented: Binding<Bool>) {
        _viewModel = StateObject(wrappedValue: PreSendTabsViewModel(wallet: wallet, predefinedAddress: predefinedAddress, amount: amount, memo: memo, crossPayVisible: addressVisible))
        self.addressVisible = addressVisible
        _path = path
        _isPresented = isPresented
    }

    var body: some View {
        ThemeView(style: .list) {
            VStack(spacing: 0) {
                if viewModel.tabs.count > 1 {
                    FolderTabHeaderView(
                        tabs: viewModel.tabs.map { FolderTabHeaderView.Tab(title: $0.title, icon: $0.icon) },
                        currentTabIndex: Binding(
                            get: {
                                viewModel.tabs.firstIndex(of: viewModel.currentTab) ?? 0
                            },
                            set: { index in
                                if viewModel.tabs.indices.contains(index) {
                                    viewModel.currentTab = viewModel.tabs[index]
                                }
                            }
                        )
                    )
                }

                Group {
                    switch viewModel.currentTab {
                    case .standard:
                        StandardPreSendTabView(viewModel: viewModel.standard, addressVisible: addressVisible, path: $path, isPresented: $isPresented)
                    case .privateSend:
                        PrivatePreSendTabView(viewModel: viewModel.privateSend, addressVisible: addressVisible, path: $path, isPresented: $isPresented)
                    case .crossPay:
                        CrossPayPreSendTabView()
                    }
                }
            }
        }
        .navigationDestination(for: ConfirmationData.self) { data in
            RegularSendView(sendData: data.sendData, address: data.address) {
                HudHelper.instance.show(banner: .sent)
                isPresented = false
            }
            .toolbarRole(.editor)
        }
        .navigationTitle(viewModel.title)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if let handler = viewModel.handler, handler.hasSettings {
                    Button(action: {
                        Coordinator.shared.present { _ in
                            handler.settingsView {
                                viewModel.syncSendData()
                            }
                        }
                    }) {
                        Image("manage")
                            .modifier(ToolbarBadgeModifier(visible: viewModel.settingsModified))
                    }
                }
            }
        }
    }
}

extension PreSendView {
    struct ConfirmationData: Hashable, Equatable {
        let id = UUID()
        let sendData: SendData
        let address: String?

        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }

        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.id == rhs.id
        }
    }
}
