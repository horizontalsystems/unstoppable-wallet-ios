import UIKit
import HsToolKit

struct CoinzixVerifyModule {

    static func viewController(mode: Mode, twoFactorTypes: [TwoFactorType], returnViewController: UIViewController? = nil) -> UIViewController? {
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

            guard case .cex(let cexType) = account.type else {
                return nil
            }

            guard let provider = App.shared.cexProviderFactory.provider(type: cexType) as? CoinzixCexProvider else {
                return nil
            }

            verifyService = WithdrawCoinzixVerifyService(orderId: orderId, provider: provider)
        }

        let service = CoinzixVerifyService(twoFactorTypes: twoFactorTypes, verifyService: verifyService)
        let viewModel = CoinzixVerifyViewModel(service: service)
        return CoinzixVerifyViewController(viewModel: viewModel, returnViewController: returnViewController)
    }

}

extension CoinzixVerifyModule {

    enum TwoFactorType {
        case email
        case authenticator
    }

    enum Mode {
        case login(token: String, secret: String)
        case withdraw(orderId: Int)
    }

}
