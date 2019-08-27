import RxSwift

class SendBitcoinInteractor {
    weak var delegate: ISendBitcoinInteractorDelegate?

    private let disposeBag = DisposeBag()

    private let adapter: ISendBitcoinAdapter

    init(adapter: ISendBitcoinAdapter) {
        self.adapter = adapter
    }

}

extension SendBitcoinInteractor: ISendBitcoinInteractor {

    func fetchAvailableBalance(feeRate: Int, address: String?) {
        DispatchQueue.global(qos: .userInitiated).async {
            let balance = self.adapter.availableBalance(feeRate: feeRate, address: address)

            DispatchQueue.main.async {
                self.delegate?.didFetch(availableBalance: balance)
            }
        }
    }

    func validate(address: String) throws {
        try adapter.validate(address: address)
    }

    func fetchFee(amount: Decimal, feeRate: Int, address: String?) {
        DispatchQueue.global(qos: .userInitiated).async {
            let fee = self.adapter.fee(amount: amount, feeRate: feeRate, address: address)

            DispatchQueue.main.async {
                self.delegate?.didFetch(fee: fee)
            }
        }
    }

    func sendSingle(amount: Decimal, address: String, feeRate: Int) -> Single<Void> {
        return adapter.sendSingle(amount: amount, address: address, feeRate: feeRate)
    }

}
