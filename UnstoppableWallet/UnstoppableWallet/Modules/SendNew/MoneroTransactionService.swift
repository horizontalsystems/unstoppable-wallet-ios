import Combine
import MarketKit
import MoneroKit
import SwiftUI

class MoneroTransactionService {
    private let adapter: MoneroAdapter

    private(set) var priority: SendPriority = .default
    private let updateSubject = PassthroughSubject<Void, Never>()

    init(adapter: MoneroAdapter) {
        self.adapter = adapter
    }
}

extension MoneroTransactionService {
    func resolveFee(amount: MoneroSendAmount, address: String, priority: SendPriority) throws -> Decimal {
        try adapter.estimateFee(amount: amount, address: address, priority: priority)
    }

    func set(priority: SendPriority) {
        self.priority = priority
        updateSubject.send()
    }
}

extension MoneroTransactionService: ITransactionService {
    var transactionSettings: TransactionSettings? {
        .monero(priority: priority)
    }

    var modified: Bool {
        priority != .default
    }

    var cautions: [CautionNew] {
        []
    }

    var updatePublisher: AnyPublisher<Void, Never> {
        updateSubject.eraseToAnyPublisher()
    }

    func sync() async throws {}
}
