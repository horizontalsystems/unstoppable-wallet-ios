import RxSwift
import MarketKit

class UDNAddressParserItem {

    private let provider = AddressResolutionProvider()
    private let coinCode: String
    private let platformCoinCode: String?
    private let chain: String?

    init(coinCode: String, platformCoinCode: String?, chain: String?) {
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

}

extension UDNAddressParserItem: IAddressParserItem {

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
                .flatMap { result in
                    switch result {
                    case .success(let resolvedAddress):
                        return Single.just(Address(raw: resolvedAddress, domain: address))
                    case .failure(let error):
                        return Single.error(error)
                    }
                }
    }

    func isValid(address: String) -> Single<Bool> {
        if !address.contains(".") {
            return Single.just(false)
        }

        return provider.isValid(domain: address)
    }

}

extension UDNAddressParserItem {

    static func chainCoinCode(coinType: CoinType) -> String? {
        switch coinType {
        case .ethereum, .erc20, .binanceSmartChain, .bep20, .polygon, .mrc20: return "ETH"
        default: return nil
        }
    }

    static func chain(coinType: CoinType) -> String? {
        switch coinType {
        case .erc20: return "ERC20"
        case .bep20: return "BEP20"
        case .polygon, .mrc20: return "MATIC"
        default: return nil
        }
    }

}
