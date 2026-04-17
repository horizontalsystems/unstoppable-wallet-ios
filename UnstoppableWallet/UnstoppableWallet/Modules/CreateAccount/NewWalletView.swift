import SwiftUI

struct NewWalletView: View {
    @Binding var isParentPresented: Bool
    var showClose: Bool = false

    @State private var standardWalletPresented = false
    @State private var passkeyWalletPresented = false
    @State private var passkeyTermsPresented = false

    var body: some View {
        ScrollableThemeView {
            ListSection {
                row(icon: "list", title: "new_wallet.standard".localized, description: "new_wallet.standard.description".localized) {
                    standardWalletPresented = true
                }

                row(icon: "face_id", title: "new_wallet.passkey".localized, description: "new_wallet.passkey.description".localized) {
                    if Core.shared.termsManager.passkeyTermsAccepted {
                        passkeyWalletPresented = true
                    } else {
                        passkeyTermsPresented = true
                    }
                }
            }
            .padding(EdgeInsets(top: 12, leading: 16, bottom: 32, trailing: 16))
        }
        .navigationTitle("new_wallet.title".localized)
        .toolbar {
            if showClose {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: {
                        isParentPresented = false
                    }) {
                        Image("close")
                    }
                }
            }
        }
        .navigationDestination(isPresented: $standardWalletPresented) {
            CreateAccountView(walletType: .regular, isParentPresented: $isParentPresented)
        }
        .navigationDestination(isPresented: $passkeyWalletPresented) {
            CreateAccountView(walletType: .passkey, isParentPresented: $isParentPresented)
        }
        .navigationDestination(isPresented: $passkeyTermsPresented) {
            PasskeyTermsView(isParentPresented: $isParentPresented)
        }
    }

    @ViewBuilder private func row(icon: String, title: String, description: String, action: @escaping () -> Void) -> some View {
        Cell(
            left: {
                ThemeImage(icon, size: 24)
            },
            middle: {
                MultiText(title: title, subtitle: description)
            },
            right: {
                Image.disclosureIcon
            },
            action: action
        )
    }
}
