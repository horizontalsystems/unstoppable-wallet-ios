import Kingfisher
import MarketKit
import SwiftUI

struct EvmNetworkView: View {
    @StateObject private var viewModel: EvmNetworkViewModel
    @Binding private var isPresented: Bool

    init(blockchain: Blockchain, isPresented: Binding<Bool>) {
        _viewModel = .init(wrappedValue: EvmNetworkViewModel(blockchain: blockchain))
        _isPresented = isPresented
    }

    var body: some View {
        ThemeNavigationStack {
            ThemeView {
                BottomGradientWrapper {
                    ScrollView {
                        VStack(spacing: 32) {
                            ThemeText("evm_network.description".localized, style: .subhead)
                                .padding(.horizontal, 16)

                            ListSection {
                                ForEach(viewModel.defaultSources) { source in
                                    cell(source: source)
                                }
                            }

                            if !viewModel.customSources.isEmpty {
                                VStack(spacing: 0) {
                                    ThemeText("evm_network.added".localized, style: .subheadSB, colorStyle: .secondary)
                                        .padding(.horizontal, 16)
                                        .padding(.bottom, 12)
                                        .frame(maxWidth: .infinity, alignment: .leading)

                                    ListSection {
                                        ForEach(viewModel.customSources) { source in
                                            cell(source: source)
                                                .contextMenu {
                                                    Button {
                                                        viewModel.remove(syncSource: source)
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
                                        ThemeText("evm_network.add_new".localized, style: .body, colorStyle: .yellow)
                                    },
                                    action: {
                                        Coordinator.shared.present { _ in
                                            AddEvmSyncSourceSheetView(blockchainType: viewModel.blockchain.type)
                                                .ignoresSafeArea()
                                        }
                                        stat(page: .blockchainSettingsEvm, event: .openBlockchainSettingsEvmAdd(chainUid: viewModel.blockchain.type.uid))
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

    @ViewBuilder func cell(source: EvmSyncSource) -> some View {
        Cell(
            middle: {
                MultiText(title: source.name, subtitle: source.rpcSource.url.absoluteString)
            },
            right: {
                if source == viewModel.selectedSource {
                    Image.checkIcon
                }
            },
            action: {
                viewModel.selectedSource = source
            }
        )
    }
}
