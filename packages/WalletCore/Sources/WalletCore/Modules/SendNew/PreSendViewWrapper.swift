import SwiftUI

struct PreSendViewWrapper: View {
    let wallet: Wallet
    @Binding var isPresented: Bool

    @State private var path = NavigationPath()

    var body: some View {
        ThemeNavigationStack(path: $path) {
            PreSendView(wallet: wallet, path: $path, isPresented: $isPresented)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        if path.count == 0 {
                            Button(action: {
                                isPresented = false
                            }) {
                                Image("close")
                            }
                        }
                    }
                }
        }
    }
}
