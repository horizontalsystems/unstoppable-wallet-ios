import RxSwift
import ObjectMapper
import HsToolKit
import Alamofire
import CoinKit

class EnableCoinsEip20Provider {
    private let appConfigProvider: IAppConfigProvider
    private let networkManager: NetworkManager
    private let mode: Mode

    init(appConfigProvider: IAppConfigProvider, networkManager: NetworkManager, mode: Mode) {
        self.appConfigProvider = appConfigProvider
        self.networkManager = networkManager
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

    private func coin(transaction: Transaction) -> Coin? {
        guard !transaction.tokenName.isEmpty, !transaction.tokenSymbol.isEmpty, let decimal = Int(transaction.tokenDecimal) else {
            return nil
        }

        return Coin(title: transaction.tokenName, code: transaction.tokenSymbol, decimal: decimal, type: coinType(address: transaction.contractAddress))
    }

    private func coins(transactions: [Transaction]) -> [Coin] {
        let transactionCoins = transactions.compactMap { coin(transaction: $0) }
        return Array(Set(transactionCoins))
    }

}

extension EnableCoinsEip20Provider {

    func coinsSingle(address: String) -> Single<[Coin]> {
        let parameters: Parameters = [
            "module": "account",
            "action": "tokentx",
            "address": address,
            "sort": "asc",
            "apikey": apiKey
        ]

        let request = networkManager.session.request(url, parameters: parameters)

        return networkManager.single(request: request).map { [weak self] (response: Response) -> [Coin] in
            self?.coins(transactions: response.result) ?? []
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

    struct Transaction: ImmutableMappable {
        let contractAddress: String
        let tokenName: String
        let tokenSymbol: String
        let tokenDecimal: String

        init(map: Map) throws {
            contractAddress = try map.value("contractAddress")
            tokenName = try map.value("tokenName")
            tokenSymbol = try map.value("tokenSymbol")
            tokenDecimal = try map.value("tokenDecimal")
        }
    }

}
