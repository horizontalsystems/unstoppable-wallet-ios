import Foundation
import RxSwift

protocol IAdapter {
    var listener: IAdapterListener? { get set }

    var id: String { get }

    var coin: Coin { get }

    var balance: Double { get }
    var balanceSubject: PublishSubject<Double> { get }

    var progressSubject: BehaviorSubject<Double> { get }

    func showInfo()
    func start() throws
    func send(to address: String, value: Int) throws
    func fee(for value: Int, senderPay: Bool) throws -> Int
    func validate(address: String) -> Bool
}

protocol IAdapterListener: class {
    func handle(transactionRecords: [TransactionRecord])
}
