import Kingfisher
import MarketKit
import SwiftUI

struct ZcashNetworkView: View {
    @StateObject private var viewModel: ZcashNetworkViewModel
    @Binding private var isPresented: Bool

    init(blockchain: Blockchain, isPresented: Binding<Bool>) {
        _viewModel = .init(wrappedValue: ZcashNetworkViewModel(blockchain: blockchain))
        _isPresented = isPresented
    }

    var body: some View {
        ThemeNavigationStack {
            ThemeView {
                BottomGradientWrapper {
                    ScrollView {
                        VStack(spacing: 32) {
                            ThemeText("zcash_network.description".localized, style: .subhead)
                                .padding(.horizontal, 16)

                            ListSection {
                                Cell(
                                    middle: {
                                        MultiText(title: "zcash_network.auto_select".localized, subtitle: "zcash_network.auto_select.description".localized)
                                    },
                                    right: {
                                        ThemeToggle(isOn: $viewModel.autoSelectEnabled)
                                    }
                                )
                            }

                            ListSection {
                                ForEach(viewModel.defaultItems) { item in
                                    nodeCell(item: item)
                                }
                            }

                            if !viewModel.customItems.isEmpty {
                                VStack(spacing: 0) {
                                    ThemeText("zcash_network.added".localized, style: .subheadSB, colorStyle: .secondary)
                                        .padding(.horizontal, 16)
                                        .padding(.bottom, 12)
                                        .frame(maxWidth: .infinity, alignment: .leading)

                                    ListSection {
                                        ForEach(viewModel.customItems) { item in
                                            nodeCell(item: item)
                                                .contextMenu {
                                                    Button {
                                                        viewModel.removeCustomNode(item)
                                                    } label: {
                                                        Label("button.delete".localized, image: "trash")
                                                    }
                                                }
                                                .tint(.themeLeah)
                                        }
                                    }
                                }
                            }

                            ListSection {
                                Cell(
                                    left: {
                                        ThemeImage("plus", size: 24, colorStyle: .yellow)
                                    },
                                    middle: {
                                        ThemeText("zcash_network.add_new".localized, style: .body, colorStyle: .yellow)
                                    },
                                    action: {
                                        Coordinator.shared.present { isPresented in
                                            AddZcashNodeView(blockchainType: viewModel.blockchain.type, isPresented: isPresented)
                                        }
                                        stat(page: .blockchainSettingsZcash, event: .openBlockchainSettingsZcashAdd(chainUid: viewModel.blockchain.type.uid))
                                    }
                                )
                            }
                        }
                        .padding(EdgeInsets(top: 12, leading: 16, bottom: 32, trailing: 16))
                    }
                } bottomContent: {
                    Button(action: {
                        viewModel.save()
                        isPresented = false
                    }) {
                        HStack(spacing: .margin8) {
                            if viewModel.processing {
                                ProgressView().progressViewStyle(.circular)
                            }
                            Text("button.save".localized)
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle(style: .yellow))
                    .disabled(!viewModel.saveEnabled || viewModel.processing)
                    .animation(.default, value: viewModel.processing)
                }
            }
            .navigationTitle(viewModel.blockchain.name)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    KFImage.url(URL(string: viewModel.blockchain.type.imageUrl))
                        .resizable()
                        .frame(size: 24)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { isPresented = false }) {
                        Image("close")
                    }
                }
            }
            .onReceive(viewModel.errorPublisher) { error in
                HudHelper.instance.show(banner: .error(string: error))
            }
        }
    }

    @ViewBuilder private func nodeCell(item: ZcashNetworkViewModel.NodeItem) -> some View {
        Cell(
            middle: {
                MultiText(title: item.name, subtitle: item.url)
            },
            right: {
                pingBadge(state: viewModel.pingStates[item.url])

                if item.selected {
                    Image.checkIcon
                }
            },
            // While auto-select is on, the fastest node wins - manual choice is disabled
            action: viewModel.autoSelectEnabled ? nil : {
                viewModel.selectNode(item)
            }
        )
    }

    @ViewBuilder private func pingBadge(state: ZcashNetworkViewModel.PingState?) -> some View {
        // Plain font/color instead of themeSubhead2, which expands to full width and would
        // float the badge mid-cell instead of keeping it at the trailing edge
        switch state {
        case .loading:
            ProgressView()
        case .unreachable:
            Text("zcash_network.unreachable".localized).font(.themeSubhead2).foregroundColor(.themeLucian)
        case let .reachable(text, level):
            switch level {
            case .good: Text(text).font(.themeSubhead2).foregroundColor(.themeRemus)
            case .medium: Text(text).font(.themeSubhead2).foregroundColor(.themeJacob)
            case .slow: Text(text).font(.themeSubhead2).foregroundColor(.themeGray)
            }
        case nil:
            EmptyView()
        }
    }
}
