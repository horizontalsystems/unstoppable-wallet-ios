class WCPremiumGate: IWCPremiumGate {
    private let securityManager: SecurityManager
    private let purchaseManager: PurchaseManager

    init(securityManager: SecurityManager, purchaseManager: PurchaseManager) {
        self.securityManager = securityManager
        self.purchaseManager = purchaseManager
    }

    var scamProtectionEnabled: Bool {
        securityManager.scamProtectionEnabled && purchaseManager.activated(.scamProtection)
    }
}
