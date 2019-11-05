import RxSwift

class SendBitcoinInteractor {
    weak var delegate: ISendBitcoinInteractorDelegate?

    private let adapter: ISendBitcoinAdapter

    init(adapter: ISendBitcoinAdapter) {
        self.adapter = adapter
    }

}

extension SendBitcoinInteractor: ISendBitcoinInteractor {

    func fetchAvailableBalance(feeRate: Int, address: String?, pluginData: [UInt8: IBitcoinPluginData]) {
        DispatchQueue.global(qos: .userInitiated).async {
            let balance = self.adapter.availableBalance(feeRate: feeRate, address: address, pluginData: pluginData)

            DispatchQueue.main.async {
                self.delegate?.didFetch(availableBalance: balance)
            }
        }
    }

    func fetchMaximumAmount(pluginData: [UInt8: IBitcoinPluginData] = [:]) {
        DispatchQueue.global(qos: .userInitiated).async {
            let amount = self.adapter.maximumSendAmount(pluginData: pluginData)

            DispatchQueue.main.async {
                self.delegate?.didFetch(maximumAmount: amount)
            }
        }
    }

    func fetchMinimumAmount(address: String?) {
        DispatchQueue.global(qos: .userInitiated).async {
            let amount = self.adapter.minimumSendAmount(address: address)

            DispatchQueue.main.async {
                self.delegate?.didFetch(minimumAmount: amount)
            }
        }
    }

    func validate(address: String) throws {
        try adapter.validate(address: address)
    }

    func fetchFee(amount: Decimal, feeRate: Int, address: String?, pluginData: [UInt8: IBitcoinPluginData]) {
        DispatchQueue.global(qos: .userInitiated).async {
            let fee = self.adapter.fee(amount: amount, feeRate: feeRate, address: address, pluginData: pluginData)

            DispatchQueue.main.async {
                self.delegate?.didFetch(fee: fee)
            }
        }
    }

    func sendSingle(amount: Decimal, address: String, feeRate: Int, pluginData: [UInt8: IBitcoinPluginData]) -> Single<Void> {
        adapter.sendSingle(amount: amount, address: address, feeRate: feeRate, pluginData: pluginData)
    }

}
