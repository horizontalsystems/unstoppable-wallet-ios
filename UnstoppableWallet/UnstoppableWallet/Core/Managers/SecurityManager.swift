import Combine
import HsExtensions

class SecurityManager {
    private let localStorage: LocalStorage

    // send settings
    @PostPublished private(set) var securityChecks: [AddressSecurityIssueType: Bool]
    @PostPublished private(set) var secureSendEnabled: Bool

    // swap settings
    @PostPublished private(set) var swapProtectionEnabled: Bool

    // scam protection
    @PostPublished private(set) var scamProtectionEnabled: Bool
    
    // tx filter
    @PostPublished private(set) var spamFilterEnabled: Bool


    init(localStorage: LocalStorage) {
        self.localStorage = localStorage

        let needMigration: Bool = localStorage.addressSecurityIssue(.phishing) == nil

        if needMigration {
            Self.migrateRecipientAddressCheck(storage: localStorage)
        }

        let checks = Self.loadSecurityChecks(storage: localStorage)
        securityChecks = checks
        secureSendEnabled = checks.values.contains(true)
        swapProtectionEnabled = localStorage.useMevProtection
        scamProtectionEnabled = localStorage.scamProtection
        spamFilterEnabled = localStorage.spamFilterEnabled
    }

    private static func migrateRecipientAddressCheck(storage: LocalStorage) {
        let legacyValue: Bool? = storage.recipientAddressCheckOld

        for type in AddressSecurityIssueType.allCases {
            storage.setAddressSecurityIssue(legacyValue ?? type.defaultValue, type: type)
        }
    }

    private static func loadSecurityChecks(storage: LocalStorage) -> [AddressSecurityIssueType: Bool] {
        var result = [AddressSecurityIssueType: Bool]()

        for type in AddressSecurityIssueType.allCases {
            result[type] = storage.addressSecurityIssue(type) ?? type.defaultValue
        }

        return result
    }
}

extension SecurityManager {
    func isCheckEnabled(_ type: AddressSecurityIssueType) -> Bool {
        securityChecks[type] ?? true
    }

    func setCheckEnabled(_ type: AddressSecurityIssueType, enabled: Bool) {
        securityChecks[type] = enabled
        secureSendEnabled = securityChecks.values.contains(true)
        localStorage.setAddressSecurityIssue(enabled, type: type)
    }

    func setSwapProtection(enabled: Bool) {
        swapProtectionEnabled = enabled
        localStorage.useMevProtection = enabled
    }

    func setScamProtection(enabled: Bool) {
        scamProtectionEnabled = enabled
        localStorage.scamProtection = enabled
    }

    func setSpamFilter(enabled: Bool) {
        spamFilterEnabled = enabled
        localStorage.spamFilterEnabled = enabled
    }
}
