import EvmKit
import Foundation
import MarketKit

class BitcoinFeeSettingsViewModel: ObservableObject {
    let service: BitcoinTransactionService

    init(service: BitcoinTransactionService) {
        self.service = service

        if let satoshiPerByte = service.actualFeeRates?.recommended {
            self.satoshiPerByte = satoshiPerByte.description
        }

        syncFromService()
    }

    @Published var satoshiPerByte: String = "" {
        didSet {
            DispatchQueue.main.async { [weak self] in
                self?.handle()
            }
        }
    }

    @Published var satoshiPerByteCautionState: FieldCautionState = .none
    @Published var resetEnabled = false

    private func syncFromService() {
        if let satoshiPerByte = service.satoshiPerByte {
            self.satoshiPerByte = satoshiPerByte.description
        }

        sync()
    }

    private func sync() {
        resetEnabled = service.modified

        if let caution = service.cautions.first {
            satoshiPerByteCautionState = .caution(caution.type)
        } else {
            satoshiPerByteCautionState = .none
        }
    }

    private func handle() {
        guard let satoshiPerByteInt = Int(satoshiPerByte) else {
            satoshiPerByteCautionState = .caution(.error)
            return
        }

        service.set(satoshiPerByte: satoshiPerByteInt)
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

extension BitcoinFeeSettingsViewModel {
    func stepChangesatoshiPerByte(_ direction: StepChangeButtonsViewDirection) {
        if let newValue = updateByStep(value: satoshiPerByte, direction: direction) {
            satoshiPerByte = newValue.description
        }
    }

    func onReset() {
        service.useRecommended()
        syncFromService()
    }
}
