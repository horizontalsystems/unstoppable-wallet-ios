import Combine
import Foundation

class BackupNameViewModel: ObservableObject {
    private let validator: BackupFilenameValidator

    @Published var name: String = "" {
        didSet {
            validate()
        }
    }

    @Published var cautionState: CautionState = .none

    var isValid: Bool {
        if case .none = cautionState, !name.trimmingCharacters(in: .whitespaces).isEmpty {
            return true
        }
        return false
    }

    init(type: BackupModule.BackupType, destination: BackupModule.Destination) {
        validator = BackupFilenameValidator(destination: destination)

        let nameProvider = BackupNameProviderFactory.create(type: type, destination: destination)
        name = nameProvider.defaultName()
    }

    func validate() {
        do {
            try validator.validate(name: name)
            cautionState = .none
        } catch {
            cautionState = .caution(Caution(text: error.localizedDescription, type: .error))
        }
    }
}
