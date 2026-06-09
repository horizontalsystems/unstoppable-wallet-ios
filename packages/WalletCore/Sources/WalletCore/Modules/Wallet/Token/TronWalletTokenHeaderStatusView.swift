import SwiftUI

struct TronWalletTokenHeaderStatusView: View {
    @ObservedObject var viewModel: WalletTokenViewModel
    @ObservedObject var tronViewModel: TronWalletTokenViewModel

    var body: some View {
        if tronViewModel.accountActive {
            WalletTokenHeaderStatusView(viewModel: viewModel)
        } else {
            Image("warning_filled").icon(size: .iconSize20, colorStyle: .yellow)
                .tappablePadding(.margin12) {
                    tronViewModel.showPopup()
                }
        }
    }
}
