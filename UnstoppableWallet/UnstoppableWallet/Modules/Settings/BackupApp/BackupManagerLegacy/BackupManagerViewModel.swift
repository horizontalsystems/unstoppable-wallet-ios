import Combine

class BackupManagerViewModel {
    private let passcodeManager: PasscodeManager

    private let openUnlockSubject = PassthroughSubject<Void, Never>()
    private let openBackupSubject = PassthroughSubject<Void, Never>()

    init(passcodeManager: PasscodeManager) {
        self.passcodeManager = passcodeManager
    }
}

extension BackupManagerViewModel {
    var openUnlockPublisher: AnyPublisher<Void, Never> {
        openUnlockSubject.eraseToAnyPublisher()
    }

    var openBackupPublisher: AnyPublisher<Void, Never> {
        openBackupSubject.eraseToAnyPublisher()
    }

    func onTapBackup() {
        if passcodeManager.isPasscodeSet {
            openUnlockSubject.send()
        } else {
            openBackupSubject.send()
        }
    }

    func unlock() {
        openBackupSubject.send()
    }
}
