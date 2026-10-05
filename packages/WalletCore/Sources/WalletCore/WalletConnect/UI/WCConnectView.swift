import MarketKit
import SwiftUI

// Connect proposal as a bottom sheet: no size-changing blocks, so it sizes stably
struct WCConnectView: View {
    // owned by WCPresenter so reject-on-dismiss can go through Coordinator.onDismiss, not the view lifecycle
    @ObservedObject private var viewModel: WCConnectViewModel
    @Binding private var isPresented: Bool

    init(viewModel: WCConnectViewModel, isPresented: Binding<Bool>) {
        self.viewModel = viewModel
        _isPresented = isPresented
    }

    var body: some View {
        ThemeView(style: .list) {
            VStack(spacing: 0) {
                content
                buttons
                    .padding(EdgeInsets(top: .margin24, leading: .margin24, bottom: .margin16, trailing: .margin24))
            }
        }
        .onReceive(viewModel.finishPublisher) {
            HudHelper.instance.show(banner: .done)
            isPresented = false
        }
        .onReceive(viewModel.errorPublisher) { error in
            HudHelper.instance.show(banner: .error(string: error))
        }
        .interactiveDismissDisabled(viewModel.connecting)
    }

    @ViewBuilder private var content: some View {
        WCDAppTitleView(iconUrl: viewModel.iconUrl, title: "wallet_connect.connect.title".localized(viewModel.dAppName), showGrabber: true)
        BSModule.view(for: .subtitle(text: viewModel.dAppHost))

        if let caution = viewModel.verificationCaution {
            AlertCardView(caution: caution)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, .margin16)
                .padding(.top, .margin16)
        }

        DefenseSystemHeader(icon: Image.defenseIcon, title: "wallet_connect.scam_protection".localized)
            .padding(.horizontal, .margin16)
            .padding(.top, .margin24)

        ListSection {
            Cell(
                middle: {
                    MiddleTextIcon(text: "wallet_connect.dapp_check".localized)
                },
                right: {
                    dAppCheckValue
                },
                action: viewModel.dAppCheck == .locked ? { activateScamProtection() } : nil
            )
        }
        .themeListStyle(.bordered)
        .padding(.horizontal, .margin16)
        .padding(.top, .margin12)

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
                        WCBlockchainsView(blockchainTypes: viewModel.blockchainTypes)
                    }
                }
            )
        }
        .themeListStyle(.bordered)
        .padding(.horizontal, .margin16)
        .padding(.top, .margin16)

        BSModule.view(for: .footer(text: "wallet_connect.connect.description".localized))

        if viewModel.unsupported {
            BSModule.view(for: .error(text: "wallet_connect.connect.unsupported".localized))
        }

        if viewModel.showDanger {
            AlertCardView(caution: CautionNew(title: "wallet_connect.defense.danger.title".localized, text: "wallet_connect.defense.danger.text".localized, type: .error))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, .margin16)
                .padding(.top, .margin8)
        }
    }

    @ViewBuilder private var dAppCheckValue: some View {
        switch viewModel.dAppCheck {
        case .locked:
            Image("lock").themeIcon()
        case .secure:
            RightTextIcon(text: ComponentText(text: "wallet_connect.scam_protection.secure".localized, colorStyle: .green))
        case .risky:
            RightTextIcon(text: ComponentText(text: "wallet_connect.scam_protection.risky".localized, colorStyle: .red))
        case .unavailable:
            RightTextIcon(text: ComponentText(text: "wallet_connect.scam_protection.not_available".localized, colorStyle: .secondary))
        case .hidden:
            EmptyView()
        }
    }

    @ViewBuilder private var buttons: some View {
        HStack(spacing: .margin8) {
            Button(action: {
                viewModel.reject()
                isPresented = false
            }) {
                Text("button.cancel".localized)
            }
            .buttonStyle(PrimaryButtonStyle(style: .gray))
            .disabled(viewModel.connecting)

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

    private var blockchainIcons: some View {
        HStack(spacing: -.margin8) {
            ForEach(Array(viewModel.blockchainTypes.prefix(6)), id: \.self) { type in
                IconView(url: type.imageUrl, placeholderImage: "rectangle_placeholder", type: .circle, size: .iconSize24)
            }
        }
    }

    private func activateScamProtection() {
        Coordinator.shared.performAfterPurchase(premiumFeature: .scamProtection, page: .walletConnect, trigger: .getPremium) {
            viewModel.refreshDefense()
        }
    }
}
