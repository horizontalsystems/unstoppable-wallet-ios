import MarketKit

class SpamAddressDetector {
    private let spamManager: SpamManagerNew

    init() {
        spamManager = Core.shared.spamManager
    }
}

extension SpamAddressDetector: IAddressSecurityChecker {
    func isClear(address: Address, token _: Token) async throws -> Bool {
        !spamManager.isSpam(address: address.raw.lowercased())
    }
}
