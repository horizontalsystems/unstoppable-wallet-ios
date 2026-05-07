import EvmKit
import Foundation
import MarketKit
import MoneroKit

class MoneroFeeSettingsViewModel: ObservableObject {
    private let service: MoneroTransactionService
    private let amount: MoneroSendAmount
    private let address: String

    @Published var priorityCautionState: FieldCautionState = .none
    @Published var resetEnabled = false
    @Published var applyEnabled = false

    @Published var fee: Decimal?
    @Published var priority: MoneroKit.SendPriority {
        didSet {
            sync()
        }
    }

    init(service: MoneroTransactionService, amount: MoneroSendAmount, address: String) {
        self.service = service
        self.amount = amount
        self.address = address

        priority = service.priority

        sync()
    }

    private func sync() {
        fee = try? service.resolveFee(amount: amount, address: address, priority: priority)

        applyEnabled = service.priority != priority
        resetEnabled = priority != .default
    }
}

extension MoneroFeeSettingsViewModel {
    func onReset() {
        priority = .default
        sync()
    }

    func apply() {
        service.set(priority: priority)
    }
}
