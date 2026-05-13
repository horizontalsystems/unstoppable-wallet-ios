import Combine
import MarketKit
import SwiftUI

class MevProtectionHelper {
    var isActive: Bool = false
    private let securityManager = Core.shared.securityManager

    func section() -> SendDataSection {
        isActive = securityManager.swapProtectionEnabled

        let binding = Binding<Bool>(
            get: { [weak self] in
                if Core.shared.purchaseManager.activated(.swapProtection) {
                    self?.isActive ?? false
                } else {
                    false
                }
            },
            set: { [weak self] newValue in
                let successBlock = { [weak self] in
                    self?.isActive = newValue
                    self?.securityManager.setSwapProtection(enabled: newValue)
                }

                Coordinator.shared.performAfterPurchase(premiumFeature: .swapProtection, page: .swap, trigger: .mevProtection) {
                    successBlock()
                }
            }
        )

        return SendDataSection([
            .mevProtection(isOn: binding),
        ], isList: false)
    }
}
