import HSEthereumKit
import RxSwift

class Erc20Adapter: EthereumBaseAdapter {
    let contractAddress: String
    let feeCoinCode: CoinCode? = "ETH"

    init(coin: Coin, ethereumKit: EthereumKit, contractAddress: String, decimal: Int) {
        self.contractAddress = EIP55.format(contractAddress)

        super.init(coin: coin, ethereumKit: ethereumKit, decimal: decimal)

        ethereumKit.register(contractAddress: contractAddress, decimal: decimal, delegate: self)
    }

    override func transactionsObservable(hashFrom: String?, limit: Int) -> Single<[EthereumTransaction]> {
        return ethereumKit.transactionsErc20Single(contractAddress: contractAddress, fromHash: hashFrom, limit: limit)
    }

}

extension Erc20Adapter: IAdapter {

    func stop() {
        ethereumKit.unregister(contractAddress: contractAddress)
    }

    var balance: Decimal {
        return ethereumKit.balanceErc20(contractAddress: contractAddress)
    }

    func refresh() {
        ethereumKit.start()
    }

    func sendSingle(to address: String, amount: Decimal) -> Single<Void> {
        let formattedAmount = ValueFormatter.instance.round(value: amount, scale: decimal, roundingMode: .plain)
        return ethereumKit.sendErc20Single(to: address, contractAddress: contractAddress, amount: formattedAmount)
                .map { _ in ()}
    }

    func availableBalance(for address: String?) -> Decimal {
        return balance
    }

    func fee(for value: Decimal, address: String?) -> Decimal {
        return ethereumKit.feeErc20()
    }

    func validate(amount: Decimal, address: String?) -> [SendStateError] {
        var errors = [SendStateError]()
        if amount > availableBalance(for: address) {
            errors.append(.insufficientAmount)
        }
        if ethereumKit.balance < fee(for: amount, address: address) {
            errors.append(.insufficientFeeBalance)
        }
        return errors
    }

}

extension Erc20Adapter: IEthereumKitDelegate {

}
