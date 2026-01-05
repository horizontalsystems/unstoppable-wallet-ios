import Combine
import MarketKit
import SwiftUI

class MevProtectionHelper {
    var isActive: Bool = false
    private let localStorage = Core.shared.localStorage

    func section(tokenIn: Token) -> SendDataSection? {
        guard MerkleTransactionAdapter.allowProtection(blockchainType: tokenIn.blockchainType) else {
            isActive = false
            return nil
        }

        isActive = localStorage.useMevProtection

        let binding = Binding<Bool>(
            get: { [weak self] in
                if Core.shared.purchaseManager.activated(.vipSupport) {
                    self?.isActive ?? false
                } else {
                    false
                }
            },
            set: { [weak self] newValue in
                let successBlock = { [weak self] in
                    self?.isActive = newValue
                    self?.localStorage.useMevProtection = newValue
                }

                Coordinator.shared.performAfterPurchase(premiumFeature: .vipSupport, page: .swap, trigger: .mevProtection) {
                    successBlock()
                }
            }
        )

        return .init([
            .mevProtection(isOn: binding),
        ], isList: false)
    }
}
