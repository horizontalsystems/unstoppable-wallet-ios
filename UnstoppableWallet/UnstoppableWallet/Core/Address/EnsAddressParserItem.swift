import EvmKit
import MarketKit
import RxSwift

class EnsAddressParserItem {
    static let registrars = ["eth", "xyz", "luxe", "kred", "art"]

    private let provider: ENSProvider
    private let rawAddressParserItem: IAddressParserItem

    init?(rpcSource: RpcSource, rawAddressParserItem: IAddressParserItem) {
        guard let provider = try? ENSProvider.instance(rpcSource: rpcSource) else {
            return nil
        }

        self.provider = provider
        self.rawAddressParserItem = rawAddressParserItem
    }

    private func rawAddressHandle(address: Address) -> Single<Address> {
        rawAddressParserItem
            .handle(address: address.raw)
            .map { rawAddress in
                Address(raw: rawAddress.raw, domain: address.domain, blockchainType: address.blockchainType)
            }
    }
}

extension EnsAddressParserItem: IAddressParserItem {
    var blockchainType: BlockchainType { rawAddressParserItem.blockchainType }

    func handle(address: String) -> Single<Address> {
        let blockchainType = blockchainType
        return provider.address(domain: address)
            .flatMap { [weak self] resolvedAddress in
                let address = Address(raw: resolvedAddress.hex, domain: address, blockchainType: blockchainType)
                return self?.rawAddressHandle(address: address) ?? Single.just(address)
            }.catchError { _ in
                .error(AddressService.AddressError.invalidAddress(blockchainName: blockchainType.uid))
            }
    }

    func isValid(address: String) -> Single<Bool> {
        let parts = address.trimmingCharacters(in: .whitespaces).components(separatedBy: ".")
        if parts.count > 1,
           let last = parts.last?.lowercased()
        {
            return .just(Self.registrars.contains(last))
        }

        return .just(false)
    }
}
