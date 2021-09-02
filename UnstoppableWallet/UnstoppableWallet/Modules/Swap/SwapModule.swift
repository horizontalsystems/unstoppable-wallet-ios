import UIKit
import MarketKit
import EthereumKit
import SectionsTableView
import ThemeKit
import RxSwift
import RxCocoa

protocol ISwapDexManager {
    var dex: SwapModule.Dex? { get }
    func set(provider: SwapModule.Dex.Provider)

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

    var swapState: SwapModule.DataSourceState { get }
}

protocol ISwapDataSource: AnyObject {
    func buildSections() -> [SectionProtocol]

    var state: SwapModule.DataSourceState { get }

    var onOpen: ((_ viewController: UIViewController,_ viaPush: Bool) -> ())? { get set }
    var onOpenSelectProvider: (() -> ())? { get set }
    var onClose: (() -> ())? { get set }
    var onReload: (() -> ())? { get set }
}

class SwapModule {

    static func viewController(platformCoinFrom: PlatformCoin? = nil) -> UIViewController? {
        let swapDexManager = SwapProviderManager(localStorage: App.shared.localStorage, platformCoinFrom: platformCoinFrom)

        let viewModel =  SwapViewModel(dexManager: swapDexManager)
        let viewController = SwapViewControllerNew(
                viewModel: viewModel,
                dataSourceManager: swapDexManager
        )

        return ThemeNavigationController(rootViewController: viewController)
    }

}

extension SwapModule {

    enum ApproveStepState: Int {
        case notApproved, approveRequired, approving, approved
    }

    class DataSourceState {
        var platformCoinFrom: PlatformCoin?
        var platformCoinTo: PlatformCoin?
        var amountFrom: Decimal?
        var amountTo: Decimal?
        var exactFrom: Bool

        init(platformCoinFrom: PlatformCoin?, platformCoinTo: PlatformCoin? = nil, amountFrom: Decimal? = nil, amountTo: Decimal? = nil, exactFrom: Bool = true) {
            self.platformCoinFrom = platformCoinFrom
            self.platformCoinTo = platformCoinTo
            self.amountFrom = amountFrom
            self.amountTo = amountTo
            self.exactFrom = exactFrom
        }

    }

    class Dex {
        var blockchain: Blockchain {
            didSet {
                let allowedProviders = blockchain.allowedProviders
                if !allowedProviders.contains(provider) {
                    provider = allowedProviders[0]
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

    }

}

extension SwapModule {

    enum SwapError: Error {
        case noBalanceIn
        case insufficientBalanceIn
        case insufficientAllowance
        case forbiddenPriceImpactLevel
    }

}

extension SwapModule.Dex {

    enum Blockchain: String {
        case ethereum
        case binanceSmartChain

        var allowedProviders: [Provider] {
            switch self {
            case .ethereum: return isMainNet ? [.oneInch, .uniswap] : [.uniswap]
            case .binanceSmartChain: return isMainNet ? [.oneInch, .pancake] : [.pancake]
            }
        }

        var evmKit: EthereumKit.Kit? {
            switch self {
            case .ethereum: return App.shared.ethereumKitManager.evmKit
            case .binanceSmartChain: return App.shared.binanceSmartChainKitManager.evmKit
            }
        }

        var platformCoin: PlatformCoin? {
            switch self {
            case .ethereum: return try? App.shared.marketKit.platformCoin(coinType: .ethereum)
            case .binanceSmartChain: return try? App.shared.marketKit.platformCoin(coinType: .binanceSmartChain)
            }
        }

        var isMainNet: Bool {
            evmKit?.networkType.isMainNet ?? true
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
