import SwiftUI

struct SetupWalletView: View {
    var body: some View {
        ThemeNavigationStack {
            ThemeView {
                ZStack(alignment: .center) {
                    Image("setup_wallet")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity)
                        .allowsHitTesting(false)

                    VStack(alignment: .leading, spacing: 0) {
                        VStack(alignment: .leading, spacing: 3) {
                            ThemeText(key: "setup_wallet.title", style: .title3)
                            ThemeText(key: "setup_wallet.subtitle", style: .subhead, color: .themeGray)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 16)

                        Spacer()

                        VStack(spacing: 12) {
                            SetupWalletOptionRow(
                                icon: "premium_filled",
                                title: "setup_wallet.new_wallet",
                                subtitle: "setup_wallet.new_wallet.description",
                                action: {}
                            )

                            SetupWalletOptionRow(
                                icon: "arrow_in",
                                title: "setup_wallet.restore_wallet",
                                subtitle: "setup_wallet.restore_wallet.description",
                                action: {}
                            )
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(verbatim: "")
                }
            }
        }
    }
}
