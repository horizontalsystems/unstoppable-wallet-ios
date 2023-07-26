import UIKit
import HsToolKit

struct CoinzixVerifyModule {

    static func viewController(mode: Mode, twoFactorTypes: [CoinzixCexProvider.TwoFactorType], returnViewController: UIViewController? = nil) -> UIViewController? {
        let verifyService: ICoinzixVerifyService

        switch mode {
        case .login(let token, let secret):
            verifyService = LoginCoinzixVerifyService(
                    token: token,
                    secret: secret,
                    networkManager: App.shared.networkManager,
                    accountFactory: App.shared.accountFactory,
                    accountManager: App.shared.accountManager
            )
        case .withdraw(let orderId):
            guard let account = App.shared.accountManager.activeAccount else {
                return nil
            }

            guard case .cex(let cexAccount) = account.type else {
                return nil
            }

            guard case .coinzix(let authToken, let secret) = cexAccount else {
                return nil
            }

            let provider = CoinzixCexProvider(networkManager: App.shared.networkManager, authToken: authToken, secret: secret)
            verifyService = WithdrawCoinzixVerifyService(orderId: orderId, provider: provider)
        }

        let service = CoinzixVerifyService(twoFactorTypes: twoFactorTypes, verifyService: verifyService)
        let viewModel = CoinzixVerifyViewModel(service: service)
        return CoinzixVerifyViewController(viewModel: viewModel, returnViewController: returnViewController)
    }

}

extension CoinzixVerifyModule {

    enum Mode {
        case login(token: String, secret: String)
        case withdraw(orderId: Int)
    }

}
