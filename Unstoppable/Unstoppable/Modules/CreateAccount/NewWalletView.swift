import SwiftUI

struct NewWalletView: View {
    @Binding var isPresented: Bool
    var parentPresented: Binding<Bool>?
    var showClose: Bool = false

    @State private var standardWalletPresented = false
    @State private var passkeyWalletPresented = false
    @State private var passkeyTermsPresented = false
    @State private var smartAccountWalletPresented = false
    @State private var smartAccountTermsPresented = false

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

                row(icon: "face_id", title: "new_wallet.smart_account".localized, description: "new_wallet.smart_account.description".localized) {
                    if Core.shared.termsManager.passkeyTermsAccepted {
                        smartAccountWalletPresented = true
                    } else {
                        smartAccountTermsPresented = true
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
        .navigationDestination(isPresented: $smartAccountWalletPresented) {
            CreateAccountView(walletType: .smartAccount, isPresented: parentPresented ?? $isPresented)
        }
        .navigationDestination(isPresented: $smartAccountTermsPresented) {
            PasskeyTermsView(isPresented: parentPresented ?? $isPresented, walletType: .smartAccount)
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
