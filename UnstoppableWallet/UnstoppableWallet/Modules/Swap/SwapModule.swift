import UIKit
import MarketKit
import EvmKit
import SectionsTableView
import ThemeKit
import RxSwift
import RxCocoa
import UniswapKit

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
    var tableView: UITableView? { get set }
    var buildSections: [SectionProtocol] { get }

    var state: SwapModule.DataSourceState { get }

    var onOpen: ((_ viewController: UIViewController,_ viaPush: Bool) -> ())? { get set }
    var onOpenSelectProvider: (() -> ())? { get set }
    var onOpenSettings: (() -> ())? { get set }
    var onClose: (() -> ())? { get set }
    var onReload: (() -> ())? { get set }

    func viewDidAppear()
}

class SwapModule {

    static func viewController(tokenFrom: MarketKit.Token? = nil) -> UIViewController? {
        let swapDexManager = SwapProviderManager(localStorage: App.shared.localStorage, evmBlockchainManager: App.shared.evmBlockchainManager, tokenFrom: tokenFrom)

        let viewModel =  SwapViewModel(dexManager: swapDexManager)
        let viewController = SwapViewController(
                viewModel: viewModel,
                dataSourceManager: swapDexManager
        )
        return viewController
    }

}

extension SwapModule {
    private static let addressesForRevoke = ["0xdac17f958d2ee523a2206206994597c13d831ec7"]

    static func mustBeRevoked(token: MarketKit.Token?) -> Bool {
        if let token = token,
           case .ethereum = token.blockchainType,
           case .eip20(let address) = token.type,
           Self.addressesForRevoke.contains(address.lowercased()) {
            return true
        }

        return false
    }

}

extension SwapModule {

    enum ApproveStepState: Int {
        case notApproved, revokeRequired, revoking, approveRequired, approving, approved
    }

    class DataSourceState {
        var tokenFrom: MarketKit.Token?
        var tokenTo: MarketKit.Token?
        var amountFrom: Decimal?
        var amountTo: Decimal?
        var exactFrom: Bool

        init(tokenFrom: MarketKit.Token?, tokenTo: MarketKit.Token? = nil, amountFrom: Decimal? = nil, amountTo: Decimal? = nil, exactFrom: Bool = true) {
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

    enum SwapError: Error, Equatable {
        case noBalanceIn
        case insufficientBalanceIn
        case insufficientAllowance
        case needRevokeAllowance(allowance: CoinValue)

        static func ==(lhs: SwapError, rhs: SwapError) -> Bool {
            switch (lhs, rhs) {
            case (.noBalanceIn, .noBalanceIn): return true
            case (.insufficientBalanceIn, .insufficientBalanceIn): return true
            case (.insufficientAllowance, .insufficientAllowance): return true
            case (.needRevokeAllowance(let lAllowance), .needRevokeAllowance(let rAllowance)): return lAllowance == rAllowance
            default: return false
            }
        }

        var revokeAllowance: CoinValue? {
            switch self {
            case .needRevokeAllowance(let allowance): return allowance
            default: return nil
            }
        }

    }

}

extension BlockchainType {

    var allowedProviders: [SwapModule.Dex.Provider] {
        switch self {
        case .ethereum: return [.oneInch, .uniswap, .uniswapV3, .pancakeV3]
        case .binanceSmartChain: return [.oneInch, .pancake, .pancakeV3, .uniswapV3]
        case .polygon: return [.oneInch, .quickSwap, .uniswapV3]
        case .avalanche: return [.oneInch]
        case .optimism: return [.oneInch]
        case .arbitrumOne: return [.oneInch, .uniswapV3]
        case .gnosis: return [.oneInch]
        case .fantom: return [.oneInch]
        default: return []
        }
    }

}

extension SwapModule.Dex {

    enum Provider: String {
        case uniswap = "Uniswap"
        case uniswapV3 = "Uniswap V3"
        case oneInch = "1Inch"
        case pancake = "PancakeSwap"
        case pancakeV3 = "PancakeSwap V3"
        case quickSwap = "QuickSwap"

        var id: String {
            switch self {
            case .uniswap: return "uniswap"
            case .uniswapV3: return "uniswap_v3"
            case .oneInch: return "oneinch"
            case .pancake: return "pancake"
            case .pancakeV3: return "pancake_v3"
            case .quickSwap: return "quickswap"
            }
        }

        var allowedBlockchainTypes: [BlockchainType] {
            switch self {
            case .uniswap: return [.ethereum]
            case .uniswapV3: return [.ethereum, .binanceSmartChain, .arbitrumOne, .polygon]
            case .oneInch: return [.ethereum, .binanceSmartChain, .polygon, .avalanche, .optimism, .arbitrumOne, .gnosis, .fantom]
            case .pancake: return [.binanceSmartChain]
            case .pancakeV3: return [.ethereum, .binanceSmartChain]
            case .quickSwap: return [.polygon]
            }
        }

        var infoUrl: String {
            switch self {
            case .uniswap, .uniswapV3: return "https://uniswap.org/"
            case .oneInch: return "https://app.1inch.io/"
            case .pancake, .pancakeV3: return "https://pancakeswap.finance/"
            case .quickSwap: return "https://quickswap.exchange/"
            }
        }

        var title: String {
            switch self {
            case .uniswap: return "Uniswap v.2"
            case .uniswapV3: return "Uniswap v.3"
            case .oneInch: return "1Inch"
            case .pancake: return "PancakeSwap v.2"
            case .pancakeV3: return "PancakeSwap v.3"
            case .quickSwap: return "QuickSwap"
            }
        }

        var icon: String {
            switch self {
            case .uniswap, .uniswapV3: return "uniswap_32"
            case .oneInch: return "1inch_32"
            case .pancake, .pancakeV3: return "pancake_32"
            case .quickSwap: return "quick_32"
            }
        }

        var dexType: DexType {
            switch self {
            case .uniswap, .uniswapV3: return .uniswap
            default: return .pancakeSwap
            }
        }

    }

}

protocol ISwapErrorProvider {
    var errors: [Error] { get }
    var errorsObservable: Observable<[Error]> { get }
}
