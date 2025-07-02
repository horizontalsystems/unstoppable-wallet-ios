import Combine

class BackupManagerViewModel: ObservableObject {
    private let passcodeManager = Core.shared.passcodeManager
}

extension BackupManagerViewModel {
    var unlockRequired: Bool {
        passcodeManager.isPasscodeSet
    }
}
