import Foundation
import WalletKit

class SendInteractor {

    weak var delegate: ISendInteractorDelegate?

    var coins: [Coin]

    init(coins: [Coin]) {
        self.coins = coins
    }

}

extension SendInteractor: ISendInteractor {

    func getBaseCurrency() -> String {
        print("getBaseCurrency")
        return "base currency"
    }

    func getCopiedText() -> String {
        print("getCopiedText")
        return "getCopiedText"
    }

    func fetchExchangeRate() {
        print("fetchExchangeRate")
    }

    func send(coinCode: String, address: String, amount: Double) {
        print("send(coinCode")
    }

}
