import Combine
import MarketKit
import SwiftUI

public protocol ITransactionService {
    var transactionSettings: TransactionSettings? { get }
    var modified: Bool { get }
    var cautions: [CautionNew] { get }
    var updatePublisher: AnyPublisher<Void, Never> { get }
    func sync() async throws
}
