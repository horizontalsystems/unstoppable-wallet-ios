import Foundation

protocol IAdapter {
    var listener: IAdapterListener? { get set }
    func showInfo()
    func start() throws
    func send(to address: String, amount: Int)
}

protocol IAdapterListener: class {
    func handle(transactionRecords: [TransactionRecord])
}
