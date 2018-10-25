import Foundation

class DollarCurrency: Currency {

    override var symbol: String {
        return "$"
    }
    override var code: String {
        return "USD"
    }
    override var locale: Locale {
        return Locale(identifier: "en_US")
    }

}
