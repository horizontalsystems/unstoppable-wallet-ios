import BigInt
import Eip20Kit
import EvmKit
import Foundation
import MarketKit

class MultiSwapApproveViewModel: ObservableObject {
    let token: Token
    let amount: Decimal
    private let spenderAddress: Address
    private let approveDataProvider: IApproveDataProvider?

    @Published var unlimitedAmount = false

    init(token: Token, amount: Decimal, spenderAddress: Address) {
        self.token = token
        self.amount = amount
        self.spenderAddress = spenderAddress
        approveDataProvider = Core.shared.adapterManager.adapter(for: token) as? IApproveDataProvider
    }
}

extension MultiSwapApproveViewModel {
    var sendData: SendData? {
        let amount = unlimitedAmount ? .init(2).power(256) - 1 : token.fractionalMonetaryValue(value: amount)
        return try? approveDataProvider?.approveSendData(token: token, spenderAddress: spenderAddress, amount: amount)
    }

    func set(unlimitedAmount: Bool) {
        guard self.unlimitedAmount != unlimitedAmount else {
            return
        }

        self.unlimitedAmount = unlimitedAmount
    }
}
