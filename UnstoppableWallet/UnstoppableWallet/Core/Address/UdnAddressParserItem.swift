import RxSwift
import MarketKit

class UdnAddressParserItem {

    private let provider = AddressResolutionProvider()
    private let coinCode: String
    private let platformCoinCode: String?
    private let chain: String?
    private let rawAddressParserItem: IAddressParserItem

    var exceptionRegistrars: [String] = []

    init(rawAddressParserItem: IAddressParserItem, coinCode: String, platformCoinCode: String?, chain: String?) {
        self.rawAddressParserItem = rawAddressParserItem
        self.coinCode = coinCode
        self.platformCoinCode = platformCoinCode
        self.chain = chain
    }

    private func resolve(index: Int = 0, singles: [Single<Result<String, Error>>]) -> Single<Result<String, Error>> {
        let failure = Single.just(Result<String, Error>.failure(AddressService.AddressError.invalidAddress))

        guard index < singles.count else {
            return failure
        }

        return singles[index].flatMap { [weak self] resultOfAddress in
            switch resultOfAddress {
            case .success(let address):
                    return Single.just(Result.success(address))
            case .failure:
                return self?.resolve(index: index + 1, singles: singles) ?? failure
            }
        }
    }

    private func rawAddressHandle(address: Address) -> Single<Address> {
        rawAddressParserItem
                .handle(address: address.raw)
                .map { rawAddress in
                    Address(raw: rawAddress.raw, domain: address.domain)
                }
    }

}

extension UdnAddressParserItem: IAddressParserItem {

    func handle(address: String) -> Single<Address> {
        var singles = [Single<Result<String, Error>>]()
        if let chain = chain {
            singles.append(provider.resolveSingle(domain: address, ticker: coinCode, chain: chain))
        }
        singles.append(provider.resolveSingle(domain: address, ticker: coinCode, chain: nil))
        if let platformCoinCode = platformCoinCode {
            singles.append(provider.resolveSingle(domain: address, ticker: platformCoinCode, chain: nil))
        }

        return resolve(singles: singles)
                .flatMap { [weak self] result in
                    switch result {
                    case .success(let resolvedAddress):
                        let address = Address(raw: resolvedAddress, domain: address)
                        return self?.rawAddressHandle(address: address) ?? Single.just(address)
                    case .failure(let error):
                        return Single.error(error)
                    }
                }
    }

    func isValid(address: String) -> Single<Bool> {
        let parts = address.components(separatedBy: ".")
        if parts.count > 1,
           let last = parts.last?.lowercased(),
           !exceptionRegistrars.contains(last) {

            return provider.isValid(domain: address)
        }

        return .just(false)
    }

}

extension UdnAddressParserItem {

    static func chainCoinCode(blockchainType: BlockchainType) -> String? {
        switch blockchainType {
        case .ethereum: return "ETH"
        case .binanceSmartChain: return "ETH"
        case .polygon: return "ETH"
        case .avalanche: return "ETH"
        case .optimism: return "ETH"
        case .arbitrumOne: return "ETH"
        default: return nil
        }
    }

    static func chain(token: Token) -> String? {
        switch (token.blockchainType, token.type) {
        case (.ethereum, .eip20), (.optimism, .eip20), (.arbitrumOne, .eip20): return "ERC20"
        case (.binanceSmartChain, .eip20): return "BEP20"
        case (.polygon, .native), (.polygon, .eip20): return "MATIC"
        case (.avalanche, .native), (.avalanche, .eip20): return "AVAX"
        default: return nil
        }
    }

}

extension UdnAddressParserItem {

    static func item(rawAddressParserItem: IAddressParserItem, coinCode: String, token: Token?) -> UdnAddressParserItem {
        let item = UdnAddressParserItem(
                rawAddressParserItem: rawAddressParserItem,
                coinCode: coinCode,
                platformCoinCode: token.flatMap { chainCoinCode(blockchainType: $0.blockchainType) },
                chain: token.flatMap { chain(token: $0) }
        )

        item.exceptionRegistrars = EnsAddressParserItem.registrars
        return item
    }

    static func item(rawAddressParserItem: IAddressParserItem, blockchainType: BlockchainType, default: String = "ETH") -> UdnAddressParserItem {
        let item = UdnAddressParserItem(
                rawAddressParserItem: rawAddressParserItem,
                coinCode: chainCoinCode(blockchainType: blockchainType) ?? `default`,
                platformCoinCode: nil,
                chain: nil
        )

        item.exceptionRegistrars = EnsAddressParserItem.registrars
        return item
    }

}
