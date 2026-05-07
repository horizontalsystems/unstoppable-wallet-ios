import Eip20Kit
import EvmKit
import Foundation
import MarketKit

class MultiSwapRevokeViewModel: ObservableObject {
    let token: Token
    private let spenderAddress: Address
    private let approveDataProvider: IApproveDataProvider?

    init(token: Token, spenderAddress: Address) {
        self.token = token
        self.spenderAddress = spenderAddress
        approveDataProvider = Core.shared.adapterManager.adapter(for: token) as? IApproveDataProvider
    }
}

extension MultiSwapRevokeViewModel {
    var sendData: SendData? {
        try? approveDataProvider?.approveSendData(token: token, spenderAddress: spenderAddress, amount: 0)
    }
}
