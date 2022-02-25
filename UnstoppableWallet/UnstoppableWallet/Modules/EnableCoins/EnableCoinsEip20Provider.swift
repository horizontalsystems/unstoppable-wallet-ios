import RxSwift
import ObjectMapper
import HsToolKit
import Alamofire
import MarketKit

class EnableCoinsEip20Provider {
    private let networkManager: NetworkManager
    private let blockchain: EvmBlockchain

    init(networkManager: NetworkManager, blockchain: EvmBlockchain) {
        self.networkManager = networkManager
        self.blockchain = blockchain
    }

    private func baseUrl(syncSource: EvmSyncSource) -> String {
        switch syncSource.transactionSource.type {
        case .etherscan(let baseUrl, _, _): return baseUrl
        }
    }

    private func url(syncSource: EvmSyncSource) -> String {
        "\(baseUrl(syncSource: syncSource))/api"
    }

    private func apiKey(syncSource: EvmSyncSource) -> String {
        switch syncSource.transactionSource.type {
        case .etherscan(_, _, let apiKey): return apiKey
        }
    }

    private func coinTypes(transactions: [Transaction]) -> [CoinType] {
        let transactionCoinTypes = transactions.map { blockchain.evm20CoinType(address: $0.contractAddress) }
        return Array(Set(transactionCoinTypes))
    }

}

extension EnableCoinsEip20Provider {

    func blockNumberSingle(syncSource: EvmSyncSource) -> Single<Int> {
        let parameters: Parameters = [
            "module": "proxy",
            "action": "eth_blockNumber",
            "apikey": apiKey(syncSource: syncSource)
        ]

        let request = networkManager.session.request(url(syncSource: syncSource), parameters: parameters)

        return networkManager.single(request: request).map { (response: RpcResponse) -> Int in
            Int(response.result.stripHexPrefix(), radix: 16) ?? 0
        }
    }

    func coinTypesSingle(syncSource: EvmSyncSource, address: String, startBlock: Int = 0) -> Single<[CoinType]> {
        let parameters: Parameters = [
            "module": "account",
            "action": "tokentx",
            "address": address,
            "startblock": startBlock,
            "sort": "asc",
            "apikey": apiKey(syncSource: syncSource)
        ]

        let request = networkManager.session.request(url(syncSource: syncSource), parameters: parameters)

        return networkManager.single(request: request).map { [unowned self] (response: Response) -> [CoinType] in
            coinTypes(transactions: response.result)
        }
    }

}

extension EnableCoinsEip20Provider {

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
