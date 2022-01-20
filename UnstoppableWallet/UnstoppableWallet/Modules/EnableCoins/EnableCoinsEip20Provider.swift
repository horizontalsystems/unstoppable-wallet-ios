import RxSwift
import ObjectMapper
import HsToolKit
import Alamofire
import MarketKit

class EnableCoinsEip20Provider {
    private let networkManager: NetworkManager
    private let appConfigProvider: AppConfigProvider
    private let mode: Mode

    init(networkManager: NetworkManager, appConfigProvider: AppConfigProvider, mode: Mode) {
        self.networkManager = networkManager
        self.appConfigProvider = appConfigProvider
        self.mode = mode
    }

    private var url: String {
        switch mode {
        case .erc20: return "https://api.etherscan.io/api"
        case .bep20: return "https://api.bscscan.com/api"
        }
    }

    private var apiKey: String {
        switch mode {
        case .erc20: return appConfigProvider.etherscanKey
        case .bep20: return appConfigProvider.bscscanKey
        }
    }

    private func coinType(address: String) -> CoinType {
        switch mode {
        case .erc20: return .erc20(address: address)
        case .bep20: return .bep20(address: address)
        }
    }

    private func coinTypes(transactions: [Transaction]) -> [CoinType] {
        let transactionCoinTypes = transactions.map { coinType(address: $0.contractAddress) }
        return Array(Set(transactionCoinTypes))
    }

}

extension EnableCoinsEip20Provider {

    func blockNumberSingle() -> Single<Int> {
        let parameters: Parameters = [
            "module": "proxy",
            "action": "eth_blockNumber",
            "apikey": apiKey
        ]

        let request = networkManager.session.request(url, parameters: parameters)

        return networkManager.single(request: request).map { [unowned self] (response: RpcResponse) -> Int in
            Int(response.result.stripHexPrefix(), radix: 16) ?? 0
        }
    }

    func coinTypesSingle(address: String, startBlock: Int = 0) -> Single<[CoinType]> {
        let parameters: Parameters = [
            "module": "account",
            "action": "tokentx",
            "address": address,
            "startblock": startBlock,
            "sort": "asc",
            "apikey": apiKey
        ]

        let request = networkManager.session.request(url, parameters: parameters)

        return networkManager.single(request: request).map { [unowned self] (response: Response) -> [CoinType] in
            coinTypes(transactions: response.result)
        }
    }

}

extension EnableCoinsEip20Provider {

    enum Mode {
        case erc20
        case bep20
    }

    struct Response: ImmutableMappable {
        let status: String
        let result: [Transaction]

        init(map: Map) throws {
            status = try map.value("status")
            result = try map.value("result")
        }
    }

    struct RpcResponse: ImmutableMappable {
        let result: String

        init(map: Map) throws {
            result = try map.value("result")
        }
    }

    struct Transaction: ImmutableMappable {
        let contractAddress: String

        init(map: Map) throws {
            contractAddress = try map.value("contractAddress")
        }
    }

}
