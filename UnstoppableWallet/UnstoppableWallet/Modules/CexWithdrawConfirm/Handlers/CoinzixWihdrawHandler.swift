import Foundation
import UIKit

class CoinzixWithdrawHandler: ICexWithdrawHandler {
    typealias WithdrawResult = (String, [CoinzixCexProvider.TwoFactorType])

    private let provider: CoinzixCexProvider

    init(provider: CoinzixCexProvider) {
        self.provider = provider
    }

    func withdraw(id: String, network: String?, address: String, amount: Decimal, feeFromAmount: Bool?) async throws -> WithdrawResult {
        try await provider.withdraw(id: id, network: network, address: address, amount: amount, feeFromAmount: feeFromAmount)
    }

    func handle(result: WithdrawResult, viewController: UIViewController) {
        guard let orderId = Int(result.0),
              let module = CoinzixVerifyModule.viewController(mode: .withdraw(orderId: orderId), twoFactorTypes: result.1) else {
            return
        }

        viewController.navigationController?.pushViewController(module, animated: true)
    }

}
