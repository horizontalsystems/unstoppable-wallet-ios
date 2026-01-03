import EvmKit
import Foundation
import MarketKit
import SwiftUI

class TransactionNonceViewModel: ObservableObject {
    let service: EvmTransactionService

    @Published var nonceCautionState: FieldCautionState = .none
    @Published var applyEnabled = false
    @Published var resetEnabled = false
    @Published var cautions = [CautionNew]()

    @Published var txNonce: Int? {
        didSet {
            sync()
        }
    }

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
        txNonce = service.currentNonce

        if let txNonce {
            _nonce = txNonce.description
        }
    }

    private func sync() {
        applyEnabled = service.currentNonce != txNonce
        resetEnabled = service.nextNonce != txNonce

        let errors = EvmTransactionService.validateNonce(nonce: txNonce, minimumNonce: service.minimumNonce)
        cautions = errors.map(\.caution)

        if !errors.isEmpty {
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

        txNonce = intNonce
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
        guard let nextNonce = service.nextNonce else {
            return
        }

        _nonce = nextNonce.description
        handleChange()
    }

    func apply() {
        guard let txNonce, let nextNonce = service.nextNonce else {
            return
        }

        service.set(nonce: txNonce == nextNonce ? nil : txNonce)
    }
}
