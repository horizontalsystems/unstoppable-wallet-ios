import MarketKit

class SpamAddressDetector {
    private let spamManager: SpamManager

    init() {
        spamManager = Core.shared.spamManager
    }
}

extension SpamAddressDetector: IAddressSecurityChecker {
    func isClear(address: Address, token _: Token) async throws -> Bool {
        spamManager.find(address: address.raw.uppercased()) == nil
    }
}
