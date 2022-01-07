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

    private func coinTypeInfo(transactions: [Transaction]) -> CoinTypeInfo {
        let transactionCoinTypes = transactions.map { coinType(address: $0.contractAddress) }
        let coinTypes = Array(Set(transactionCoinTypes))
        let lastTransactionBlockNumber = transactions.last.flatMap { Int($0.blockNumber) }

        return CoinTypeInfo(coinTypes: coinTypes, lastTransactionBlockNumber: lastTransactionBlockNumber)
    }

}

extension EnableCoinsEip20Provider {

    func coinTypeInfoSingle(address: String, startBlock: Int? = nil) -> Single<CoinTypeInfo> {
        let parameters: Parameters = [
            "module": "account",
            "action": "tokentx",
            "address": address,
            "startblock": startBlock ?? 0,
            "sort": "asc",
            "apikey": apiKey
        ]

        let request = networkManager.session.request(url, parameters: parameters)

        return networkManager.single(request: request).map { [unowned self] (response: Response) -> CoinTypeInfo in
            coinTypeInfo(transactions: response.result)
        }
    }

}

extension EnableCoinsEip20Provider {

    enum Mode {
        case erc20
        case bep20
    }

    struct CoinTypeInfo {
        let coinTypes: [CoinType]
        let lastTransactionBlockNumber: Int?
    }

    struct Response: ImmutableMappable {
        let status: String
        let result: [Transaction]

        init(map: Map) throws {
            status = try map.value("status")
            result = try map.value("result")
        }
    }

    struct Transaction: ImmutableMappable {
        let blockNumber: String
        let contractAddress: String

        init(map: Map) throws {
            blockNumber = try map.value("blockNumber")
            contractAddress = try map.value("contractAddress")
        }
    }

}
