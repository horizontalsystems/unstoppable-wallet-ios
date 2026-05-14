import SwiftUI

struct SetupWalletView: View {
    @State private var showNewWallet: Bool = false

    var body: some View {
        ThemeNavigationStack {
            ThemeView {
                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading, spacing: 3) {
                        ThemeText(key: "setup_wallet.title", style: .title3)
                        ThemeText(key: "setup_wallet.subtitle", style: .subhead, color: .themeGray)
                    }
                    .padding(.horizontal, 8)
                    .padding(.top, 16)

                    Spacer()

                    VStack(spacing: 12) {
                        SetupWalletOptionRow(
                            icon: "premium_filled",
                            title: "setup_wallet.new_wallet",
                            subtitle: "setup_wallet.new_wallet.description",
                            action: { showNewWallet = true }
                        )

                        SetupWalletOptionRow(
                            icon: "arrow_in",
                            title: "setup_wallet.restore_wallet",
                            subtitle: "setup_wallet.restore_wallet.description",
                            action: {}
                        )
                    }
                    .padding(.bottom, 16)
                }
                .padding(.horizontal, 16)
                .background(
                    Image("setup_wallet")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .allowsHitTesting(false)
                )
            }
            .navigationDestination(isPresented: $showNewWallet) {
                NewWalletView()
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(verbatim: "")
                }
            }
        }
    }
}
