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

    static func viewController(tokenFrom: Token? = nil) -> UIViewController? {
        let swapDexManager = SwapProviderManager(localStorage: App.shared.localStorage, evmBlockchainManager: App.shared.evmBlockchainManager, tokenFrom: tokenFrom)

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
        var tokenFrom: Token?
        var tokenTo: Token?
        var amountFrom: Decimal?
        var amountTo: Decimal?
        var exactFrom: Bool

        init(tokenFrom: Token?, tokenTo: Token? = nil, amountFrom: Decimal? = nil, amountTo: Decimal? = nil, exactFrom: Bool = true) {
            self.tokenFrom = tokenFrom
            self.tokenTo = tokenTo
            self.amountFrom = amountFrom
            self.amountTo = amountTo
            self.exactFrom = exactFrom
        }

    }

    class Dex {
        var blockchainType: BlockchainType {
            didSet {
                let allowedProviders = blockchainType.allowedProviders
                if !allowedProviders.contains(provider) {
                    provider = allowedProviders[0]
                }
            }
        }

        var provider: Provider {
            didSet {
                if !provider.allowedBlockchainTypes.contains(blockchainType) {
                    blockchainType = provider.allowedBlockchainTypes[0]
                }
            }
        }

        init(blockchainType: BlockchainType, provider: Provider) {
            self.blockchainType = blockchainType
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

extension BlockchainType {

    var allowedProviders: [SwapModule.Dex.Provider] {
        switch self {
        case .ethereum: return [.oneInch, .uniswap]
        case .binanceSmartChain: return [.oneInch, .pancake]
        case .polygon: return [.oneInch, .quickSwap]
        case .optimism: return [.oneInch]
        case .arbitrumOne: return [.oneInch]
        default: return []
        }
    }

}

extension SwapModule.Dex {

    enum Provider: String {
        case uniswap = "Uniswap"
        case oneInch = "1Inch"
        case pancake = "PancakeSwap"
        case quickSwap = "QuickSwap"

        var allowedBlockchainTypes: [BlockchainType] {
            switch self {
            case .uniswap: return [.ethereum]
            case .oneInch: return [.ethereum, .binanceSmartChain, .polygon, .optimism, .arbitrumOne]
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
