import UIKit

class MarketAdvancedSearchModule {

    static func viewController() -> UIViewController {
        let service = MarketAdvancedSearchService(marketKit: App.shared.marketKit, currencyKit: App.shared.currencyKit)
        let viewModel = MarketAdvancedSearchViewModel(service: service)

        return MarketAdvancedSearchViewController(viewModel: viewModel)
    }

}

extension MarketAdvancedSearchModule {

    enum Blockchain: String, CaseIterable {
        case ethereum = "Ethereum"
        case binanceSmartChain = "Binance Smart Chain"
        case binance = "Binance"
        case arbitrum = "Arbitrum"
        case avalanche = "Avalanche"
        case fantom = "Fantom"
        case harmony = "Harmony"
        case huobi = "Huobi"
        case iotex = "Iotex"
        case moonriver = "Moonriver"
        case okex = "Okex"
        case polygon = "Polygon"
        case solana = "Solana"
        case sora = "Sora"
        case tomochain = "Tomochain"
        case xdai = "Xdai"
    }

}
