import SwiftUI

struct PrivateKeysView: View {
    private let viewModel: PrivateKeysViewModel

    init(account: Account) {
        viewModel = PrivateKeysViewModel(account: account)
    }

    var body: some View {
        ScrollableThemeView {
            VStack(spacing: .margin24) {
                if viewModel.showEvmPrivateKey {
                    option(title: "private_keys.evm_private_key".localized, description: "private_keys.evm_private_key.description".localized) {
                        SecretKeyView(kind: .evmPrivateKey, accountType: viewModel.accountType)
                            .onFirstAppear { stat(page: .privateKeys, event: .open(page: .evmPrivateKey)) }
                    }
                }

                if viewModel.showTronPrivateKey {
                    option(title: "private_keys.tron_private_key".localized, description: "private_keys.tron_private_key.description".localized) {
                        SecretKeyView(kind: .tronPrivateKey, accountType: viewModel.accountType)
                            .onFirstAppear { stat(page: .privateKeys, event: .open(page: .tronPrivateKey)) }
                    }
                }

                if viewModel.showStellarSecretKey {
                    option(title: "private_keys.stellar_secret_key".localized, description: "private_keys.stellar_secret_key.description".localized) {
                        SecretKeyView(kind: .stellarSecretKey, accountType: viewModel.accountType)
                            .onFirstAppear { stat(page: .privateKeys, event: .open(page: .stellarSecretKey)) }
                    }
                }

                if viewModel.showBip32RootKey {
                    option(title: "private_keys.bip32_root_key".localized, description: "private_keys.bip32_root_key.description".localized) {
                        ExtendedKeyView(mode: .bip32RootKey, accountType: viewModel.accountType)
                            .onFirstAppear { stat(page: .privateKeys, event: .open(page: .bip32RootKey)) }
                    }
                }

                if viewModel.showAccountExtendedPrivateKey {
                    option(title: "private_keys.account_extended_private_key".localized, description: "private_keys.account_extended_private_key.description".localized) {
                        ExtendedKeyView(mode: .accountExtendedPrivateKey, accountType: viewModel.accountType)
                            .onFirstAppear { stat(page: .privateKeys, event: .open(page: .accountExtendedPrivateKey)) }
                    }
                }

                if viewModel.showMoneroPrivateKey {
                    option(title: "private_keys.monero_private_key".localized, description: "private_keys.monero_private_key.description".localized) {
                        MoneroKeyView(accountType: viewModel.accountType, mode: .privateKeys)
                            .onFirstAppear { stat(page: .privateKeys, event: .open(page: .moneroPrivateKeys)) }
                    }
                }
            }
            .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
        }
        .navigationTitle("private_keys.title".localized)
    }

    private func option(title: String, description: String, @ViewBuilder destination: () -> some View) -> some View {
        ListSection(footer: description) {
            NavigationRow(destination: destination) {
                ThemeText(title, style: .body)
                    .frame(maxWidth: .infinity, alignment: .leading)
                ThemeImage("arrow_b_right", size: .iconSize20)
            }
        }
    }
}
