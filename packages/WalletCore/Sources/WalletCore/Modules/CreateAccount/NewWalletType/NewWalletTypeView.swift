import SwiftUI

struct NewWalletTypeView: View {
    @Binding var isPresented: Bool
    var parentPresented: Binding<Bool>?
    var showClose: Bool = false

    @State private var standardWalletPresented = false
    @State private var passkeyWalletPresented = false
    @State private var passkeyTermsPresented = false

    var body: some View {
        ScrollableThemeView {
            ListSection {
                row(
                    icon: "face_id",
                    title: "new_wallet.passkey".localized,
                    subtitle: "new_wallet.passkey.description".localized,
                    accessibilityIdentifier: TestTags.createTypePasskey
                ) {
                    if Core.shared.termsManager.passkeyTermsAccepted {
                        passkeyWalletPresented = true
                    } else {
                        passkeyTermsPresented = true
                    }
                }

                row(
                    icon: "list",
                    title: "new_wallet.standard".localized,
                    subtitle: "new_wallet.standard.description".localized,
                    accessibilityIdentifier: TestTags.createTypeStandard
                ) {
                    standardWalletPresented = true
                }
            }
            .padding(EdgeInsets(top: .margin16, leading: .margin16, bottom: .margin32, trailing: .margin16))
        }
        .navigationTitle("new_wallet.title".localized)
        .toolbar {
            if showClose {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: {
                        isPresented = false
                    }) {
                        Image("close")
                    }
                }
            }
        }
        .navigationDestination(isPresented: $standardWalletPresented) {
            CreateAccountView(walletType: .regular, isPresented: parentPresented ?? $isPresented)
        }
        .navigationDestination(isPresented: $passkeyWalletPresented) {
            CreateAccountView(walletType: .passkey, isPresented: parentPresented ?? $isPresented)
        }
        .navigationDestination(isPresented: $passkeyTermsPresented) {
            PasskeyTermsView(isPresented: parentPresented ?? $isPresented)
        }
    }

    private func row(icon: String, title: String, subtitle: String, accessibilityIdentifier: String, action: @escaping () -> Void) -> some View {
        Cell(
            left: {
                ThemeImage(icon, size: .iconSize24)
            },
            middle: {
                MultiText(title: title, subtitle: subtitle)
            },
            right: {
                Image.disclosureIcon
            },
            action: action
        )
        .accessibilityIdentifier(accessibilityIdentifier)
    }
}
