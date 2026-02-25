import Combine
import MarketKit
import SwiftUI

class ZanoTransactionService {
    private let adapter: ZanoAdapter
    private let updateSubject = PassthroughSubject<Void, Never>()

    init(adapter: ZanoAdapter) {
        self.adapter = adapter
    }
}

extension ZanoTransactionService {
    var fee: Decimal {
        adapter.estimateFee()
    }
}

extension ZanoTransactionService: ITransactionService {
    var transactionSettings: TransactionSettings? {
        nil
    }

    var modified: Bool {
        false
    }

    var cautions: [CautionNew] {
        []
    }

    var updatePublisher: AnyPublisher<Void, Never> {
        updateSubject.eraseToAnyPublisher()
    }

    func sync() async throws {}
}
