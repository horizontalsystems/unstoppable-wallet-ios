import SwiftUI

struct AddWalletView: View {
    @Binding var isParentPresented: Bool
    var showClose: Bool = false

    @State private var newWalletPresented = false
    @State private var existingWalletPresented = false

    var body: some View {
        ScrollableThemeView {
            ListSection {
                row(icon: "plus", title: "add_wallet.new_wallet".localized, description: "add_wallet.new_wallet.description".localized) {
                    newWalletPresented = true
                }

                row(icon: "arrow_in", title: "add_wallet.existing_wallet".localized, description: "add_wallet.existing_wallet.description".localized) {
                    existingWalletPresented = true
                }
            }
            .padding(EdgeInsets(top: 12, leading: 16, bottom: 32, trailing: 16))
        }
        .navigationTitle("add_wallet.title".localized)
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

        .navigationDestination(isPresented: $newWalletPresented) {
            NewWalletView(isParentPresented: $isParentPresented)
        }
        .navigationDestination(isPresented: $existingWalletPresented) {
            RestoreTypeView(type: .wallet, isParentPresented: $isParentPresented)
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
