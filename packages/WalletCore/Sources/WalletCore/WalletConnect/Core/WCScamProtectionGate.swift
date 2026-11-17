class WCScamProtectionGate: IWCScamProtectionGate {
    private let securityManager: SecurityManager

    init(securityManager: SecurityManager) {
        self.securityManager = securityManager
    }

    var scamProtectionEnabled: Bool {
        securityManager.scamProtectionEnabled
    }
}
