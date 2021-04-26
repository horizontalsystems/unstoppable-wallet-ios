import Foundation
import CurrencyKit

class SendAmountInteractor {
    private let localStorage: ILocalStorage
    private let rateManager: IRateManager
    private let currencyKit: CurrencyKit.Kit

    init(localStorage: ILocalStorage, rateManager: IRateManager, currencyKit: CurrencyKit.Kit) {
        self.localStorage = localStorage
        self.rateManager = rateManager
        self.currencyKit = currencyKit
    }

}

extension SendAmountInteractor: ISendAmountInteractor {

    func set(inputType: SendInputType) {
        localStorage.sendInputType = inputType
    }

    var baseCurrency: Currency {
        currencyKit.baseCurrency
    }

}
