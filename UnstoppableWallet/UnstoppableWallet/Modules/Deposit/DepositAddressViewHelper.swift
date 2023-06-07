import Foundation

class DepositAddressViewHelper {
    let testNet: Bool

    init(testNet: Bool) {
        self.testNet = testNet
    }

    var fields: [String] {
        if testNet {
            return ["TestNet"]
        }
        return []
    }

    var additionalInfo: AdditionalInfo {
        if fields.isEmpty {
            return .none
        }
        return .plain(text: fields.joined(separator: ", "))
    }

}


extension DepositAddressViewHelper {

    enum AdditionalInfo {
        case none
        case plain(text: String)
        case warning(text: String, descriptionTitle: String, description: String)

        var text: String? {
            switch self {
            case .none: return nil
            case .plain(let text): return text
            case .warning(let text, _, _): return text
            }
        }
    }

    class Derivation: DepositAddressViewHelper {
        private let mnemonicDerivation: MnemonicDerivation

        init(testNet: Bool, mnemonicDerivation: MnemonicDerivation) {
            self.mnemonicDerivation = mnemonicDerivation
            super.init(testNet: testNet)
        }

        override var fields: [String] {
            [mnemonicDerivation.addressType] + super.fields
        }
    }

    class Activated: DepositAddressViewHelper {
        private let isActive: Bool

        init(testNet: Bool, isActive: Bool) {
            self.isActive = isActive
            super.init(testNet: testNet)
        }

        override var fields: [String] {
            super.fields + (isActive ? [] : ["deposit.not_active".localized])
        }

        override var additionalInfo: AdditionalInfo {
            if !isActive {
                return .warning(
                        text: fields.joined(separator: ", "),
                        descriptionTitle: "deposit.not_active.title".localized,
                        description: "deposit.not_active.tron_description".localized)
            }

            return super.additionalInfo
        }

    }

}
