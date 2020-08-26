import Foundation
import EthereumKit

struct SwapApproveModule {

    static func instance(coin: Coin, spenderAddress: Address, amount: Decimal, delegate: ISwapApproveDelegate) -> UIViewController? {
        guard let wallet = App.shared.walletManager.wallets.first(where: { $0.coin == coin }),
              let erc20Adapter = App.shared.adapterManager.adapter(for: wallet) as? IErc20Adapter,
              let balanceAdapter = App.shared.adapterManager.balanceAdapter(for: wallet),
              let feePresenter = FeeModule.instance(erc20Adapter: erc20Adapter, balanceAdapter: balanceAdapter, coin: coin, amount: amount, spenderAddress: spenderAddress) else {

            return nil
        }

        let service = SwapApproveService(feeService: feePresenter.service, sendAdapter: erc20Adapter, coin: coin, amount: amount, spenderAddress: spenderAddress)
        let viewModel = SwapApproveViewModel(service: service, feePresenter: feePresenter)
        let view = SwapApproveViewController(viewModel: viewModel, delegate: delegate)

        return view.toBottomSheet
    }

}

protocol ISwapApproveDelegate {
    func didApprove()
}

extension SwapApproveModule {

    enum ApproveState {
        case approveNotAllowed
        case approveAllowed
        case loading
        case success
        case error(error: Error)
    }

}