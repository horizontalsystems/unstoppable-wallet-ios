import SwiftUI

struct WalletTokenHeaderStatusView: View {
    @ObservedObject var viewModel: WalletTokenViewModel

    var body: some View {
        switch viewModel.state {
        case let .syncing(progress, _, _), let .customSyncing(_, _, progress):
            ProgressView(value: max(0.1, Float(progress ?? 10) / 100))
                .progressViewStyle(DeterminiteSpinnerStyle())
                .frame(size: 20)
                .spinning()
        case .notSynced:
            if viewModel.isReachable {
                Image("warning_filled").icon(size: .iconSize20, colorStyle: .red)
                    .tappablePadding(.margin12) {
                        Coordinator.shared.presentBalanceError(wallet: viewModel.wallet, state: viewModel.state)
                    }
            }
        default: EmptyView()
        }
    }
}
