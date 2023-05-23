import Foundation

class ICloudBackupPassphraseService {
    private let minimumPassphraseLength = 8
    private let account: Account
    private let name: String

    var passphrase: String = ""
    var passphraseConfirmation: String = ""

    init(account: Account, name: String) {
        self.account = account
        self.name = name
    }

}

extension ICloudBackupPassphraseService {

    func validate(text: String?) -> Bool {
        PassphraseValidator.validate(text: text)
    }

    func createBackup() throws {
        guard !passphrase.isEmpty else {
            throw CreateError.emptyPassphrase
        }

        guard passphrase.count >= minimumPassphraseLength else {
            throw CreateError.tooShort
        }

        guard passphrase == passphraseConfirmation else {
            throw CreateError.invalidConfirmation
        }
    }

}

extension ICloudBackupPassphraseService {

    enum CreateError: Error {
        case emptyPassphrase
        case tooShort
        case invalidConfirmation
    }

}
