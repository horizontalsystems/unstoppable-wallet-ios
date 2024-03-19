import Combine
import Foundation
import MarketKit
import UIKit

protocol IMultiSwapSettingsField {
    var syncPublisher: AnyPublisher<Void, Never> { get }
    var state: BaseMultiSwapSettingsViewModel.FieldState { get }

    func onReset()
    func onDone()
}

class BaseMultiSwapSettingsViewModel: ObservableObject {
    private var cancellables = Set<AnyCancellable>()

    var fields: [IMultiSwapSettingsField]

    @Published var resetEnabled = false
    @Published var doneEnabled = false

    init(fields: [IMultiSwapSettingsField]) {
        self.fields = fields

        for field in fields {
            field
                .syncPublisher
                .sink(receiveValue: { [weak self] in self?.syncButtons() })
                .store(in: &cancellables)
        }
    }

    func syncButtons() {
        let states = fields.map(\.state)

        let allValid = states.map(\.valid).allSatisfy { $0 }
        let anyChanged = states.map(\.changed).contains(true)

        doneEnabled = allValid && anyChanged
        resetEnabled = states.map(\.resetEnabled).contains(true)
    }

    func onReset() {
        fields.forEach { $0.onReset() }
    }

    func onDone() {
        fields.forEach { $0.onDone() }
    }
}

extension BaseMultiSwapSettingsViewModel {
    struct FieldState {
        let valid: Bool
        let changed: Bool
        let resetEnabled: Bool
    }
}
