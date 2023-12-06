import MarketKit
import RxSwift

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
        let failure = Single.just(Result<String, Error>.failure(AddressService.AddressError.invalidAddress(blockchainName: nil)))

        guard index < singles.count else {
            return failure
        }

        return singles[index].flatMap { [weak self] resultOfAddress in
            switch resultOfAddress {
            case let .success(address):
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
                Address(raw: rawAddress.raw, domain: address.domain, blockchainType: address.blockchainType)
            }
    }
}

extension UdnAddressParserItem: IAddressParserItem {
    var blockchainType: BlockchainType { rawAddressParserItem.blockchainType }

    func handle(address: String) -> Single<Address> {
        var singles = [Single<Result<String, Error>>]()
        if let chain {
            singles.append(provider.resolveSingle(domain: address, ticker: coinCode, chain: chain))
        }
        singles.append(provider.resolveSingle(domain: address, ticker: coinCode, chain: nil))
        if let platformCoinCode {
            singles.append(provider.resolveSingle(domain: address, ticker: platformCoinCode, chain: nil))
        }

        return resolve(singles: singles)
            .flatMap { [weak self, blockchainType] result in
                switch result {
                case let .success(resolvedAddress):
                    let address = Address(raw: resolvedAddress, domain: address, blockchainType: blockchainType)
                    return self?.rawAddressHandle(address: address) ?? Single.just(address)
                case let .failure(error):
                    return Single.error(error)
                }
            }
    }

    func isValid(address: String) -> Single<Bool> {
        let parts = address.components(separatedBy: ".")
        if parts.count > 1,
           let last = parts.last?.lowercased(),
           !exceptionRegistrars.contains(last)
        {
            return provider.isValid(domain: address)
        }

        return .just(false)
    }
}

extension UdnAddressParserItem {
    static func chainCoinCode(blockchainType: BlockchainType) -> String {
        switch blockchainType {
        case .bitcoin: return "BTC"
        case .ethereum: return "ETH"
        case .binanceSmartChain: return "ETH"
        case .polygon: return "ETH"
        case .avalanche: return "ETH"
        case .optimism: return "ETH"
        case .arbitrumOne: return "ETH"
        case .litecoin: return "LTC"
        case .dash: return "DASH"
        case .bitcoinCash: return "BCH"
        case .ecash: return "XEC"
        case .zcash: return "ZEC"
        case .binanceChain: return "ETH"
        case .gnosis: return "ETH"
        case .fantom: return "ETH"
        case .tron: return "TRX"
        case .solana: return "SOL"
        case .ton: return "TON"
        case let .unsupported(uid): return uid
        }
    }

    static func chain(token: Token) -> String? {
        switch (token.blockchainType, token.type) {
        case (.ethereum, .eip20), (.optimism, .eip20), (.arbitrumOne, .eip20), (.gnosis, .eip20), (.fantom, .eip20): return "ERC20"
        case (.binanceSmartChain, .native), (.binanceSmartChain, .eip20): return "BEP20"
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

    static func item(rawAddressParserItem: IAddressParserItem, blockchainType: BlockchainType) -> UdnAddressParserItem {
        let item = UdnAddressParserItem(
            rawAddressParserItem: rawAddressParserItem,
            coinCode: chainCoinCode(blockchainType: blockchainType),
            platformCoinCode: nil,
            chain: nil
        )

        item.exceptionRegistrars = EnsAddressParserItem.registrars
        return item
    }
}
