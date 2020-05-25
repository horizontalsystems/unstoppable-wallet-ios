import UIKit
import RxSwift
import CurrencyKit
import XRatesKit

protocol ISendView: class {
    func set(coin: Coin)

    func showCopied()
    func show(error: Error)
    func showProgress()
    func set(sendButtonEnabled: Bool)
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

    func nonExpiredRateValue(coinCode: CoinCode, currencyCode: String) -> Decimal?
    func send(single: Single<Void>)
    func subscribeToMarketInfo(coinCode: CoinCode, currencyCode: String)
}

protocol ISendInteractorDelegate: AnyObject {
    func sync()
    func didSend()
    func didFailToSend(error: Error)
    func didReceive(marketInfo: MarketInfo)
}

protocol ISendHandler: AnyObject {
    var delegate: ISendHandlerDelegate? { get set }
    func onViewDidLoad()
    func showKeyboard()

    func sync()
    func sync(rateValue: Decimal?)
    func sync(inputType: SendInputType)
    func confirmationViewItems() throws -> [ISendConfirmationViewItemNew]
    func sendSingle() throws -> Single<Void>
}

protocol ISendHandlerDelegate: AnyObject {
    func onChange(isValid: Bool)
}

protocol ISendBitcoinInteractor {
    var lockTimeEnabled: Bool { get }
    func fetchAvailableBalance(feeRate: Int, address: String?, pluginData: [UInt8: IBitcoinPluginData])
    func fetchMaximumAmount(pluginData: [UInt8: IBitcoinPluginData])
    func fetchMinimumAmount(address: String?)
    func validate(address: String, pluginData: [UInt8: IBitcoinPluginData]) throws
    func fetchFee(amount: Decimal, feeRate: Int, address: String?, pluginData: [UInt8: IBitcoinPluginData])
    func sendSingle(amount: Decimal, address: String, feeRate: Int, pluginData: [UInt8: IBitcoinPluginData]) -> Single<Void>
}

protocol ISendBitcoinInteractorDelegate: class {
    func didFetch(availableBalance: Decimal)
    func didFetch(maximumAmount: Decimal?)
    func didFetch(minimumAmount: Decimal)
    func didFetch(fee: Decimal)
}

protocol ISendDashInteractor {
    func fetchAvailableBalance(address: String?)
    func fetchMinimumAmount(address: String?)
    func validate(address: String) throws
    func fetchFee(amount: Decimal, address: String?)
    func sendSingle(amount: Decimal, address: String) -> Single<Void>
}

protocol ISendDashInteractorDelegate: class {
    func didFetch(availableBalance: Decimal)
    func didFetch(minimumAmount: Decimal)
    func didFetch(fee: Decimal)
}

protocol ISendEthereumInteractor {
    func availableBalance(gasPrice: Int, gasLimit: Int?) -> Decimal
    var ethereumBalance: Decimal { get }
    var minimumRequiredBalance: Decimal { get }
    var minimumSpendableAmount: Decimal? { get }
    func validate(address: String) throws
    func fee(gasPrice: Int, gasLimit: Int) -> Decimal
    func estimateGasLimit(to address: String, value: Decimal, gasPrice: Int?) -> Single<Int>
    func sendSingle(amount: Decimal, address: String, gasPrice: Int, gasLimit: Int) -> Single<Void>
}

protocol ISendEosInteractor {
    var availableBalance: Decimal { get }
    func validate(account: String) throws
    func sendSingle(amount: Decimal, account: String, memo: String?) -> Single<Void>
}

protocol ISendBinanceInteractor {
    var availableBalance: Decimal { get }
    var availableBinanceBalance: Decimal { get }
    func validate(address: String) throws
    var fee: Decimal { get }
    func sendSingle(amount: Decimal, address: String, memo: String?) -> Single<Void>
}

protocol ISendRouter: class {
    func showConfirmation(viewItems: [ISendConfirmationViewItemNew], delegate: ISendConfirmationDelegate)
    func dismiss()
}

protocol ISendSubRouter: AnyObject {
    var viewController: UIViewController? { set get }
}

protocol ISendConfirmationItemFactory {
    func viewItem(sendInputType: SendInputType, coinAmountValue: CoinValue, currencyAmountValue: CurrencyValue?, receiver: String, showMemo: Bool, coinFeeValue: CoinValue?, currencyFeeValue: CurrencyValue?, estimateTime: String?) -> SendConfirmationViewItem?
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
            return ValueFormatter.instance.format(coinValue: coinValue)
        case .currencyValue(let currencyValue):
            return ValueFormatter.instance.format(currencyValue: currencyValue)
        }
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
    var secondaryInfo: AmountInfo?
    let receiver: String
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

struct SendConfirmationDurationViewItem: ISendConfirmationViewItemNew {
    let timeInterval: TimeInterval?
}

struct SendConfirmationLockUntilViewItem: ISendConfirmationViewItemNew {
    let lockValue: String
}
