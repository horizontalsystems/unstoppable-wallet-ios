import Foundation
import WalletKit

class SendInteractor {

    weak var delegate: ISendInteractorDelegate?

    var coin: Coin

    init(coin: Coin) {
        self.coin = coin
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
