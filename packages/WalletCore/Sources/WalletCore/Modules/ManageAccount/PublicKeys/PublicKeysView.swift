import SwiftUI

struct PublicKeysView: View {
    private let viewModel: PublicKeysViewModel

    init(account: Account) {
        viewModel = PublicKeysViewModel(account: account)
    }

    var body: some View {
        ScrollableThemeView {
            VStack(spacing: .margin24) {
                if viewModel.showEvmAddress {
                    option(title: "public_keys.evm_address".localized, description: "public_keys.evm_address.description".localized) {
                        PublicAddressView(kind: .evm, account: viewModel.account)
                            .onFirstAppear { stat(page: .publicKeys, event: .open(page: .evmAddress)) }
                    }
                }

                if viewModel.showTronAddress {
                    option(title: "public_keys.tron_address".localized, description: "public_keys.tron_address.description".localized) {
                        // Tron address intentionally logs the `.evmAddress` page (parity with the UIKit screen)
                        PublicAddressView(kind: .tron, account: viewModel.account)
                            .onFirstAppear { stat(page: .publicKeys, event: .open(page: .evmAddress)) }
                    }
                }

                if viewModel.showAccountExtendedPublicKey {
                    option(title: "public_keys.account_extended_public_key".localized, description: "public_keys.account_extended_public_key.description".localized) {
                        ExtendedKeyView(mode: .accountExtendedPublicKey, accountType: viewModel.accountType)
                            .onFirstAppear { stat(page: .publicKeys, event: .open(page: .accountExtendedPublicKey)) }
                    }
                }

                if viewModel.showMoneroPublicKey {
                    option(title: "public_keys.monero_public_key".localized, description: "public_keys.monero_public_key.description".localized) {
                        // logs page `.privateKeys` intentionally (parity with the UIKit screen)
                        MoneroKeyView(accountType: viewModel.accountType, mode: .publicKeys)
                            .onFirstAppear { stat(page: .privateKeys, event: .open(page: .moneroPublicKeys)) }
                    }
                }

                if viewModel.showZcashViewingKey {
                    option(title: "public_keys.zcash_viewing_key".localized, description: "public_keys.zcash_viewing_key.description".localized, identifier: TestTags.publicKeysZcashViewingKey) {
                        ZcashViewingKeyView(accountType: viewModel.accountType)
                            .onFirstAppear { stat(page: .publicKeys, event: .open(page: .zcashViewingKey)) }
                    }
                }
            }
            .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
        }
        .navigationTitle("public_keys.title".localized)
    }

    private func option(title: String, description: String, identifier: String? = nil, @ViewBuilder destination: () -> some View) -> some View {
        ListSection(footer: description) {
            let link = NavigationLink(destination: destination) {
                Cell(
                    middle: { ThemeText(title, style: .headline2) },
                    right: { Image.disclosureIcon }
                )
            }
            .buttonStyle(CellButtonStyle())

            if let identifier {
                link.accessibilityIdentifier(identifier)
            } else {
                link
            }
        }
    }
}
