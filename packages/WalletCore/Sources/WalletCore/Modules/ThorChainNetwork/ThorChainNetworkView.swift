import Kingfisher
import MarketKit
import SwiftUI
import ThorChainKit

struct ThorChainNetworkView: View {
    @StateObject private var viewModel: ThorChainNetworkViewModel
    @Binding private var isPresented: Bool

    init(blockchain: Blockchain, isPresented: Binding<Bool>) {
        _viewModel = .init(wrappedValue: ThorChainNetworkViewModel(blockchain: blockchain))
        _isPresented = isPresented
    }

    var body: some View {
        ThemeNavigationStack {
            ThemeView {
                BottomGradientWrapper {
                    ScrollView {
                        ListSection {
                            ForEach(viewModel.endpointFamilies, id: \.id) { endpointFamily in
                                Cell(
                                    middle: {
                                        MultiText(
                                            title: endpointFamily.id,
                                            subtitle: "\(endpointFamily.cosmosRestURL.host ?? "")\n\(endpointFamily.cometBftURL.host ?? "")"
                                        )
                                    },
                                    right: {
                                        if endpointFamily.id == viewModel.selectedEndpointFamilyId {
                                            Image.checkIcon
                                        }
                                    },
                                    action: {
                                        viewModel.selectedEndpointFamilyId = endpointFamily.id
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
                if #available(iOS 26, *) {
                    ToolbarItem(placement: .topBarTrailing) { BlockchainIcon(blockchain: viewModel.blockchain) }
                        .sharedBackgroundVisibility(.hidden)
                } else {
                    ToolbarItem(placement: .topBarTrailing) { BlockchainIcon(blockchain: viewModel.blockchain) }
                }

                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { isPresented = false }) {
                        Image("close")
                    }
                }
            }
        }
    }
}
