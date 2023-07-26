import Foundation
import UIKit

class CoinzixWithdrawHandler: ICexWithdrawHandler {
    private let provider: CoinzixCexProvider

    init(provider: CoinzixCexProvider) {
        self.provider = provider
    }

    func withdraw(id: String, network: String?, address: String, amount: Decimal, feeFromAmount: Bool?) async throws -> Any {
        try await provider.withdraw(id: id, network: network, address: address, amount: amount, feeFromAmount: feeFromAmount)
    }

    func handle(result: Any, viewController: UIViewController) {
        guard let result = result as? (String, [CoinzixCexProvider.TwoFactorType]) else {
            return
        }

        guard let orderId = Int(result.0),
              let module = CoinzixVerifyModule.viewController(mode: .withdraw(orderId: orderId), twoFactorTypes: result.1) else {
            return
        }

        viewController.navigationController?.pushViewController(module, animated: true)
    }

}
