import Foundation

class SendFeePresenter {
    weak var view: ISendFeeView?
    weak var delegate: ISendFeeDelegate?

    private let interactor: ISendFeeInteractor

    private let coin: Coin
    private let feeCoin: Coin
    private let coinProtocol: String
    private let currency: Currency
    private let rate: Rate?

    private var fee: Decimal = 0
    private var availableFeeBalance: Decimal?

    private(set) var inputType: SendInputType = .coin

    init(coin: Coin, feeCoin: Coin, coinProtocol: String, interactor: ISendFeeInteractor) {
        self.coin = coin
        self.feeCoin = feeCoin
        self.coinProtocol = coinProtocol
        self.interactor = interactor

        currency = interactor.baseCurrency
        rate = interactor.rate(coinCode: feeCoin.code, currencyCode: currency.code)
    }

    private func syncFeeLabels() {
        let coinAmountInfo: AmountInfo = .coinValue(coinValue: CoinValue(coin: feeCoin, value: fee))
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

    private func syncError() {
        do {
            try validate()
            view?.set(error: nil)
        } catch {
            view?.set(error: error)
        }
    }

    private func validate() throws {
        guard let availableFeeBalance = availableFeeBalance else {
            return
        }

        if availableFeeBalance < fee {
            throw ValidationError.insufficientFeeBalance(coin: coin, coinProtocol: coinProtocol, feeCoin: feeCoin, fee: .coinValue(coinValue: CoinValue(coin: feeCoin, value: fee)))
        }
    }

}

extension SendFeePresenter: ISendFeeModule {

    var isValid: Bool {
        do {
            try validate()
            return true
        } catch {
            return false
        }
    }

    var coinValue: CoinValue {
        return CoinValue(coin: feeCoin, value: fee)
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
        syncFeeLabels()
        syncError()
    }

    func set(availableFeeBalance: Decimal) {
        self.availableFeeBalance = availableFeeBalance
        syncError()

    }

    func update(inputType: SendInputType) {
        self.inputType = inputType
        syncFeeLabels()
    }

}

extension SendFeePresenter: ISendFeeViewDelegate {

    func viewDidLoad() {
        inputType = delegate?.inputType ?? .coin
        syncFeeLabels()
        syncError()
    }

}

extension SendFeePresenter {

    private enum ValidationError: Error, LocalizedError {
        case insufficientFeeBalance(coin: Coin, coinProtocol: String, feeCoin: Coin, fee: AmountInfo)

        var errorDescription: String? {
            switch self {
            case let .insufficientFeeBalance(coin, coinProtocol, feeCoin, fee):
                return "send.token.insufficient_fee_alert".localized(coin.code, coinProtocol, feeCoin.title, fee.formattedString ?? "")
            }
        }
    }

}
