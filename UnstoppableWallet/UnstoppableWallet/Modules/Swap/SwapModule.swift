import UIKit
import MarketKit
import EvmKit
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
    private static let addressesForRevoke = ["0xdac17f958d2ee523a2206206994597c13d831ec7"]

    static func mustBeRevoked(token: Token?) -> Bool {
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
        case .ethereum: return [.oneInch, .uniswap]
        case .binanceSmartChain: return [.oneInch, .pancake]
        case .polygon: return [.oneInch, .quickSwap]
        case .avalanche: return [.oneInch]
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
            case .oneInch: return [.ethereum, .binanceSmartChain, .polygon, .avalanche, .optimism, .arbitrumOne]
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
