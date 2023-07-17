import Foundation
import UIKit

class BinanceWithdrawHandler: ICexWithdrawHandler {
    typealias WithdrawResult = String

    private let provider: BinanceCexProvider

    init(provider: BinanceCexProvider) {
        self.provider = provider
    }

    func withdraw(id: String, network: String?, address: String, amount: Decimal, feeFromAmount: Bool?) async throws -> String {
        try await provider.withdraw(id: id, network: network, address: address, amount: amount, feeFromAmount: feeFromAmount)
    }

    func handle(result: WithdrawResult, viewController: UIViewController) {

    }

}
