import UIKit
import RxSwift
import CurrencyKit
import HsToolKit
import MarketKit

protocol ISendView: AnyObject {
    func set(coin: Coin, coinType: CoinType)

    func showCopied()
    func show(error: Error)
    func showProgress()
    func set(actionState: SendPresenter.ActionState)
    func dismissKeyboard()
    func dismissWithSuccess()
}

protocol ISendViewDelegate: AnyObject {
    var view: ISendView? { get set }

    func onViewDidLoad()
    func showKeyboard()

    func onClose()

    func onProceedClicked()
}

protocol ISendInteractor {
    var baseCurrency: Currency { get }
    var defaultInputType: SendInputType { get }

    func nonExpiredRateValue(coinUid: String, currencyCode: String) -> Decimal?
    func send(single: Single<Void>, logger: Logger)
    func subscribeToCoinPrice(coinUid: String, currencyCode: String)
}

protocol ISendInteractorDelegate: AnyObject {
    func sync()
    func didSend()
    func didFailToSend(error: Error)
    func didReceive(coinPrice: CoinPrice)
}

protocol ISendHandler: AnyObject {
    var delegate: ISendHandlerDelegate? { get set }
    func onViewDidLoad()
    func showKeyboard()

    func sync()
    func sync(rateValue: Decimal?)
    func sync(inputType: SendInputType)
    func confirmationViewItems() throws -> [ISendConfirmationViewItemNew]
    func sendSingle(logger: Logger) throws -> Single<Void>
}

protocol ISendHandlerDelegate: AnyObject {
    func onChange(isValid: Bool, amountError: Error?, addressError: Error?)
}

protocol ISendBitcoinInteractor {
    var lockTimeEnabled: Bool { get }
    var balance: Decimal { get }
    func fetchAvailableBalance(feeRate: Int, address: String?, pluginData: [UInt8: IBitcoinPluginData])
    func fetchMaximumAmount(pluginData: [UInt8: IBitcoinPluginData])
    func fetchMinimumAmount(address: String?)
    func fetchFee(amount: Decimal, feeRate: Int, address: String?, pluginData: [UInt8: IBitcoinPluginData])
    func sendSingle(amount: Decimal, address: String, feeRate: Int, pluginData: [UInt8: IBitcoinPluginData], logger: Logger) -> Single<Void>
}

protocol ISendBitcoinInteractorDelegate: AnyObject {
    func didFetch(availableBalance: Decimal)
    func didFetch(maximumAmount: Decimal?)
    func didFetch(minimumAmount: Decimal)
    func didFetch(fee: Decimal)
}

protocol ISendDashInteractor {
    func fetchAvailableBalance(address: String?)
    func fetchMinimumAmount(address: String?)
    func fetchFee(amount: Decimal, address: String?)
    func sendSingle(amount: Decimal, address: String, logger: Logger) -> Single<Void>
}

protocol ISendDashInteractorDelegate: AnyObject {
    func didFetch(availableBalance: Decimal)
    func didFetch(minimumAmount: Decimal)
    func didFetch(fee: Decimal)
}

protocol ISendEthereumInteractor {
    var balance: Decimal { get }
    func availableBalance(gasPrice: Int, gasLimit: Int) -> Decimal
    var ethereumBalance: Decimal { get }
    var minimumRequiredBalance: Decimal { get }
    var minimumSpendableAmount: Decimal? { get }
    func validate(address: String) throws
    func fee(gasPrice: Int, gasLimit: Int) -> Decimal
    func estimateGasLimit(to address: String?, value: Decimal, gasPrice: Int?) -> Single<Int>
    func sendSingle(amount: Decimal, address: String, gasPrice: Int, gasLimit: Int, logger: Logger) -> Single<Void>
}

protocol ISendBinanceInteractor {
    var availableBalance: Decimal { get }
    var availableBinanceBalance: Decimal { get }
    var fee: Decimal { get }
    func sendSingle(amount: Decimal, address: String, memo: String?) -> Single<Void>
}

protocol ISendZcashInteractor {
    var availableBalance: Decimal { get }
    var fee: Decimal { get }
    func sendSingle(amount: Decimal, address: String, memo: String?) -> Single<Void>
}

protocol ISendRouter: AnyObject {
    func showConfirmation(viewItems: [ISendConfirmationViewItemNew], delegate: ISendConfirmationDelegate)
    func dismiss()
}

protocol ISendSubRouter: AnyObject {
    var viewController: UIViewController? { set get }
}

enum SendInputType: String {
    case coin = "coin"
    case currency = "currency"

    var reversed: SendInputType { return self == .coin ? .currency : .coin }
}

enum AmountInfo {
    case coinValue(coinValue: CoinValue)
    case currencyValue(currencyValue: CurrencyValue)

    var formattedString: String? {
        switch self {
        case .coinValue(let coinValue):
            return coinValue.formattedString
        case .currencyValue(let currencyValue):
            return ValueFormatter.instance.format(currencyValue: currencyValue)
        }
    }

    var formattedRawString: String? {
        switch self {
        case .coinValue(let coinValue):
            return coinValue.formattedRawString
        case .currencyValue(let currencyValue):
            return ValueFormatter.instance.format(currencyValue: currencyValue)
        }
    }

    var value: Decimal {
        switch self {
        case .currencyValue(let currencyValue): return currencyValue.value
        case .coinValue(let coinValue): return coinValue.value
        }
    }

    var decimal: Int {
        switch self {
        case .currencyValue(let currencyValue): return currencyValue.currency.decimal
        case .coinValue(let coinValue): return coinValue.decimals
        }
    }

}

struct AmountData {
    let primary: AmountInfo
    let secondary: AmountInfo?

    var formattedString: String {
        var parts = [String]()

        if let formatted = primary.formattedString {
            parts.append(formatted)
        }

        if let formatted = secondary?.formattedString {
            parts.append(formatted)
        }

        return parts.joined(separator: "  |  ")
    }

    var formattedRawString: String {
        var parts = [String]()

        if let formatted = primary.formattedRawString {
            parts.append(formatted)
        }

        if let formatted = secondary?.formattedRawString {
            parts.append(formatted)
        }

        return parts.joined(separator: "  |  ")
    }

}

class SendConfirmationViewItem {
    let primaryAmount: String
    var secondaryAmount: String?
    let receiver: String
    let showMemo: Bool
    let feeInfo: String?
    let totalInfo: String?
    let estimateTime: String?

    init(primaryAmount: String, secondaryAmount: String?, receiver: String, showMemo: Bool, feeInfo: String?, totalInfo: String?, estimateTime: String?) {
        self.primaryAmount = primaryAmount
        self.secondaryAmount = secondaryAmount
        self.receiver = receiver
        self.showMemo = showMemo
        self.feeInfo = feeInfo
        self.totalInfo = totalInfo
        self.estimateTime = estimateTime
    }

}

protocol ISendConfirmationViewItemNew {

}

struct SendConfirmationAmountViewItem: ISendConfirmationViewItemNew {
    let primaryInfo: AmountInfo
    let secondaryInfo: AmountInfo?
    let receiver: Address
    let isAccount: Bool

    init(primaryInfo: AmountInfo, secondaryInfo: AmountInfo?, receiver: Address, isAccount: Bool = false) {
        self.primaryInfo = primaryInfo
        self.secondaryInfo = secondaryInfo
        self.receiver = receiver
        self.isAccount = isAccount
    }

}

struct SendConfirmationFeeViewItem: ISendConfirmationViewItemNew {
    let primaryInfo: AmountInfo
    var secondaryInfo: AmountInfo?
}

struct SendConfirmationTotalViewItem: ISendConfirmationViewItemNew {
    let primaryInfo: AmountInfo
    var secondaryInfo: AmountInfo?
}

struct SendConfirmationMemoViewItem: ISendConfirmationViewItemNew {
    let memo: String
}

struct SendConfirmationLockUntilViewItem: ISendConfirmationViewItemNew {
    let lockValue: String
}
