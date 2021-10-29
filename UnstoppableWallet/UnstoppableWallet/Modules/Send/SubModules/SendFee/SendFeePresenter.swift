import Foundation
import CurrencyKit
import MarketKit

class SendFeePresenter {
    weak var view: ISendFeeView?

    private let interactor: ISendFeeInteractor

    private let basePlatformCoin: PlatformCoin
    private let feePlatformCoin: PlatformCoin?
    private let feeCoinProtocol: String?
    private let currency: Currency
    private var rateValue: Decimal?

    private var fee: Decimal = 0
    private var availableFeeBalance: Decimal?

    private var inputType: SendInputType = .coin

    private var externalError: Error?

    init(platformCoin: PlatformCoin, interactor: ISendFeeInteractor) {
        basePlatformCoin = platformCoin
        self.interactor = interactor

        feePlatformCoin = interactor.feeCoin(platformCoin: platformCoin)
        feeCoinProtocol = interactor.feeCoinProtocol(platformCoin: platformCoin)
        currency = interactor.baseCurrency
    }

    private var platformCoin: PlatformCoin {
        feePlatformCoin ?? basePlatformCoin
    }

    private func syncFeeLabels() {
        view?.set(fee: primaryAmountInfo, convertedFee: secondaryAmountInfo)
    }

    private func syncError() {
        do {
            if let externalError = externalError {
                throw externalError
            }

            try validate()

            view?.set(error: nil)
        } catch {
            view?.set(error: resolve(error: error))
        }
    }

    private func validate() throws {
        guard let feePlatformCoin = feePlatformCoin, let feeCoinProtocol = feeCoinProtocol else {
            return
        }

        guard let availableFeeBalance = availableFeeBalance else {
            return
        }

        if availableFeeBalance < fee {
            throw ValidationError.insufficientFeeBalance(coin: basePlatformCoin.coin, coinProtocol: feeCoinProtocol, feeCoin: feePlatformCoin.coin, fee: .coinValue(coinValue: CoinValue(kind: .platformCoin(platformCoin: feePlatformCoin), value: fee)))
        }
    }

    private func resolve(error: Error) -> String {
        if case AppError.ethereum(let reason) = error.convertedError, case .insufficientBalanceWithFee = reason {
            return "ethereum_transaction.error.insufficient_balance_with_fee".localized(platformCoin.coin.code)
        }

        return error.convertedError.smartDescription
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
            return .coinValue(coinValue: CoinValue(kind: .platformCoin(platformCoin: platformCoin), value: fee))
        }
        switch inputType {
        case .coin:
            return .coinValue(coinValue: CoinValue(kind: .platformCoin(platformCoin: platformCoin), value: fee))
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
            return .coinValue(coinValue: CoinValue(kind: .platformCoin(platformCoin: platformCoin), value: fee))
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
        syncFeeLabels()
        syncError()

        interactor.subscribeToCoinPrice(coinUid: feePlatformCoin?.coin.uid, currencyCode: interactor.baseCurrency.code)
        rateValue = interactor.nonExpiredRateValue(coinUid: platformCoin.coin.uid, currencyCode: interactor.baseCurrency.code)
    }

}

extension SendFeePresenter: ISendFeeInteractorDelegate {

    func didReceive(coinPrice: CoinPrice) {
        if !coinPrice.expired {
            rateValue = coinPrice.value
        } else {
            rateValue = nil
        }

        syncFeeLabels()
    }

}

extension SendFeePresenter {

    private enum ValidationError: Error, LocalizedError {
        case insufficientFeeBalance(coin: Coin, coinProtocol: String, feeCoin: Coin, fee: AmountInfo)

        var errorDescription: String? {
            switch self {
            case let .insufficientFeeBalance(coin, coinProtocol, feeCoin, fee):
                return "send.token.insufficient_fee_alert".localized(coin.code, coinProtocol, feeCoin.name, fee.formattedString ?? "")
            }
        }
    }

}
