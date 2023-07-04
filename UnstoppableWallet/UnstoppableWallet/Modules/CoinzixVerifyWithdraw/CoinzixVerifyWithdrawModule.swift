import UIKit

struct CoinzixVerifyWithdrawModule {

    static func viewController(orderId: Int) -> UIViewController? {
        guard let account = App.shared.accountManager.activeAccount else {
            return nil
        }

        guard case .cex(let type) = account.type else {
            return nil
        }

        guard let provider = App.shared.cexProviderFactory.provider(type: type) as? CoinzixCexProvider else {
            return nil
        }

        let service = CoinzixVerifyWithdrawService(orderId: orderId, provider: provider)
        let viewModel = CoinzixVerifyWithdrawViewModel(service: service)
        return CoinzixVerifyWithdrawViewController(viewModel: viewModel)
    }

}
