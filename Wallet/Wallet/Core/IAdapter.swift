import Foundation
import RxSwift

protocol IAdapter {
    var id: String { get }

    var coin: Coin { get }

    var balance: Double { get }
    var balanceSubject: PublishSubject<Double> { get }

    var progressSubject: BehaviorSubject<Double> { get }

    var latestBlockHeight: Int { get }
    var latestBlockHeightSubject: PublishSubject<Void> { get }

    var transactionRecords: [TransactionRecord] { get }
    var transactionRecordsSubject: PublishSubject<Void> { get }

    func showInfo()
    func start() throws
    func send(to address: String, value: Int) throws
    func fee(for value: Int, senderPay: Bool) throws -> Int
    func validate(address: String) -> Bool
}
