import Foundation

class StubSettingsProvider: SettingsProtocol {

    var currency: Currency {
        return DollarCurrency()
    }

}
