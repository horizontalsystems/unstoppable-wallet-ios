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

    enum Blockchain {
        case bitcoin
        case bitcoinCash
        case zcash
        case litecoin
        case dash
        case binanceChain
        case evm(evmBlockchain: EvmBlockchain)

        static var all: [Blockchain] {
            [
                .bitcoin,
                .evm(evmBlockchain: .ethereum),
                .evm(evmBlockchain: .binanceSmartChain),
                .evm(evmBlockchain: .polygon),
                .zcash,
                .dash,
                .bitcoinCash,
                .litecoin,
                .binanceChain
            ]
        }

        var uid: String {
            switch self {
            case .bitcoin: return "bitcoin"
            case .bitcoinCash: return "bitcoin-cash"
            case .zcash: return "zcash"
            case .litecoin: return "litecoin"
            case .dash: return "dash"
            case .binanceChain: return "binance-chain"
            case .evm(let evmBlockchain): return evmBlockchain.uid
            }
        }

        var title: String {
            switch self {
            case .bitcoin: return "Bitcoin"
            case .bitcoinCash: return "Bitcoin Cash"
            case .zcash: return "Zcash"
            case .litecoin: return "Litecoin"
            case .dash: return "Dash"
            case .binanceChain: return "Binance Chain"
            case .evm(let evmBlockchain): return evmBlockchain.name
            }
        }

        var description: String {
            switch self {
            case .bitcoin: return "BTC (BIP44, BIP49, BIP84)"
            case .bitcoinCash: return "BCH (Legacy, CashAddress)"
            case .zcash: return "ZEC"
            case .litecoin: return "LTC (BIP44, BIP49, BIP84)"
            case .dash: return "DASH"
            case .binanceChain: return "BNB, BEP2 tokens"
            case .evm(let evmBlockchain): return evmBlockchain.description
            }
        }

        var imageName: String {
            switch self {
            case .bitcoin: return "bitcoin_24"
            case .bitcoinCash: return "bitcoin_cash_24"
            case .zcash: return "zcash_24"
            case .litecoin: return "litecoin_24"
            case .dash: return "dash_24"
            case .binanceChain: return "binance_chain_24"
            case .evm(let evmBlockchain): return evmBlockchain.icon24
            }
        }

        var coinType: CoinType {
            switch self {
            case .bitcoin: return .bitcoin
            case .bitcoinCash: return .bitcoinCash
            case .zcash: return .zcash
            case .litecoin: return .litecoin
            case .dash: return .dash
            case .binanceChain: return .bep2(symbol: "BNB")
            case .evm(let evmBlockchain): return evmBlockchain.baseCoinType
            }
        }
    }

}
