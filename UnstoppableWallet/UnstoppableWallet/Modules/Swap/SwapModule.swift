import Foundation
import UniswapKit
import EthereumKit
import ThemeKit

struct SwapModule {

    enum PriceImpactLevel: Int {
    case none
    case normal
    case warning
    case forbidden
    }

    struct TradeItem {
        let coinIn: Coin
        let coinOut: Coin
        let type: TradeType
        let executionPrice: Decimal?
        let priceImpact: Decimal?
        let priceImpactLevel: PriceImpactLevel
        let minMaxAmount: Decimal?
    }

    struct TradeViewItem {
        let executionPrice: String?
        let priceImpact: String?
        let priceImpactLevel: PriceImpactLevel
        let minMaxTitle: String?
        let minMaxAmount: String?
    }

    struct AllowanceItem {
        let amount: CoinValue
        let isSufficient: Bool
    }

    struct AllowanceViewItem {
        let amount: String?
        let isSufficient: Bool
    }

    struct ApproveData {
        let coin: Coin
        let spenderAddress: Address
        let amount: Decimal
    }

    struct CoinBalanceItem {
        let coin: Coin
        let balance: Decimal?
    }

    enum SwapState {
        case idle
        case approveRequired
        case waitingForApprove
        case allowed
        case swapSuccess
    }

    struct ConfirmationAdditionalViewItem {
        let title: String
        let value: String?
    }

    struct ConfirmationAmountViewItem {
        let payTitle: String
        let payValue: String?
        let getTitle: String
        let getValue: String?
    }


    static func instance(wallet: Wallet) -> UIViewController? {
        guard let ethereumKit = try? App.shared.ethereumKitManager.ethereumKit(account: wallet.account) else {
            return nil
        }
        let swapKit = UniswapKit.Kit.instance(ethereumKit: ethereumKit)
        let allowanceRepository = AllowanceRepository(walletManager: App.shared.walletManager, adapterManager: App.shared.adapterManager)
        let swapCoinProvider = SwapCoinProvider(coinManager: App.shared.coinManager, walletManager: App.shared.walletManager, adapterManager: App.shared.adapterManager)

        let service = SwapService(uniswapRepository: UniswapRepository(swapKit: swapKit), allowanceRepository: allowanceRepository, swapCoinProvider: swapCoinProvider, adapterManager: App.shared.adapterManager, coin: wallet.coin)
        let viewModel = SwapViewModel(service: service, factory: SwapViewItemFactory(), decimalParser: SendAmountDecimalParser())

        return ThemeNavigationController(rootViewController: SwapViewController(viewModel: viewModel))
    }

}

enum SwapValidationError: Error, LocalizedError {
    case insufficientBalance(availableBalance: CoinValue?)
    case insufficientAllowance

    var errorDescription: String? {
        switch self {
        case .insufficientBalance(let availableBalance):
            if let availableBalance = availableBalance {
                return "swap.amount_error.maximum_amount".localized(ValueFormatter.instance.format(coinValue: availableBalance) ?? "")
            }
            return "swap.amount_error.no_balance".localized
        case .insufficientAllowance:
            return "swap.allowance_error.insufficient_allowance".localized
        }
    }

}

extension UniswapKit.Kit.TradeError: LocalizedError {

    public var errorDescription: String? {
        switch self {
        case .tradeNotFound: return "swap.trade_error.not_found".localized
        default: return nil
        }
    }

}
