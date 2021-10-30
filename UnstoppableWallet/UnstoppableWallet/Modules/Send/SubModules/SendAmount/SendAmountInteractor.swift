import Foundation
import CurrencyKit

class SendAmountInteractor {
    private let localStorage: ILocalStorage
    private let currencyKit: CurrencyKit.Kit

    init(localStorage: ILocalStorage, currencyKit: CurrencyKit.Kit) {
        self.localStorage = localStorage
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
