import UniswapKit
import EthereumKit

protocol ISwapView: class {
    func dismissKeyboard()

    func bind(viewItem: SwapModule.ViewItem)
    func amount(type: TradeType) -> String?

    func dismissWithSuccess()
}

protocol ISwapViewDelegate {
    func onViewDidLoad()
    func onTapInfo()
    func onClose()

    func isValid(type: TradeType, text: String) -> Bool
    func willChangeAmount(type: TradeType, text: String?)

    func onTokenSelect(type: TradeType)
    func onButtonClicked()
}

protocol ISwapInteractor {
    var spenderAddress: Address { get }
    func balance(coin: Coin) -> Decimal?
    func requestSwapData(coinIn: Coin?, coinOut: Coin?)
    func requestAllowance(coin: Coin)
    func allowanceChanging(subscribe: Bool, coin: Coin)
    func bestTradeExactIn(swapData: SwapData, amount: Decimal) throws -> TradeData
    func bestTradeExactOut(swapData: SwapData, amount: Decimal) throws -> TradeData
}

protocol ISwapInteractorDelegate: class {
    func clearSwapData()
    func didReceive(swapData: SwapData)
    func didFailReceiveSwapData(error: Error)

    func didReceive(allowance: Decimal?)
    func didFailReceiveAllowance(error:Error)
}

protocol ISwapRouter {
    func openTokenSelect(accountCoins: Bool, exclude: [Coin], delegate: ICoinSelectDelegate)
    func showUniswapInfo()
    func showApprove(delegate: ISwapApproveDelegate, coin: Coin, spenderAddress: Address, amount: Decimal)
    func showConfirmation(coinIn: Coin, coinOut: Coin, tradeData: TradeData, delegate: ISwapConfirmationDelegate)
    func dismiss()
}

protocol ISwapInputViewDelegate: class {
    func isValid(_ inputView: SwapInputView, text: String) -> Bool

    func willChangeAmount(_ inputView: SwapInputView, text: String?)

    func onMaxClicked(_ inputView: SwapInputView)
    func onTokenSelectClicked(_ inputView: SwapInputView)
}

protocol ISwapViewItemFactory {
    func viewItem(coinIn: Coin, balance: Decimal?, coinOut: Coin?, type: TradeType, allowance: DataStatus<Decimal>?, tradeData: DataStatus<TradeData>?, state: SwapProcessState) -> SwapModule.ViewItem
}

protocol ISwapFactory {
    func swapState(coinIn: Coin, allowance: DataStatus<Decimal>?, tradeData: DataStatus<TradeData>?, approving: Bool) -> SwapProcessState
}

extension UniswapKit.Kit: ISwapKit {
}

struct CoinBalanceItem {
    let coin: Coin
    let balance: Decimal?
}

enum SwapValidationError: Error, LocalizedError {
    case insufficientBalance(availableBalance: String?)

    var errorDescription: String? {
        switch self {
        case .insufficientBalance(let availableBalance):
            return "swap.amount_error.maximum_amount".localized(availableBalance ?? "")
        }
    }

}

enum SwapProcessState {
    case hidden
    case approve
    case approving
    case proceed

    var title: String {
        switch self {
        case .hidden: return ""
        case .approve: return "swap.approve_button"
        case .approving: return "swap.approving_button"
        case .proceed: return "swap.proceed_button"
        }
    }

}

struct AdditionalViewItem {
    let title: String
    let value: String?
    let customColor: UIColor?

    init(title: String, value: String?, customColor: UIColor? = nil) {
        self.title = title
        self.value = value
        self.customColor = customColor
    }

}


class SwapModule {

    struct SwapAreaViewItem {
        let minMaxItem: AdditionalViewItem
        let executionPriceItem: AdditionalViewItem
        let priceImpactItem: AdditionalViewItem

        let buttonTitle: String
        let buttonEnabled: Bool
    }

    struct ViewItem {
        let exactType: TradeType
        let estimatedAmount: String?

        let tokenIn: String
        let tokenOut: String?

        let balance: String?
        let balanceError: Error?

        let allowance: DataStatus<String>?

        let swapAreaItem: DataStatus<SwapAreaViewItem>?
    }

}
