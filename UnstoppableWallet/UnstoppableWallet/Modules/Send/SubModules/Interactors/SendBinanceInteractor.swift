import RxSwift

class SendBinanceInteractor {
    private let adapter: ISendBinanceAdapter

    init(adapter: ISendBinanceAdapter) {
        self.adapter = adapter
    }

}

extension SendBinanceInteractor: ISendBinanceInteractor {

    var availableBalance: Decimal {
        return adapter.availableBalance
    }

    var availableBinanceBalance: Decimal {
        return adapter.availableBinanceBalance
    }

    var fee: Decimal {
        return adapter.fee
    }

    func sendSingle(amount: Decimal, address: String, memo: String?) -> Single<Void> {
        return adapter.sendSingle(amount: amount, address: address, memo: memo)
    }

}
