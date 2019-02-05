import HSEthereumKit
import RxSwift

class Erc20Adapter: EthereumBaseAdapter {
    let contractAddress: String

    init(coin: Coin, ethereumKit: EthereumKit, contractAddress: String, decimal: Int) {
        self.contractAddress = contractAddress

        super.init(coin: coin, ethereumKit: ethereumKit, decimal: decimal)

        ethereumKit.register(token: self)
    }

    override func transactionsObservable(hashFrom: String?, limit: Int) -> Single<[EthereumTransaction]> {
        return ethereumKit.erc20Transactions(contractAddress: contractAddress, fromHash: hashFrom, limit: limit)
    }

}

extension Erc20Adapter: IAdapter {

    func stop() {
        ethereumKit.unregister(contractAddress: contractAddress)
    }

    var balance: Decimal {
        return ethereumKit.erc20Balance(contractAddress: contractAddress)
    }

    func refresh() {
        ethereumKit.erc20Refresh(contractAddress: contractAddress)
    }

    func send(to address: String, value: Decimal, completion: ((Error?) -> ())?) {
        ethereumKit.erc20Send(to: address, contractAddress: contractAddress, value: value, gasPrice: nil, completion: completion)
    }

    func fee(for value: Decimal, address: String?, senderPay: Bool) throws -> Decimal {
        let fee =  ethereumKit.erc20Fee
        if ethereumKit.balance > 0, ethereumKit.balance - fee < 0 {
            throw FeeError.insufficientAmount(fee: fee)
        }
        return fee
    }

}

extension Erc20Adapter: Erc20KitDelegate {

}
