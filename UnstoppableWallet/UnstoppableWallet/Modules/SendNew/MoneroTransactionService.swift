import Combine
import MarketKit
import MoneroKit
import SwiftUI

class MoneroTransactionService: ITransactionService {
    private(set) var usingRecommended: Bool = true
    private(set) var cautions: [CautionNew] = []
    private(set) var priority: SendPriority?

    private let updateSubject = PassthroughSubject<Void, Never>()

    var transactionSettings: TransactionSettings? {
        guard let priority else {
            return nil
        }

        return .monero(priority: priority)
    }

    var modified: Bool {
        !usingRecommended
    }

    var updatePublisher: AnyPublisher<Void, Never> {
        updateSubject.eraseToAnyPublisher()
    }

    init() {}

    func sync() async throws {
        if usingRecommended {
            priority = .default
        }
    }

    func settingsView(feeData: Binding<FeeData?>, loading: Binding<Bool>, feeToken: MarketKit.Token, currency: Currency, feeTokenRate: Binding<Decimal?>) -> AnyView? {
        let view = MoneroFeeSettingsView(
            service: self,
            feeData: feeData,
            loading: loading,
            feeToken: feeToken,
            currency: currency,
            feeTokenRate: feeTokenRate
        )

        return AnyView(ThemeNavigationStack { view })
    }

    func set(priority: SendPriority) {
        self.priority = priority
        usingRecommended = (priority == .default)

        updateSubject.send()
    }

    func useRecommended() {
        priority = .default
        usingRecommended = true
        updateSubject.send()
    }
}
