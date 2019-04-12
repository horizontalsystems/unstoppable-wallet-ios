import HSEthereumKit
import RxSwift

class Erc20Adapter: EthereumBaseAdapter {
    let contractAddress: String
    let feeCoinCode: CoinCode? = "ETH"

    init(coin: Coin, ethereumKit: EthereumKit, contractAddress: String, decimal: Int, addressParser: IAddressParser, feeRateProvider: IFeeRateProvider) {
        self.contractAddress = EIP55.format(contractAddress)

        super.init(coin: coin, ethereumKit: ethereumKit, decimal: decimal, addressParser: addressParser, feeRateProvider: feeRateProvider)

        ethereumKit.register(contractAddress: contractAddress, delegate: self)
    }

    override func transactionsObservable(hashFrom: String?, limit: Int) -> Single<[EthereumTransaction]> {
        return ethereumKit.transactionsErc20Single(contractAddress: contractAddress, fromHash: hashFrom, limit: limit)
    }

    override func sendSingle(to address: String, amount: String, gasPrice: Int) -> Single<Void> {
        return ethereumKit.sendErc20Single(to: address, contractAddress: contractAddress, amount: amount, gasPriceInWei: gasPrice)
                .map { _ in ()}
                .catchError { [weak self] error in
                    return Single.error(self?.createSendError(from: error) ?? error)
                }
    }

}

extension Erc20Adapter: IAdapter {

    func stop() {
        ethereumKit.unregister(contractAddress: contractAddress)
    }

    var balance: Decimal {
        return balanceDecimal(balanceString: ethereumKit.balanceErc20(contractAddress: contractAddress), decimal: decimal)
    }

    func refresh() {
        ethereumKit.start()
    }

    func availableBalance(for address: String?, feeRatePriority: FeeRatePriority) -> Decimal {
        return balance
    }

    func fee(for value: Decimal, address: String?, feeRatePriority: FeeRatePriority) -> Decimal {
        return ethereumKit.feeErc20(gasPriceInWei: feeRateProvider.ethereumGasPrice(for: feeRatePriority)) / pow(10, EthereumAdapter.decimal)
    }

    func validate(amount: Decimal, address: String?, feeRatePriority: FeeRatePriority) -> [SendStateError] {
        var errors = [SendStateError]()
        if amount > availableBalance(for: address, feeRatePriority: feeRatePriority) {
            errors.append(.insufficientAmount)
        }

        let ethereumBalance = balanceDecimal(balanceString: ethereumKit.balance, decimal: EthereumAdapter.decimal)

        if ethereumBalance < fee(for: amount, address: address, feeRatePriority: feeRatePriority) {
            errors.append(.insufficientFeeBalance)
        }
        return errors
    }

}

extension Erc20Adapter: IEthereumKitDelegate {

}
