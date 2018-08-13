import Foundation

protocol IAdapter {
    var listener: IAdapterListener? { get set }
    func showInfo()
    func start() throws
}

protocol IAdapterListener: class {
    func handle(transactionRecords: [TransactionRecord])
}
