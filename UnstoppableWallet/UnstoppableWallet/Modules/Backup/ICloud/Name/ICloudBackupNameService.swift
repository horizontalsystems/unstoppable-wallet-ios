import Foundation
import Combine
import HsExtensions

class ICloudBackupNameService {
    private let iCloudManager: CloudBackupManager
    let account: Account

    @PostPublished private(set) var state: State = .failure(error: NameError.empty)

    init(iCloudManager: CloudBackupManager, account: Account) {
        self.iCloudManager = iCloudManager
        self.account = account

        set(name: account.name)
    }

}

extension ICloudBackupNameService {

    var initialName: String {
        account.name
    }

    func set(name: String) {
        let name = name.trimmingCharacters(in: NSCharacterSet.whitespaces)

        guard !name.isEmpty else {
            state = .failure(error: NameError.empty)
            return
        }

        if iCloudManager.existFilenames.contains(where: { s in s.lowercased() == name.lowercased() }) {
            state = .failure(error: NameError.alreadyExist)
            return
        }

        state = .success(name: name)
    }

}

extension ICloudBackupNameService {

    enum State {
        case success(name: String)
        case failure(error: Error)
    }

    enum NameError: Error {
        case empty
        case alreadyExist
    }

}
