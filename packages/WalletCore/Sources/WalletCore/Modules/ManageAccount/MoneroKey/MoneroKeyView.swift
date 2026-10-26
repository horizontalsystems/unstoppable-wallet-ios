import SwiftUI

struct MoneroKeyView: View {
    @StateObject private var viewModel: MoneroKeyViewModel

    init(accountType: AccountType, mode: MoneroKeyViewModel.Mode) {
        _viewModel = StateObject(wrappedValue: MoneroKeyViewModel(accountType: accountType, mode: mode))
    }

    var body: some View {
        KeyScreenScaffold(
            title: viewModel.title,
            statPage: viewModel.statPage,
            buttonDisabled: viewModel.key.isEmpty,
            onButtonTap: { viewModel.copy() }
        ) {
            VStack(spacing: .margin24) {
                ListSection {
                    Cell(
                        middle: {
                            ThemeText("monero.key_types".localized, style: .body)
                        },
                        right: {
                            ThemeText(viewModel.keyType.title, style: .subhead, colorStyle: .secondary).arrow(style: .dropdown)
                        },
                        action: {
                            Coordinator.shared.present(type: .alert) { isPresented in
                                OptionAlertView(
                                    title: "monero.key_types".localized,
                                    viewItems: viewModel.keyTypeViewItems,
                                    onSelect: { index in
                                        viewModel.onSelectKeyType(index: index)
                                    },
                                    isPresented: isPresented
                                )
                            }
                        }
                    )
                }

                VStack(spacing: .margin12) {
                    if viewModel.showingPrivateKeys {
                        AlertCardView(.init(text: "recovery_phrase.warning".localized(AppConfig.appName), type: .caution, style: .inline))
                    }

                    KeyCardView(
                        text: viewModel.key,
                        hidden: viewModel.showingPrivateKeys && viewModel.hidden,
                        hint: "monero_private_key.tap_to_show".localized,
                        alignment: .center,
                        onTap: viewModel.showingPrivateKeys ? { viewModel.toggleHidden() } : nil
                    )
                }
            }
        }
    }
}
