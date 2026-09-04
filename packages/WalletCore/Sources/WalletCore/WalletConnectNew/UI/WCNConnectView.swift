import MarketKit
import SwiftUI

struct WCNConnectView: View {
    @StateObject private var viewModel: WCNConnectViewModel
    @Environment(\.presentationMode) private var presentationMode

    init(item: WCNProposalItem) {
        _viewModel = StateObject(wrappedValue: WCNConnectViewModel(item: item))
    }

    init(session: WCNSessionItem) {
        _viewModel = StateObject(wrappedValue: WCNConnectViewModel(session: session))
    }

    var body: some View {
        ThemeNavigationStack {
            ThemeView {
                BottomGradientWrapper {
                    ScrollView {
                        VStack(spacing: 0) {
                            WCNDAppTitleView(iconUrl: viewModel.iconUrl, title: (viewModel.connected ? "wallet_connect.session.title" : "wallet_connect.connect.title").localized(viewModel.dAppName))
                            BSModule.view(for: .subtitle(text: viewModel.dAppHost))

                            ListSection {
                                Cell(
                                    middle: {
                                        MiddleTextIcon(text: "wallet_connect.connect.wallet".localized)
                                    },
                                    right: {
                                        RightTextIcon(text: ComponentText(text: viewModel.accountName ?? "", colorStyle: .primary))
                                    }
                                )
                                Cell(
                                    middle: {
                                        MiddleTextIcon(text: "wallet_connect.networks".localized)
                                    },
                                    right: {
                                        blockchainIcons
                                        Image.disclosureIcon
                                    },
                                    action: {
                                        Coordinator.shared.present { _ in
                                            WCNBlockchainsView(blockchainTypes: viewModel.blockchainTypes)
                                        }
                                    }
                                )
                            }
                            .themeListStyle(.bordered)
                            .padding(.horizontal, .margin16)
                            .padding(.vertical, .margin8)

                            BSModule.view(for: .footer(text: "wallet_connect.connect.description".localized))

                            if viewModel.unsupported {
                                BSModule.view(for: .error(text: "wallet_connect.connect.unsupported".localized))
                            }
                        }
                        .padding(.bottom, .margin32)
                    }
                } bottomContent: {
                    VStack(spacing: .margin16) {
                        WCNDefenseBlock(state: viewModel.defenseState) {
                            Coordinator.shared.performAfterPurchase(premiumFeature: .scamProtection, page: .walletConnect, trigger: .getPremium) {
                                viewModel.refreshDefense()
                            }
                        }

                        if viewModel.connected {
                            Button(action: { viewModel.disconnect() }) {
                                HStack(spacing: .margin8) {
                                    if viewModel.connecting { ProgressView().progressViewStyle(.circular) }
                                    Text("wallet_connect.button_disconnect".localized)
                                }
                            }
                            .buttonStyle(PrimaryButtonStyle(style: .gray))
                            .disabled(viewModel.connecting)
                        } else {
                            HStack(spacing: .margin8) {
                                Button(action: {
                                    viewModel.reject()
                                    presentationMode.wrappedValue.dismiss()
                                }) {
                                    Text("button.cancel".localized)
                                }
                                .buttonStyle(PrimaryButtonStyle(style: .gray))

                                Button(action: { viewModel.connect() }) {
                                    HStack(spacing: .margin8) {
                                        if viewModel.connecting { ProgressView().progressViewStyle(.circular) }
                                        Text("button.connect".localized)
                                    }
                                }
                                .buttonStyle(PrimaryButtonStyle(style: .yellow))
                                .disabled(!viewModel.connectEnabled)
                            }
                        }
                    }
                }
            }
            .onReceive(viewModel.finishPublisher) {
                HudHelper.instance.show(banner: viewModel.connected ? .disconnectedWalletConnect : .done)
                presentationMode.wrappedValue.dismiss()
            }
            .onReceive(viewModel.errorPublisher) { error in
                HudHelper.instance.show(banner: .error(string: error))
            }
            .onDisappear { viewModel.reject() }
            .navigationTitle("wallet_connect.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: {
                        viewModel.reject()
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image("close")
                    }
                }
            }
        }
    }

    private var blockchainIcons: some View {
        HStack(spacing: -.margin8) {
            ForEach(Array(viewModel.blockchainTypes.prefix(6)), id: \.self) { type in
                IconView(url: type.imageUrl, placeholderImage: "rectangle_placeholder", type: .circle, size: .iconSize24)
            }
        }
    }
}
