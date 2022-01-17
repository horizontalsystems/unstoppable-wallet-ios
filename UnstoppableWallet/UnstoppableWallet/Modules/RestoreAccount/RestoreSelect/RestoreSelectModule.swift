import UIKit
import RxSwift
import MarketKit

struct RestoreSelectModule {

    static func viewController(accountType: AccountType) -> UIViewController {
        let (enableCoinService, enableCoinView) = EnableCoinModule.module()

        let service = RestoreSelectService(
                accountType: accountType,
                accountFactory: App.shared.accountFactory,
                accountManager: App.shared.accountManager,
                walletManager: App.shared.walletManager,
                coinManager: App.shared.coinManager,
                enableCoinService: enableCoinService
        )

        let viewModel = RestoreSelectViewModel(service: service)

        return RestoreSelectViewController(
                viewModel: viewModel,
                enableCoinView: enableCoinView
        )
    }

}

extension RestoreSelectModule {

    enum Blockchain: String, CaseIterable {
        case bitcoin
        case ethereum
        case binanceSmartChain
        case bitcoinCash
        case zcash
        case litecoin
        case dash
        case binanceChain

        var title: String {
            switch self {
            case .bitcoin: return "Bitcoin"
            case .ethereum: return "Ethereum"
            case .binanceSmartChain: return "Binance Smart Chain"
            case .bitcoinCash: return "Bitcoin Cash"
            case .zcash: return "Zcash"
            case .litecoin: return "Litecoin"
            case .dash: return "Dash"
            case .binanceChain: return "Binance Chain"
            }
        }

        var description: String {
            switch self {
            case .bitcoin: return "BTC (BIP44, BIP49, BIP84)"
            case .ethereum: return "ETH, ERC20 tokens"
            case .binanceSmartChain: return "BNB, BEP20 tokens"
            case .bitcoinCash: return "BCH (Legacy, CashAddress)"
            case .zcash: return "ZEC"
            case .litecoin: return "LTC (BIP44, BIP49, BIP84)"
            case .dash: return "DASH"
            case .binanceChain: return "BNB, BEP2 tokens"
            }
        }

        var icon: BlockchainIcon {
            switch self {
            case .bitcoin: return .remote(iconUid: "bitcoin")
            case .ethereum: return .remote(iconUid: "ethereum")
            case .binanceSmartChain: return .local(imageName: "binance_smart_chain_24")
            case .bitcoinCash: return .remote(iconUid: "bitcoin-cash")
            case .zcash: return .remote(iconUid: "zcash")
            case .litecoin: return .remote(iconUid: "litecoin")
            case .dash: return .remote(iconUid: "dash")
            case .binanceChain: return .local(imageName: "binance_chain_24")
            }
        }

        var coinType: CoinType {
            switch self {
            case .bitcoin: return .bitcoin
            case .ethereum: return .ethereum
            case .binanceSmartChain: return .binanceSmartChain
            case .bitcoinCash: return .bitcoinCash
            case .zcash: return .zcash
            case .litecoin: return .litecoin
            case .dash: return .dash
            case .binanceChain: return .bep2(symbol: "BNB")
            }
        }
    }

    enum BlockchainIcon {
        case remote(iconUid: String)
        case local(imageName: String)

        var imageUrl: String {
            switch self {
            case .remote(let iconUid):
                let scale = Int(UIScreen.main.scale)
                return "https://markets.nyc3.digitaloceanspaces.com/coin-icons/\(iconUid)@\(scale)x.png"
            case .local:
                return ""
            }
        }

        var placeholderImageName: String? {
            switch self {
            case .remote:
                return nil
            case .local(let imageName):
                return imageName
            }
        }
    }

}
