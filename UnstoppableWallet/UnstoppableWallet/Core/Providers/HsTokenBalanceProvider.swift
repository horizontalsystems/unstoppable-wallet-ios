import Foundation
import RxSwift
import ObjectMapper
import HsToolKit
import Alamofire
import MarketKit

class HsTokenBalanceProvider {
    private let balanceThreshold = Decimal(sign: .plus, exponent: -8, significand: 1)
    private let priceThreshold: Decimal = 1 // in usd

    private let networkManager: NetworkManager
    private let marketKit: MarketKit.Kit
    private let apiUrl: String
    private let headers: HTTPHeaders?

    init(networkManager: NetworkManager, marketKit: MarketKit.Kit, appConfigProvider: AppConfigProvider) {
        self.networkManager = networkManager
        self.marketKit = marketKit
        apiUrl = appConfigProvider.marketApiUrl

        headers = appConfigProvider.hsProviderApiKey.flatMap { HTTPHeaders([HTTPHeader(name: "apikey", value: $0)]) }
    }

    private func addressInfo(response: AddressResponse) -> EvmAccountManager.AddressInfo {
        let addresses: [String] = response.balances.compactMap { balance in
            guard balance.value > balanceThreshold else {
                return nil
            }

            guard let price = balance.price, balance.value * price >= priceThreshold else {
                return nil
            }

            return balance.address
        }

        return EvmAccountManager.AddressInfo(blockNumber: response.blockNumber, addresses: addresses)
    }

    private func chain(blockchainType: BlockchainType) -> String {
        switch blockchainType {
        case .ethereum: return "ethereum"
        case .binanceSmartChain: return "bsc"
        case .polygon: return "matic"
        case .optimism: return "optimism"
        case .arbitrumOne: return "arbitrum-one"
        default: return blockchainType.uid
        }
    }

}

extension HsTokenBalanceProvider {

    func addressInfoSingle(blockchainType: BlockchainType, address: String) -> Single<EvmAccountManager.AddressInfo> {
        let parameters: Parameters = [
            "chain": chain(blockchainType: blockchainType)
        ]

        let request = networkManager.session.request("\(apiUrl)/v1/addresses/\(address)/coins", parameters: parameters, headers: headers)
        return networkManager.single(request: request).map { [unowned self] response in
            addressInfo(response: response)
        }
    }

    func blockNumberSingle(blockchainType: BlockchainType) -> Single<Int> {
        let request = networkManager.session.request("\(apiUrl)/v1/chain/\(chain(blockchainType: blockchainType))", headers: headers)
        return networkManager.single(request: request).map { (response: ChainResponse) in
            response.blockNumber
        }
    }

}

extension HsTokenBalanceProvider {

    private struct AddressResponse: ImmutableMappable {
        let blockNumber: Int
        let balances: [BalanceResponse]

        init(map: Map) throws {
            blockNumber = try map.value("block_number")
            balances = try map.value("balances")
        }
    }

    private struct BalanceResponse: ImmutableMappable {
        let address: String
        let value: Decimal
        let price: Decimal?

        init(map: Map) throws {
            address = try map.value("address")
            value = try map.value("value", using: HsTokenBalanceProvider.stringToDecimalTransform)
            price = try? map.value("price", using: HsTokenBalanceProvider.stringToDecimalTransform)
        }
    }

    private struct ChainResponse: ImmutableMappable {
        let blockNumber: Int

        init(map: Map) throws {
            blockNumber = try map.value("block_number")
        }
    }

    private static let stringToDecimalTransform: TransformOf<Decimal, String> = TransformOf(fromJSON: { string -> Decimal? in
        guard let string = string else { return nil }
        return Decimal(string: string)
    }, toJSON: { (value: Decimal?) in
        guard let value = value else { return nil }
        return value.description
    })

}
