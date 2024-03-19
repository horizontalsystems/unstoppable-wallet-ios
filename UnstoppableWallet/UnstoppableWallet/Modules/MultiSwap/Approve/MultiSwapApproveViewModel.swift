import BigInt
import Eip20Kit
import EvmKit
import Foundation
import MarketKit

class MultiSwapApproveViewModel: ObservableObject {
    let token: Token
    let amount: Decimal
    private let spenderAddress: EvmKit.Address
    private let approveDataProvider: IApproveDataProvider?

    @Published var unlimitedAmount = false

    init(token: Token, amount: Decimal, spenderAddress: EvmKit.Address) {
        self.token = token
        self.amount = amount
        self.spenderAddress = spenderAddress
        approveDataProvider = App.shared.adapterManager.adapter(for: token) as? IApproveDataProvider
    }

    private func syncState() {}
}

extension MultiSwapApproveViewModel {
    var transactionData: TransactionData? {
        let amount = unlimitedAmount ? .init(2).power(256) - 1 : token.fractionalMonetaryValue(value: amount)
        return approveDataProvider?.approveTransactionData(spenderAddress: spenderAddress, amount: amount)
    }

    func set(unlimitedAmount: Bool) {
        guard self.unlimitedAmount != unlimitedAmount else {
            return
        }

        self.unlimitedAmount = unlimitedAmount

        syncState()
    }
}

extension MultiSwapApproveViewModel {
    enum InitError: Error {
        case noApproveDataProvider
    }
}
