import HSEthereumKit
import RxSwift

class EthereumAdapter: EthereumBaseAdapter {

    init(coin: Coin, ethereumKit: EthereumKit) {
        super.init(coin: coin, ethereumKit: ethereumKit, decimal: 18)

        ethereumKit.delegate = self
    }

    override func transactionsObservable(hashFrom: String?, limit: Int) -> Single<[EthereumTransaction]> {
        return ethereumKit.transactions(fromHash: hashFrom, limit: limit)
    }

}

extension EthereumAdapter: IAdapter {

    func stop() {
    }

    var balance: Decimal {
        return ethereumKit.balance
    }

    func refresh() {
        ethereumKit.refresh()
    }

    func send(to address: String, value: Decimal, completion: ((Error?) -> ())?) {
        ethereumKit.send(to: address, value: value, gasPrice: nil, completion: completion)
    }

    func fee(for value: Decimal, address: String?, senderPay: Bool) throws -> Decimal {
        let fee = ethereumKit.fee
        if balance > 0, balance - value - fee < 0 {
            throw FeeError.insufficientAmount(fee: fee)
        }
        return fee
    }

}

extension EthereumAdapter: EthereumKitDelegate {

}
