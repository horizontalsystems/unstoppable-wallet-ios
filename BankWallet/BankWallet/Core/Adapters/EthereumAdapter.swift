import HSEthereumKit
import RxSwift

class EthereumAdapter: EthereumBaseAdapter {

    init(coin: Coin, ethereumKit: EthereumKit) {
        super.init(coin: coin, ethereumKit: ethereumKit, decimal: 18)

        ethereumKit.delegate = self
    }

    override func transactionsObservable(hashFrom: String?, limit: Int) -> Single<[EthereumTransaction]> {
        return ethereumKit.transactionsSingle(fromHash: hashFrom, limit: limit)
    }

}

extension EthereumAdapter: IAdapter {

    func stop() {
    }

    var balance: Decimal {
        return ethereumKit.balance
    }

    func refresh() {
        ethereumKit.start()
    }

    func sendSingle(to address: String, amount: Decimal) -> Single<Void> {
        let formattedAmount = ValueFormatter.instance.round(value: amount, scale: decimal, roundingMode: .plain)
        return ethereumKit.sendSingle(to: address, amount: formattedAmount)
                .map { _ in ()}
    }

    func availableBalance(for address: String?) -> Decimal {
        return max(0, balance - fee(for: balance, address: address))
    }

    func fee(for value: Decimal, address: String?) -> Decimal {
        return ethereumKit.fee()
    }

    func validate(amount: Decimal, address: String?) -> [SendStateError] {
        var errors = [SendStateError]()
        if amount > availableBalance(for: address) {
            errors.append(.insufficientAmount)
        }
        return errors
    }

}

extension EthereumAdapter: IEthereumKitDelegate {

}
