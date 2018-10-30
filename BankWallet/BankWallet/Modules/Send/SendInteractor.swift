import Foundation
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

    var wallet: Wallet

    init(wallet: Wallet) {
        self.wallet = wallet
    }

}

extension SendInteractor: ISendInteractor {

    func getCoin() -> Coin {
        return wallet.coin
    }

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
        let rate = Rate()
        rate.coin = wallet.coin
        rate.value = 5000
        delegate?.didFetchExchangeRate(exchangeRate: rate.value)
    }

    private func didFetchExchangeRates () {
//        if let exchangeRate = (changeset.array.filter { $0.code == coin }).first {
//            delegate?.didFetchExchangeRate(exchangeRate: exchangeRate.value)
//        }
    }

    func send(address: String, amount: Double) {
        wallet.adapter.send(to: address, value: amount) { [weak self] error in
            if let error = error {
                self?.delegate?.didFailToSend(error: error)
            } else {
                self?.delegate?.didSend()
            }
        }
    }

    func isValid(address: String?) -> Bool {
        guard let address = address, !address.isEmpty else {
            return false
        }
        do {
            try wallet.adapter.validate(address: address)
            return true
        } catch {
            return false
        }
    }

}
