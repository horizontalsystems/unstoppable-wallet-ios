import RxSwift

class SpamAddressDetector {
    private let spamAddressManager: SpamAddressManager

    init() {
        spamAddressManager = App.shared.spamAddressManager
    }
}

extension SpamAddressDetector: IAddressSecurityCheckerItem {
    func handle(address: Address) -> Single<AddressSecurityCheckerChain.SecurityIssue?> {
        var result: AddressSecurityCheckerChain.SecurityIssue? = nil

        let spamAddress = spamAddressManager.find(address: address.raw.uppercased())
        if let spamAddress {
            result = .spam(transactionHash: spamAddress.transactionHash.hs.hexString)
        }

        return Single.just(result)
    }
}
