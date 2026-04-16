import SwiftUI

struct AddWalletView: View {
    @Binding var isParentPresented: Bool
    var showClose: Bool = false

    @State private var newWalletPresented = false
    @State private var existingWalletPresented = false
    @State private var watchPresented = false

    var body: some View {
        ScrollableThemeView {
            AddWalletRowsView(
                onNewWallet: { newWalletPresented = true },
                onExistingWallet: { existingWalletPresented = true },
                onWatchWallet: {
                    watchPresented = true
                    stat(page: .addWallet, event: .open(page: .watchWallet))
                }
            )
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
        .navigationDestination(isPresented: $watchPresented) {
            WatchView(isParentPresented: $isParentPresented)
        }
        .navigationDestination(isPresented: $newWalletPresented) {
            NewWalletView(isParentPresented: $isParentPresented)
        }
        .navigationDestination(isPresented: $existingWalletPresented) {
            RestoreTypeView(isParentPresented: $isParentPresented)
        }
    }
}
