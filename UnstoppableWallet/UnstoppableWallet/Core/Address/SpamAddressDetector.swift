import MarketKit

class SpamAddressDetector {
    private let spamAddressManager: SpamAddressManager

    init() {
        spamAddressManager = App.shared.spamAddressManager
    }
}

extension SpamAddressDetector: IAddressSecurityChecker {
    func check(address: Address, token _: Token) async throws -> Bool {
        spamAddressManager.find(address: address.raw.uppercased()) != nil
    }
}
