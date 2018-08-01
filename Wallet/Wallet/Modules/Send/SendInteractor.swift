import Foundation
import WalletKit
import GrouviExtensions
import RxSwift

enum SendError: Error {
    case unknownError
    case insufficientFunds

    var localizedDescription: String {
        switch self {
        case .unknownError: return "unknown_error".localized
        case .insufficientFunds: return "send.insufficient_funds".localized
        }
    }
}

class SendInteractor {
    let disposeBag = DisposeBag()

    weak var delegate: ISendInteractorDelegate?

    var coin: Coin
    var databaseManager: DatabaseManager

    init(coin: Coin, databaseManager: DatabaseManager) {
        self.coin = coin
        self.databaseManager = databaseManager
    }

}

extension SendInteractor: ISendInteractor {

    func getBaseCurrency() -> String {
        print("getBaseCurrency")
        return "USD"
    }

    func getCopiedText() -> String? {
        return UIPasteboard.general.string
    }

    func fetchExchangeRate() {
        print("fetchExchangeRate")
//        databaseManager.getExchangeRates().subscribeAsync(disposeBag: disposeBag, onNext: { [weak self] in
//            self?.didFetchExchangeRates($0)
//        })
        let rate = ExchangeRate()
        rate.code = coin.code
        rate.value = 5000
        delegate?.didFetchExchangeRate(exchangeRate: rate.value)
    }

    private func didFetchExchangeRates (_ changeset: DatabaseChangeSet<ExchangeRate>) {
        if let exchangeRate = (changeset.array.filter { $0.code == coin.code }).first {
            delegate?.didFetchExchangeRate(exchangeRate: exchangeRate.value)
        }
    }

    func send(coinCode: String, address: String, amount: Double) {
        if amount > 5 {
            delegate?.didSend()
        } else {
            delegate?.didFailToSend(error: SendError.unknownError)
        }
    }

}
