import Kingfisher
import MarketKit
import SwiftUI

struct MoneroNetworkView: View {
    @StateObject private var viewModel: MoneroNetworkViewModel
    @Binding private var isPresented: Bool

    init(blockchain: Blockchain, isPresented: Binding<Bool>) {
        _viewModel = .init(wrappedValue: MoneroNetworkViewModel(blockchain: blockchain))
        _isPresented = isPresented
    }

    var body: some View {
        ThemeNavigationStack {
            ThemeView {
                BottomGradientWrapper {
                    ScrollView {
                        VStack(spacing: 32) {
                            ThemeText("monero_network.description".localized, style: .subhead)
                                .padding(.horizontal, 16)

                            ListSection {
                                ForEach(viewModel.defaultItems) { item in
                                    nodeCell(item: item)
                                }
                            }

                            if !viewModel.customItems.isEmpty {
                                VStack(spacing: 0) {
                                    ThemeText("monero_network.added".localized, style: .subheadSB, colorStyle: .secondary)
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
                                        ThemeText("monero_network.add_new".localized, style: .body, colorStyle: .yellow)
                                    },
                                    action: {
                                        Coordinator.shared.present { _ in
                                            AddMoneroNodeSheetView(blockchainType: viewModel.blockchain.type)
                                                .ignoresSafeArea()
                                        }
                                        stat(page: .blockchainSettingsMonero, event: .openBlockchainSettingsMoneroAdd(chainUid: viewModel.blockchain.type.uid))
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
                        Text("button.save".localized)
                    }
                    .buttonStyle(PrimaryButtonStyle(style: .yellow))
                    .disabled(!viewModel.saveEnabled)
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
        }
    }

    @ViewBuilder private func nodeCell(item: MoneroNetworkViewModel.NodeItem) -> some View {
        Cell(
            middle: {
                MultiText(title: item.name, subtitle: item.url)
            },
            right: {
                if item.selected {
                    Image.checkIcon
                }
            },
            action: {
                Coordinator.shared.present(type: .bottomSheet) { isPresented in
                    let initialTrusted = item.node.node.url == viewModel.selectedNode.node.url ? viewModel.selectedNode.node.isTrusted : item.isTrusted
                    MoneroNetworkNodeSettingsView(name: item.name, isTrusted: initialTrusted, isPresented: isPresented) { isTrusted in
                        viewModel.selectNode(item, isTrusted: isTrusted)
                    }
                }
            }
        )
    }
}

struct MoneroNetworkNodeSettingsView: View {
    let name: String

    @State var isTrusted: Bool
    @Binding var isPresented: Bool

    let onDone: (Bool) -> Void

    var body: some View {
        ThemeView(style: .list) {
            VStack(spacing: 0) {
                BSModule.view(for: .title(title: "monero_network.settings.title".localized))

                BSModule.view(for: .text(text: "monero_network.settings.description".localized))

                ListSection {
                    Cell(
                        middle: {
                            MultiText(title: "monero_network.settings.trust".localized, subtitle: name)
                        },
                        right: {
                            ThemeToggle(isOn: $isTrusted)
                        }
                    )
                }
                .themeListStyle(.bordered)
                .padding(.horizontal, .margin16)
                .padding(.vertical, .margin8)

                BSModule.view(for: .buttonGroup(.init(buttons: [
                    .init(style: .yellow, title: "button.done".localized) {
                        onDone(isTrusted)
                        isPresented = false
                    },
                ])))
            }
        }
    }
}
