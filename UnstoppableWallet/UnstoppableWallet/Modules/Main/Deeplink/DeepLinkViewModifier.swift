import SwiftUI

struct DeepLinkViewModifier: ViewModifier {
    @StateObject var viewModel = DeepLinkViewModifierModel()

    func body(content: Content) -> some View {
        content
            .sheet(item: $viewModel.presentedCoin) { coin in
                CoinPageView(coin: coin)
            }
            .sheet(item: $viewModel.presentedSendPage) { params in
                ChooseSendTokenListView(
                    allowedBlockchainTypes: params.allowedBlockchainTypes,
                    allowedTokenTypes: params.allowedTokenTypes,
                    address: params.address, amount: params.amount
                )
                .ignoresSafeArea()
            }
            .sheet(item: $viewModel.presentedTonConnect) { params in
                TonConnectConnectView(config: params.config, returnDeepLink: params.returnDeepLink)
            }
            .sheet(item: $viewModel.presentedProposal) { params in
                WalletConnectMainView(account: params.account, session: nil, proposal: params.proposal)
                    .ignoresSafeArea()
            }
            .sheet(item: $viewModel.presentedWalletConnectRequest) { request in
                switch request.payload {
                case is WCSignEthereumTransactionPayload: WCSignEthereumTransactionPayload.view(request: request)
                case is WCSendEthereumTransactionPayload: WCSendEthereumTransactionPayload.view(request: request)
                case is WCSignMessagePayload: WCSignMessagePayload.view(request: request)
                default: EmptyView()
                }
            }
            .modifier(WalletConnectViewModifier(viewModel: viewModel.walletConnectViewModifierModel))
    }
}
