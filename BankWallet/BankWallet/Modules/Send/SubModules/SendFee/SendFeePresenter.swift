import Foundation

class SendFeePresenter {
    weak var view: ISendFeeView?
    weak var delegate: ISendFeeDelegate?

    private let interactor: ISendFeeInteractor

    private let coin: Coin
    private let currency: Currency
    private let rate: Rate?

    private var fee: Decimal = 0

    private(set) var inputType: SendInputType = .coin

    init(coin: Coin, interactor: ISendFeeInteractor) {
        self.coin = coin
        self.interactor = interactor

        currency = interactor.baseCurrency
        rate = interactor.rate(coinCode: coin.code, currencyCode: currency.code)
    }

    private func updateFeeLabels() {
        let coinAmountInfo: AmountInfo = .coinValue(coinValue: CoinValue(coin: coin, value: fee))
        var currencyAmountInfo: AmountInfo?

        if let rate = rate {
            currencyAmountInfo = .currencyValue(currencyValue: CurrencyValue(currency: currency, value: fee * rate.value))
        }

        switch inputType {
        case .coin:
            view?.set(fee: coinAmountInfo)
            view?.set(convertedFee: currencyAmountInfo)
        case .currency:
            view?.set(fee: currencyAmountInfo)
            view?.set(convertedFee: coinAmountInfo)
        }
    }

}

extension SendFeePresenter: ISendFeeModule {

    var coinValue: CoinValue {
        return CoinValue(coin: coin, value: fee)
    }

    var currencyValue: CurrencyValue? {
        if let rate = rate {
            return CurrencyValue(currency: currency, value: fee * rate.value)
        } else {
            return nil
        }
    }

    func set(fee: Decimal) {
        self.fee = fee
        updateFeeLabels()
    }

    func insufficientFeeBalance(coinCode: CoinCode, fee: Decimal) {
//        insufficientFeeBalanceWithRequiredFee = fee
//        let feeValue = CoinValue(coinCode: feeCoinCode, value: fee)
//        view?.set(error: formatHelper.errorValue(feeValue: feeValue, coinProtocol: coinProtocol, baseCoinName: baseCoinName, coinCode: coinCode))
    }

    func update(inputType: SendInputType) {
        self.inputType = inputType
        updateFeeLabels()
    }

}

extension SendFeePresenter: ISendFeeViewDelegate {

    func viewDidLoad() {
        inputType = delegate?.inputType ?? .coin
        updateFeeLabels()
    }

}
