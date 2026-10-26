import SwiftUI

struct ExtendedKeyView: View {
    @StateObject private var viewModel: ExtendedKeyViewModel

    init(mode: ExtendedKeyViewModel.Mode, accountType: AccountType) {
        _viewModel = StateObject(wrappedValue: ExtendedKeyViewModel(mode: mode, accountType: accountType))
    }

    var body: some View {
        let viewItem = viewModel.viewItem

        KeyScreenScaffold(
            title: viewModel.title,
            statPage: viewModel.statPage,
            buttonDisabled: viewItem.key.isEmpty,
            onButtonTap: { viewModel.copy() }
        ) {
            VStack(spacing: 0) {
                if viewItem.keyIsPrivate {
                    AlertCardView(.init(text: "recovery_phrase.warning".localized(AppConfig.appName), type: .caution, style: .inline))
                        .padding(.bottom, .margin12)
                }

                ListSection {
                    controlRow(
                        title: "extended_key.purpose".localized,
                        value: viewItem.derivation,
                        switchable: viewItem.derivationSwitchable
                    ) {
                        presentSelector(title: "extended_key.purpose".localized, viewItems: viewModel.derivationViewItems) { index in
                            viewModel.onSelectDerivation(index: index)
                        }
                    }

                    if let blockchain = viewItem.blockchain {
                        controlRow(
                            title: "extended_key.blockchain".localized,
                            value: blockchain,
                            switchable: viewItem.blockchainSwitchable
                        ) {
                            presentSelector(title: "extended_key.blockchain".localized, viewItems: viewModel.blockchainViewItems) { index in
                                viewModel.onSelectBlockchain(index: index)
                            }
                        }
                    }

                    if let account = viewItem.account {
                        controlRow(
                            title: "extended_key.account".localized,
                            value: account,
                            switchable: true,
                            infoDescription: "extended_key.account.description".localized
                        ) {
                            presentSelector(title: "extended_key.account".localized, viewItems: viewModel.accountViewItems) { index in
                                viewModel.onSelectAccount(index: index)
                            }
                        }
                    }
                }
                .padding(.bottom, .margin32)

                KeyCardView(
                    text: viewItem.key,
                    hidden: viewItem.keyIsPrivate && viewModel.keyHidden,
                    hint: "extended_key.tap_to_show".localized,
                    onTap: viewItem.keyIsPrivate ? { viewModel.toggleKeyHidden() } : nil
                )
            }
        }
    }

    @ViewBuilder private func controlRow(title: String, value: String, switchable: Bool, infoDescription: String? = nil, onSelect: @escaping () -> Void) -> some View {
        Cell(
            middle: {
                if let infoDescription {
                    Button {
                        Coordinator.shared.present(info: InfoDescription(title: title, description: infoDescription))
                    } label: {
                        HStack(spacing: .margin8) {
                            ThemeText(title, style: .body)
                            ThemeImage("information", size: .iconSize20, colorStyle: .secondary)
                        }
                    }
                    .buttonStyle(.borderless)
                } else {
                    ThemeText(title, style: .body)
                }
            },
            right: {
                let text = ThemeText(value, style: .subhead, colorStyle: .secondary)

                if switchable {
                    text.arrow(style: .dropdown)
                } else {
                    text
                }
            },
            action: switchable ? onSelect : nil
        )
    }

    private func presentSelector(title: String, viewItems: [AlertViewItem], onSelect: @escaping (Int) -> Void) {
        Coordinator.shared.present(type: .alert) { isPresented in
            OptionAlertView(
                title: title,
                viewItems: viewItems,
                onSelect: onSelect,
                isPresented: isPresented
            )
        }
    }
}
