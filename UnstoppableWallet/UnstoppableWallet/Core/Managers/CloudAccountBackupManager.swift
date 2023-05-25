import Foundation
import HsToolKit

class CloudAccountBackupManager {
    private let ubiquityContainerIdentifier: String
    private let fileStorage: FileStorage

    var iCloudUrl: URL? {
        FileManager
                .default
                .url(forUbiquityContainerIdentifier: ubiquityContainerIdentifier)?
                .appendingPathComponent("Documents")
    }

    init(ubiquityContainerIdentifier: String, logger: Logger?) {
        self.ubiquityContainerIdentifier = ubiquityContainerIdentifier

        fileStorage = FileStorage(logger: logger)
    }

}

extension CloudAccountBackupManager {

    func backedUp(accountId: Data) async throws -> Bool {
        false
    }

    var existFilenames: [String] {
        []
    }

}

extension CloudAccountBackupManager {

    func checkAvailable() async throws {
        if iCloudUrl == nil {
            throw BackupError.urlNotAvailable
        }
    }

    func save(accountType: AccountType, passphrase: String, name: String) async throws {
        guard let iCloudUrl else {
            throw BackupError.urlNotAvailable
        }

        print("icloudUrl: \(iCloudUrl.path)")

        do {
            let encoded = try WalletBackupConverter.encode(accountType: accountType, passphrase: passphrase)
//            let json = encoded.hs.to(type: String.self)

            try await fileStorage.write(directoryUrl: iCloudUrl, filename: name, data: encoded)
        } catch {
            print("ERROR: \(error)")
        }

    }

    func delete(uid: Data) async throws -> AccountType {
        fatalError("delete(uid:) has not been implemented")
    }

}

extension CloudAccountBackupManager {

        enum BackupError: Error {
            case urlNotAvailable
        }

}
