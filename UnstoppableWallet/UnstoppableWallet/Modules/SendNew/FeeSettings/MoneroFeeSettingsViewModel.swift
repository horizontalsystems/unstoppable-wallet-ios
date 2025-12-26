import EvmKit
import Foundation
import MarketKit
import MoneroKit

class MoneroFeeSettingsViewModel: ObservableObject {
    let service: MoneroTransactionService

    @Published var priority: SendPriority
    @Published var priorityCautionState: FieldCautionState = .none
    @Published var resetEnabled = false

    init(service: MoneroTransactionService) {
        self.service = service
        priority = service.priority ?? SendPriority.default
        sync()
    }

    private func sync() {
        resetEnabled = service.modified

        if let caution = service.cautions.first {
            priorityCautionState = .caution(caution.type)
        } else {
            priorityCautionState = .none
        }
    }
}

extension MoneroFeeSettingsViewModel {
    func set(priority: SendPriority) {
        self.priority = priority
        service.set(priority: priority)
        sync()
    }

    func onReset() {
        service.useRecommended()
        priority = service.priority ?? SendPriority.default
        sync()
    }
}
