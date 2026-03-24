import Kingfisher
import MarketKit
import SwiftUI

struct MoneroNetworkView: View {
    @StateObject private var viewModel: MoneroNetworkViewModel
    @Binding private var isPresented: Bool

    @State private var settingsItem: MoneroNetworkViewModel.NodeItem?
    @State private var addNodePresented = false

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
                                    nodeCell(item: item) {
                                        settingsItem = item
                                    }
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
                                            nodeCell(item: item) {
                                                settingsItem = item
                                            }
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
                                        addNodePresented = true
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
            .sheet(item: $settingsItem) { item in
                let initialTrusted = item.node.node.url == viewModel.selectedNodeUrl ? viewModel.selectedIsTrusted : item.isTrusted
                MoneroNetworkNodeSettingsView(name: item.name, isTrusted: initialTrusted) { isTrusted in
                    viewModel.selectNode(item, isTrusted: isTrusted)
                }
            }
            .sheet(isPresented: $addNodePresented) {
                AddMoneroNodeSheetView(blockchainType: viewModel.blockchain.type)
                    .ignoresSafeArea()
            }
        }
    }

    @ViewBuilder private func nodeCell(item: MoneroNetworkViewModel.NodeItem, action: @escaping () -> Void) -> some View {
        Cell(
            middle: {
                MultiText(title: item.name, subtitle: item.url)
            },
            right: {
                if item.selected {
                    Image.checkIcon
                }
            },
            action: action
        )
    }
}

struct MoneroNetworkNodeSettingsView: View {
    @Environment(\.dismiss) private var dismiss

    let name: String
    let onDone: (Bool) -> Void

    @State private var isTrusted: Bool

    init(name: String, isTrusted: Bool, onDone: @escaping (Bool) -> Void) {
        self.name = name
        self.onDone = onDone
        _isTrusted = .init(initialValue: isTrusted)
    }

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
                        dismiss()
                    },
                ])))
            }
        }
    }
}
