import EvmKit
import Foundation
import MarketKit
import SwiftUI

class TransactionNonceViewModel: ObservableObject {
    let service: EvmTransactionService

    @Published var nonceCautionState: FieldCautionState = .none
    @Published var resetEnabled = false

    @Published private var _nonce: String = ""
    var nonce: Binding<String> {
        Binding(
            get: { self._nonce },
            set: { newValue in
                self._nonce = newValue
                self.handleChange()
            }
        )
    }

    init(service: EvmTransactionService) {
        self.service = service
        _nonce = service.nonce?.description ?? ""
        sync()
    }

    private func sync() {
        resetEnabled = service.modified

        if service.errors.contains(where: { $0 is NonceService.NonceError }) {
            nonceCautionState = .caution(.error)
        } else {
            nonceCautionState = .none
        }
    }

    private func handleChange() {
        guard let intNonce = Int(_nonce) else {
            nonceCautionState = .caution(.error)
            return
        }

        service.set(nonce: intNonce)
        sync()
    }

    private func updateByStep(value: String?, direction: StepChangeButtonsViewDirection) -> Int? {
        guard let int = value.flatMap({ Int($0) }) else {
            return nil
        }

        switch direction {
        case .down: return max(int - 1, 0)
        case .up: return int + 1
        }
    }
}

extension TransactionNonceViewModel {
    func stepChangeNonce(_ direction: StepChangeButtonsViewDirection) {
        if let newValue = updateByStep(value: _nonce, direction: direction) {
            nonce.wrappedValue = newValue.description
        }
    }

    func onReset() {
        service.useRecommended()
        _nonce = service.nonce?.description ?? ""
        sync()
    }
}
