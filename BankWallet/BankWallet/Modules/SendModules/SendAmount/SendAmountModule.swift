import UIKit

protocol ISendAmountView: class {
    func set(type: String?, amount: String?)
    func set(hint: String?)
    func set(error: String?)
    func set(switchButtonEnabled: Bool)

    func maxButton(show: Bool)
    func showKeyboard()
}

protocol ISendAmountViewDelegate {
    func validateInputText(text: String) -> Bool

    func onSwitchClicked()
    func onChanged(amountText: String?)
    func onMaxClicked()
}

protocol ISendAmountPresenterDelegate: class {
    var availableBalance: Decimal { get }
    func onChanged()
    func onChanged(sendInputType: SendInputType)
}

protocol ISendAmountInteractor {
    var defaultInputType: SendInputType { get }

    func set(inputType: SendInputType)

    func rate(coinCode: CoinCode, currencyCode: String) -> Rate?
    func decimal(coinDecimal: Int, inputType: SendInputType) -> Int
}

protocol ISendAmountInteractorDelegate: class {
}

protocol ISendModule {
    var view: UIView { get }
    var height: CGFloat { get }

    func viewDidLoad()
}

protocol ISendAmountModule: ISendModule {
    var coinAmount: Decimal? { get }

    func showKeyboard()

    func onValidation(error: SendStateError)
    func onValidationSuccess()
}

class SendAmountModule {
    private let sendView: SendAmountView
    let presenter: SendAmountPresenter


    init(adapter: IAdapter, appConfigProvider: IAppConfigProvider, localStorage: ILocalStorage, rateStorage: IRateStorage, currencyManager: ICurrencyManager, delegate: ISendAmountPresenterDelegate) {
        let coinCode = adapter.wallet.coin.code
        let interactor = SendAmountInteractor(adapter: adapter, appConfigProvider: appConfigProvider, localStorage: localStorage, rateStorage: rateStorage)

        let sendAmountPresenterHelper = SendAmountPresenterHelper(coinCode: coinCode, coinDecimal: adapter.decimal, currency: currencyManager.baseCurrency, currencyDecimal: App.shared.appConfigProvider.fiatDecimal)
        let presenter = SendAmountPresenter(interactor: interactor, sendAmountPresenterHelper: sendAmountPresenterHelper, coinCode: coinCode, coinDecimal: adapter.decimal, currencyCode: currencyManager.baseCurrency.code)
        sendView = SendAmountView(delegate: presenter)

        presenter.view = sendView
        presenter.presenterDelegate = delegate

        self.presenter = presenter
    }

}

extension SendAmountModule: ISendModule {

    var view: UIView {
        return sendView
    }

    var height: CGFloat {
        return SendTheme.amountHeight
    }

    func viewDidLoad() {
        presenter.viewDidLoad()
    }

}

extension SendAmountModule: ISendAmountModule {

    var coinAmount: Decimal? {
        return presenter.coinAmount
    }

    func showKeyboard() {
        presenter.showKeyboard()
    }

    func onValidation(error: SendStateError) {
        presenter.onValidation(error: error)
    }

    func onValidationSuccess() {
        presenter.onValidationSuccess()
    }

}