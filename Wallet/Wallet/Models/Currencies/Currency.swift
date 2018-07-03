import Foundation

class Currency {

    var symbol: String { fatalError("Abstract var") }
    var code: String { fatalError("Abstract var") }
    var locale: Locale { fatalError("Abstract var") }

}
