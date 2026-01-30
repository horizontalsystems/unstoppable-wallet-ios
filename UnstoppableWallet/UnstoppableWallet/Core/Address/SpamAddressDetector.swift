import MarketKit

class SpamAddressDetector {
    private let spamWrapper: SpamWrapper

    init() {
        spamWrapper = Core.shared.spamWrapper
    }
}

extension SpamAddressDetector: IAddressSecurityChecker {
    func isClear(address: Address, token _: Token) async throws -> Bool {
        !spamWrapper.isSpam(address: address.raw.lowercased())
    }
}
