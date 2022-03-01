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
    var onOpenSettings: (() -> ())? { get set }
    var onClose: (() -> ())? { get set }
    var onReload: (() -> ())? { get set }
}

class SwapModule {

    static func viewController(platformCoinFrom: PlatformCoin? = nil) -> UIViewController? {
        let swapDexManager = SwapProviderManager(localStorage: App.shared.localStorage, evmBlockchainManager: App.shared.evmBlockchainManager, platformCoinFrom: platformCoinFrom)

        let viewModel =  SwapViewModel(dexManager: swapDexManager)
        let viewController = SwapViewController(
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
        var blockchain: EvmBlockchain {
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

        init(blockchain: EvmBlockchain, provider: Provider) {
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
    }

}

extension EvmBlockchain {

    var allowedProviders: [SwapModule.Dex.Provider] {
        switch self {
        case .ethereum: return [.oneInch, .uniswap]
        case .binanceSmartChain: return [.oneInch, .pancake]
        case .polygon: return [.oneInch, .quickSwap]
        }
    }

}

extension SwapModule.Dex {

    enum Provider: String {
        case uniswap = "Uniswap"
        case oneInch = "1Inch"
        case pancake = "PancakeSwap"
        case quickSwap = "QuickSwap"

        var allowedBlockchains: [EvmBlockchain] {
            switch self {
            case .uniswap: return [.ethereum]
            case .oneInch: return [.ethereum, .binanceSmartChain, .polygon]
            case .pancake: return [.binanceSmartChain]
            case .quickSwap: return [.polygon]
            }
        }

        var infoUrl: String {
            switch self {
            case .uniswap: return "https://uniswap.org/"
            case .oneInch: return "https://app.1inch.io/"
            case .pancake: return "https://pancakeswap.finance/"
            case .quickSwap: return "https://quickswap.exchange/"
            }
        }

        var title: String {
            switch self {
            case .uniswap: return "Uniswap v.2"
            case .oneInch: return "1Inch"
            case .pancake: return "PancakeSwap"
            case .quickSwap: return "QuickSwap"
            }
        }

        var icon: String {
            switch self {
            case .uniswap: return "uniswap_24"
            case .oneInch: return "1inch_24"
            case .pancake: return "pancake_24"
            case .quickSwap: return "quick_24"
            }
        }

    }

}

protocol ISwapErrorProvider {
    var errors: [Error] { get }
    var errorsObservable: Observable<[Error]> { get }
}
