import UIKit
import CoinKit
import EthereumKit
import SectionsTableView
import ThemeKit
import RxSwift
import RxCocoa

protocol ISwapDexManager {
    var dex: SwapModuleNew.DexNew? { get }
    func set(provider: SwapModuleNew.DexNew.Provider)

    var dexUpdated: Signal<()> { get }
}

protocol ISwapDataSourceManager {
    var dataSource: ISwapDataSource? { get }
    var settingsDataSource: ISwapSettingsDataSource? { get }

    var dataSourceUpdated: Signal<()> { get }
}

protocol ISwapProvider: AnyObject {
    var dataSource: ISwapDataSource { get }
    var settingsDataSource: ISwapSettingsDataSource? { get }

    var swapState: SwapModuleNew.DataSourceState { get }
}

protocol ISwapDataSource: AnyObject {
    func buildSections() -> [SectionProtocol]

    var state: SwapModuleNew.DataSourceState { get }

    var onOpen: ((_ viewController: UIViewController,_ viaPush: Bool) -> ())? { get set }
    var onOpenSettings: (() -> ())? { get set }
    var onClose: (() -> ())? { get set }
    var onReload: (() -> ())? { get set }
}

class SwapModuleNew {

    static func viewController(coinFrom: Coin? = nil) -> UIViewController? {
        let swapDexManager = SwapProviderManager(localStorage: App.shared.localStorage, coinFrom: coinFrom)

        let viewModel =  SwapViewModel(dexManager: swapDexManager)
        let viewController = SwapViewControllerNew(
                viewModel: viewModel,
                dataSourceManager: swapDexManager
        )

        return ThemeNavigationController(rootViewController: viewController)
    }

}

extension SwapModuleNew {

    class DataSourceState {
        var coinFrom: Coin?
        var coinTo: Coin?
        var amountFrom: Decimal?
        var amountTo: Decimal?
        var exactFrom: Bool

        init(coinFrom: Coin?, coinTo: Coin? = nil, amountFrom: Decimal? = nil, amountTo: Decimal? = nil, exactFrom: Bool = true) {
            self.coinFrom = coinFrom
            self.coinTo = coinTo
            self.amountFrom = amountFrom
            self.amountTo = amountTo
            self.exactFrom = exactFrom
        }

    }

    class DexNew {
        var blockchain: Blockchain {
            didSet {
                if !blockchain.allowedProviders.contains(provider) {
                    provider = blockchain.allowedProviders[0]
                }
            }
        }

        var provider: Provider {
            didSet {
                if !provider.allowedBlockchains.contains(blockchain) {
                    blockchain = provider.allowedBlockchains[0]
                }
            }
        }

        init(blockchain: Blockchain, provider: Provider) {
            self.blockchain = blockchain
            self.provider = provider
        }

        var evmKit: EthereumKit.Kit? {
            switch blockchain {
            case .ethereum: return App.shared.ethereumKitManager.evmKit
            case .binanceSmartChain: return App.shared.binanceSmartChainKitManager.evmKit
            }
        }

        var coin: Coin? {
            switch blockchain {
            case .ethereum: return App.shared.coinKit.coin(type: .ethereum)
            case .binanceSmartChain: return App.shared.coinKit.coin(type: .binanceSmartChain)
            }
        }

    }

}

extension SwapModuleNew {

    enum SwapError: Error {
        case noBalanceIn
        case insufficientBalanceIn
        case insufficientAllowance
        case forbiddenPriceImpactLevel
    }

}

extension SwapModuleNew.DexNew {

    enum Blockchain: String {
        case ethereum
        case binanceSmartChain

        var allowedProviders: [Provider] {
            switch self {
            case .ethereum: return [.uniswap, .oneInch]
            case .binanceSmartChain: return [.pancake, .oneInch]
            }
        }

    }

    enum Provider: String {
        case uniswap = "Uniswap"
        case oneInch = "1Inch"
        case pancake = "PancakeSwap"

        var allowedBlockchains: [Blockchain] {
            switch self {
            case .oneInch: return [.ethereum, .binanceSmartChain]
            case .uniswap: return [.ethereum]
            case .pancake: return [.binanceSmartChain]
            }
        }

    }

}

protocol ISwapErrorProvider {
    var errors: [Error] { get }
    var errorsObservable: Observable<[Error]> { get }
}
