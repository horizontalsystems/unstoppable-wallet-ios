import Foundation
import EthereumKit

struct SwapApproveModule {

    static func instance(coin: Coin, spenderAddress: Address, amount: Decimal, delegate: ISwapApproveDelegate) -> UIViewController? {
        guard let wallet = App.shared.walletManager.wallets.first(where: { $0.coin == coin }),
              let adapter = App.shared.adapterManager.adapter(for: wallet),
              let feeRateProvider = App.shared.feeRateProviderFactory.provider(coin: coin),
              let feeAdapter = FeeAdapterFactory().swapAdapter(adapter: adapter),
              let sendAdapter = adapter as? Erc20Adapter else {

            return nil
        }

        let service = SwapApproveService(feeAdapter: feeAdapter, provider: feeRateProvider, sendAdapter: sendAdapter)
        let viewModel = SwapApproveViewModel(service: service, feeModule: FeeModule.module(), coin: coin, amount: amount, spenderAddress: spenderAddress)
        let view = SwapApproveViewController(viewModel: viewModel, delegate: delegate)

        return view.toBottomSheet
    }

}

enum ApproveState {
    case idle
    case loading
    case success
    case error(error: Error)
}

protocol ISwapApproveDelegate {
    func didApprove()
}

extension SwapApproveModule {

    struct ViewItem {
        let coinCode: String
        let amount: String?
        let transactionSpeed: String?
    }

}
