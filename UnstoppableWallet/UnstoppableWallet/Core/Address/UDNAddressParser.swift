import RxSwift

class UDNAddressParserItem {

    private let provider = AddressResolutionProvider()
    private let coinCode: String
    private let chain: String?
    private let isResolutionEnabled: Bool

    init(coinCode: String, chain: String?, isResolutionEnabled: Bool = true) {
        self.coinCode = coinCode
        self.chain = chain
        self.isResolutionEnabled = isResolutionEnabled
    }

    private func resolve(domain: String) -> Single<Address> {
        provider
                .resolveSingle(domain: domain, ticker: coinCode, chain: chain)
                .catchError { _ in Single.error(AddressService.AddressError.invalidAddress) }
                .flatMap { resolvedAddress in
                    Single.just(Address(raw: resolvedAddress, domain: domain))
                }
    }

}

extension UDNAddressParserItem: IAddressParserItem {

    func handle(address: String) -> Single<Address> {
        provider
                .resolveSingle(domain: address, ticker: coinCode, chain: chain)
                .catchError { _ in Single.error(AddressService.AddressError.invalidAddress) }
                .flatMap { resolvedAddress in
                    Single.just(Address(raw: resolvedAddress, domain: address))
                }
    }

    func isValid(address: String) -> Single<Bool> {
        if !address.contains(".") {
            return Single.just(false)
        }

        return provider.isValid(domain: address)
    }

}
