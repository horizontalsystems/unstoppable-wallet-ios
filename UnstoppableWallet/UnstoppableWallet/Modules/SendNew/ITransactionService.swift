import Combine
import MarketKit
import SwiftUI

protocol ITransactionService {
    var transactionSettings: TransactionSettings? { get }
    var modified: Bool { get }
    var cautions: [CautionNew] { get }
    var updatePublisher: AnyPublisher<Void, Never> { get }
    func sync() async throws
    func settingsView(feeData: Binding<FeeData?>, loading: Binding<Bool>, feeToken: Token, currency: Currency, feeTokenRate: Binding<Decimal?>) -> AnyView?
}
