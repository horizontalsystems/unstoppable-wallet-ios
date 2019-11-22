import Foundation

class SendFeePresenter {
    weak var view: ISendFeeView?
    weak var delegate: ISendFeeDelegate?

    private let interactor: ISendFeeInteractor

    private let baseCoin: Coin
    private let feeCoin: Coin?
    private let feeCoinProtocol: String?
    private let currency: Currency
    private var rateValue: Decimal?

    private var fee: Decimal = 0
    private var availableFeeBalance: Decimal?

    private(set) var inputType: SendInputType = .coin

    private var externalError: Error?

    init(coin: Coin, interactor: ISendFeeInteractor) {
        baseCoin = coin
        self.interactor = interactor

        feeCoin = interactor.feeCoin(coin: coin)
        feeCoinProtocol = interactor.feeCoinProtocol(coin: coin)
        currency = interactor.baseCurrency
        rateValue = interactor.nonExpiredRateValue(coinCode: self.coin.code, currencyCode: currency.code)
    }

    private var coin: Coin {
        feeCoin ?? baseCoin
    }

    private func syncFeeLabels() {
        view?.set(fee: primaryAmountInfo, convertedFee: secondaryAmountInfo)
    }

    private func syncError() {
        guard externalError == nil else {
            view?.set(error: externalError)
            return
        }

        do {
            try validate()
            view?.set(error: nil)
        } catch {
            view?.set(error: error)
        }
    }

    private func validate() throws {
        guard let feeCoin = feeCoin, let feeCoinProtocol = feeCoinProtocol else {
            return
        }

        guard let availableFeeBalance = availableFeeBalance else {
            return
        }

        if availableFeeBalance < fee {
            throw ValidationError.insufficientFeeBalance(coin: baseCoin, coinProtocol: feeCoinProtocol, feeCoin: feeCoin, fee: .coinValue(coinValue: CoinValue(coin: feeCoin, value: fee)))
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

    var primaryAmountInfo: AmountInfo {
        guard let rateValue = rateValue else {
            return .coinValue(coinValue: CoinValue(coin: coin, value: fee))
        }
        switch inputType {
        case .coin:
            return .coinValue(coinValue: CoinValue(coin: coin, value: fee))
        case .currency:
            return .currencyValue(currencyValue: CurrencyValue(currency: currency, value: fee * rateValue))
        }
    }

    var secondaryAmountInfo: AmountInfo? {
        guard let rateValue = rateValue else {
            return nil
        }
        switch inputType.reversed {
        case .coin:
            return .coinValue(coinValue: CoinValue(coin: coin, value: fee))
        case .currency:
            return .currencyValue(currencyValue: CurrencyValue(currency: currency, value: fee * rateValue))
        }
    }

    func set(loading: Bool) {
        view?.set(loading: loading)
    }

    func set(externalError: Error?) {
        self.externalError = externalError
        syncError()
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
