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
                self?.isActive ?? false
            },
            set: { [weak self] newValue in
                self?.isActive = newValue
                self?.securityManager.setSwapProtection(enabled: newValue)
            }
        )

        return SendDataSection([
            .mevProtection(isOn: binding),
        ], isList: false)
    }
}
