import Eip20Kit
import EvmKit
import Foundation
import MarketKit

class MultiSwapRevokeViewModel: ObservableObject {
    let token: Token
    private let spenderAddress: EvmKit.Address
    private let approveDataProvider: IApproveDataProvider?

    init(token: Token, spenderAddress: EvmKit.Address) {
        self.token = token
        self.spenderAddress = spenderAddress
        approveDataProvider = App.shared.adapterManager.adapter(for: token) as? IApproveDataProvider
    }
}

extension MultiSwapRevokeViewModel {
    var transactionData: TransactionData? {
        approveDataProvider?.approveTransactionData(spenderAddress: spenderAddress, amount: 0)
    }
}
