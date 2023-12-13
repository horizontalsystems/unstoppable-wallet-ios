import Alamofire
import Foundation
import HsToolKit
import MarketKit
import ObjectMapper

class TransakRamp {
    private let networkManager: NetworkManager
    private let apiKey: String

    private let baseUrl = "https://api-stg.transak.com"

    init(networkManager: NetworkManager, apiKey: String) {
        self.networkManager = networkManager
        self.apiKey = apiKey
    }

    private func network(blockchainType: BlockchainType) -> String? {
        switch blockchainType {
        case .bitcoin, .bitcoinCash, .litecoin: return "mainnet"
        case .ethereum: return "ethereum"
        case .binanceSmartChain: return "bsc"
        default: return nil
        }
    }
}

extension TransakRamp: IRamp {
    var title: String {
        "Transak"
    }

    var logoUrl: String {
        "https://assets.transak.com/images/ui/favicon.png"
    }

    func quote(token: Token, fiatAmount: Decimal, currencyCode: String) async throws -> RampQuote? {
        guard let network = network(blockchainType: token.blockchainType) else {
            return nil
        }

        guard fiatAmount > 0 else {
            return nil
        }

        let parameters: Parameters = [
            "partnerApiKey": apiKey,
            "fiatCurrency": currencyCode.uppercased(),
            "cryptoCurrency": token.coin.code.uppercased(),
            "isBuyOrSell": "BUY",
            "network": network,
            "paymentMethod": "credit_debit_card",
            "fiatAmount": fiatAmount.description,
        ]

        let response: Response = try await networkManager.fetch(url: "\(baseUrl)/api/v2/currencies/price", method: .get, parameters: parameters)
        let quote = response.quote

        let queryItems: [String: String] = [
            "apiKey": apiKey,
            "cryptoCurrencyCode": token.coin.code.uppercased(),
            "defaultPaymentMethod": "credit_debit_card",
//            "disableWalletAddressForm": "true",
            "fiatAmount": fiatAmount.description,
            "fiatCurrency": currencyCode.uppercased(),
            "network": network,
//            "walletAddress": "",
        ]

        var components = URLComponents()
        components.scheme = "https"
        components.host = "global-stg.transak.com"
        components.queryItems = queryItems.map { URLQueryItem(name: $0, value: $1) }

        return RampQuote(ramp: self, cryptoAmount: quote.cryptoAmount, url: components.url)
    }
}

extension TransakRamp {
    private struct Response: ImmutableMappable {
        let quote: Quote

        init(map: Map) throws {
            quote = try map.value("response")
        }
    }

    private struct Quote: ImmutableMappable {
        let cryptoAmount: Decimal

        init(map: Map) throws {
            cryptoAmount = try map.value("cryptoAmount", using: Transform.doubleToDecimalTransform)
        }
    }
}
