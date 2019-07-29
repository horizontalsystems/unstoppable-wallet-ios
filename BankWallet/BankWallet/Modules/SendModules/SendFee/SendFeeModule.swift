import UIKit

protocol ISendFeeView: class {
    func set(fee: String?)
    func set(convertedFee: String?)
    func set(error: String?)
}

protocol ISendFeeViewDelegate {
    func onFeePriorityChange(value: Int)
}

protocol ISendFeePresenterDelegate: class {
    func updateFee()
}

protocol ISendFeeInteractor {
    func rate(coinCode: CoinCode, currencyCode: String) -> Rate?
}

protocol ISendFeeInteractorDelegate: class {
}

protocol ISendFeeModule: ISendModule {
    var feeRatePriority: FeeRatePriority { get }

    func update(fee: Decimal)
    func insufficientFeeBalance(coinCode: CoinCode, fee: Decimal)
    func update(sendInputType: SendInputType)
}

class SendFeeModule {
    private let sendView: SendFeeView
    private let presenter: SendFeePresenter


    init(adapter: IAdapter, rateStorage: IRateStorage, currencyManager: ICurrencyManager, delegate: ISendFeePresenterDelegate) {
        let coinCode = adapter.feeCoinCode ?? adapter.wallet.coin.code

        let interactor = SendFeeInteractor(rateStorage: rateStorage)

        let sendAmountPresenterHelper = SendAmountPresenterHelper(coinCode: coinCode, coinDecimal: adapter.decimal, currency: currencyManager.baseCurrency, currencyDecimal: App.shared.appConfigProvider.fiatDecimal)
        presenter = SendFeePresenter(interactor: interactor, presenterHelper: sendAmountPresenterHelper, coinCode: coinCode, currencyCode: currencyManager.baseCurrency.code)
        sendView = SendFeeView(feeAdjustable: true, delegate: presenter)

        presenter.view = sendView
        presenter.presenterDelegate = delegate
    }

}

extension SendFeeModule: ISendModule {

    var view: UIView {
        return sendView
    }

    var height: CGFloat {
        return SendTheme.feeHeight
    }

    func viewDidLoad() {
        presenter.viewDidLoad()
    }

}

extension SendFeeModule: ISendFeeModule {

    func update(fee: Decimal) {
        presenter.update(fee: fee)
    }

    func insufficientFeeBalance(coinCode: CoinCode, fee: Decimal) {
        presenter.insufficientFeeBalance(coinCode: coinCode, fee: fee)
    }

    func update(sendInputType: SendInputType) {
        presenter.update(sendInputType: sendInputType)
    }

    var feeRatePriority: FeeRatePriority {
        return presenter.feeRatePriority
    }

}
