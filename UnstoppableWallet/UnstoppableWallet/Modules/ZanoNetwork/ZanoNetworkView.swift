import Kingfisher
import MarketKit
import SwiftUI

struct ZanoNetworkView: View {
    @StateObject private var viewModel: ZanoNetworkViewModel
    @Binding private var isPresented: Bool

    @State private var addNodePresented = false

    init(blockchain: Blockchain, isPresented: Binding<Bool>) {
        _viewModel = .init(wrappedValue: ZanoNetworkViewModel(blockchain: blockchain))
        _isPresented = isPresented
    }

    var body: some View {
        ThemeNavigationStack {
            ThemeView {
                BottomGradientWrapper {
                    ScrollView {
                        VStack(spacing: 32) {
                            ThemeText("zano_network.description".localized, style: .subhead)
                                .padding(.horizontal, 16)

                            ListSection {
                                ForEach(viewModel.defaultItems) { item in
                                    nodeCell(item: item) {
                                        viewModel.selectNode(item)
                                    }
                                }
                            }

                            if !viewModel.customItems.isEmpty {
                                VStack(spacing: 0) {
                                    ThemeText("zano_network.added".localized, style: .subheadSB, colorStyle: .secondary)
                                        .padding(.horizontal, 16)
                                        .padding(.bottom, 12)
                                        .frame(maxWidth: .infinity, alignment: .leading)

                                    ListSection {
                                        ForEach(viewModel.customItems) { item in
                                            nodeCell(item: item) {
                                                viewModel.selectNode(item)
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
                                        ThemeText("zano_network.add_new".localized, style: .body, colorStyle: .yellow)
                                    },
                                    action: {
                                        addNodePresented = true
                                        stat(page: .blockchainSettingsZano, event: .openBlockchainSettingsZanoAdd(chainUid: viewModel.blockchain.type.uid))
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
            .sheet(isPresented: $addNodePresented) {
                AddZanoNodeSheetView(blockchainType: viewModel.blockchain.type)
                    .ignoresSafeArea()
            }
        }
    }

    @ViewBuilder private func nodeCell(item: ZanoNetworkViewModel.NodeItem, action: @escaping () -> Void) -> some View {
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
