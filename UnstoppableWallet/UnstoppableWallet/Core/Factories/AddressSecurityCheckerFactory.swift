protocol IAddressSecurityChecker {
    func check(address: Address) async throws -> Bool
}

enum AddressSecurityCheckerFactory {
    static func addressSecurityChecker(type: AddressSecurityIssueType) -> IAddressSecurityChecker {
        switch type {
        case .phishing: return SpamAddressDetector()
        case .sanctioned: return ChainalysisAddressValidator()
        }
    }
}
