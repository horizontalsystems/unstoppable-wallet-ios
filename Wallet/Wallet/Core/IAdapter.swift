import Foundation

protocol IAdapter {
    var listener: IAdapterListener? { get set }

    var coin: Coin { get }
    var balance: Int { get }

    func showInfo()
    func start() throws
    func send(to address: String, value: Int) throws
    func validate(address: String) -> Bool
}

protocol IAdapterListener: class {
    func updateBalance()
    func handle(transactionRecords: [TransactionRecord])
}
