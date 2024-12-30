import RxSwift

class SpamAddressDetector {
    private let spamAddressManager: SpamAddressManager

    init() {
        spamAddressManager = App.shared.spamAddressManager
    }
}

extension SpamAddressDetector: IAddressSecurityCheckerItem {
    func handle(address: Address) -> Single<AddressSecurityCheckerChain.SecurityCheckResult> {
        let result: AddressSecurityCheckerChain.SecurityCheckResult

        let spamAddress = spamAddressManager.find(address: address.raw.uppercased())
        if let spamAddress {
            result = .spam(transactionHash: spamAddress.transactionHash.hs.hexString)
        } else {
            result = .valid
        }

        return Single.just(result)
    }
}
