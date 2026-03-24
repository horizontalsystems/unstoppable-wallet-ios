import Kingfisher
import MarketKit
import SwiftUI

struct BtcBlockchainSettingsView: View {
    @StateObject private var viewModel: BtcBlockchainSettingsViewModel
    @Binding private var isPresented: Bool

    init(blockchain: Blockchain, isPresented: Binding<Bool>) {
        _viewModel = .init(wrappedValue: BtcBlockchainSettingsViewModel(blockchain: blockchain))
        _isPresented = isPresented
    }

    var body: some View {
        ThemeNavigationStack {
            ThemeView {
                BottomGradientWrapper {
                    ScrollView {
                        VStack(spacing: 32) {
                            ThemeText("btc_blockchain_settings.restore_source.description".localized, style: .subhead)
                                .padding(.horizontal, 16)

                            ListSection {
                                ForEach(viewModel.restoreModes) { restoreMode in
                                    Cell(
                                        left: {
                                            switch restoreMode {
                                            case .blockchair:
                                                Image("blockchair_32")
                                            case .hybrid:
                                                Image("api_placeholder_32")
                                            case .blockchain:
                                                KFImage.url(URL(string: viewModel.blockchain.type.imageUrl))
                                                    .resizable()
                                                    .frame(size: 32)
                                            }
                                        },
                                        middle: {
                                            MultiText(
                                                title: restoreMode.title(blockchain: viewModel.blockchain),
                                                subtitle: restoreMode.description
                                            )
                                        },
                                        right: {
                                            if restoreMode == viewModel.selectedRestoreMode {
                                                Image.checkIcon
                                            }
                                        },
                                        action: {
                                            viewModel.selectedRestoreMode = restoreMode
                                        }
                                    )
                                }
                            }

                            HighlightedTextView(text: "btc_blockchain_settings.restore_source.alert".localized(viewModel.blockchain.name))
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
                        .frame(width: .iconSize24, height: .iconSize24)
                }

                ToolbarItem(placement: .cancellationAction) {
                    Button(action: {
                        isPresented = false
                    }) {
                        Image("close")
                    }
                }
            }
        }
    }
}
