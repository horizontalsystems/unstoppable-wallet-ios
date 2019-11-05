import Foundation

class SendAmountInteractor {
    private let localStorage: ILocalStorage
    private let rateManager: IRateManager
    private let currencyManager: ICurrencyManager

    init(localStorage: ILocalStorage, rateManager: IRateManager, currencyManager: ICurrencyManager) {
        self.localStorage = localStorage
        self.rateManager = rateManager
        self.currencyManager = currencyManager
    }

}

extension SendAmountInteractor: ISendAmountInteractor {

    var defaultInputType: SendInputType {
        localStorage.sendInputType ?? .coin
    }

    func set(inputType: SendInputType) {
        localStorage.sendInputType = inputType
    }

    var baseCurrency: Currency {
        currencyManager.baseCurrency
    }

    func nonExpiredRateValue(coinCode: CoinCode, currencyCode: String) -> Decimal? {
        guard let marketInfo = rateManager.marketInfo(coinCode: coinCode, currencyCode: currencyCode), !marketInfo.expired else {
            return nil
        }
        return marketInfo.rate
    }

}
