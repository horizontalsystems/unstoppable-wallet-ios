import EvmKit
import Foundation
import MarketKit
import MoneroKit

class MoneroFeeSettingsViewModel: ObservableObject {
    let service: MoneroTransactionService

    init(service: MoneroTransactionService) {
        self.service = service
        priority = SendPriority.default.description

        syncFromService()
    }

    @Published var priority: String = "" {
        didSet {
            DispatchQueue.main.async { [weak self] in
                self?.handle()
            }
        }
    }

    @Published var priorityCautionState: FieldCautionState = .none
    @Published var resetEnabled = false

    private func syncFromService() {
        if let priority = service.priority {
            self.priority = priority.description
        }

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

    private func handle() {
        guard let priorityEnum = SendPriority.from(string: priority) else {
            priorityCautionState = .caution(.error)
            return
        }

        service.set(priority: priorityEnum)
        sync()
    }
}

extension MoneroFeeSettingsViewModel {
    func set(priorityAtIndex: Int) {
        if let newValue = SendPriority(rawValue: priorityAtIndex) {
            priority = newValue.description
        }
    }

    func onReset() {
        service.useRecommended()
        syncFromService()
    }
}
