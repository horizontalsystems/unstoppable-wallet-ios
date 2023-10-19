import Foundation
import Combine
import HsExtensions

class ICloudBackupTermsService {
    let account: Account
    let termCount = 1

    private let cloudAccountBackupManager: CloudBackupManager

    @PostPublished private(set) var state: State = .selectedTerms(Set())

    init(cloudAccountBackupManager: CloudBackupManager, account: Account) {
        self.account = account
        self.cloudAccountBackupManager = cloudAccountBackupManager
    }

}

extension ICloudBackupTermsService {

    var cloudIsAvailable: Bool {
        cloudAccountBackupManager.isAvailable
    }

    func toggleTerm(at index: Int) {
        guard case .selectedTerms(var checkedIndices) = state,
              index < termCount else {
            return
        }

        if checkedIndices.contains(index) {
            checkedIndices.remove(index)
        } else {
            checkedIndices.insert(index)
        }

        state = .selectedTerms(checkedIndices)
    }

}

extension ICloudBackupTermsService {

    enum State {
        case iCloudNotAvailable
        case selectedTerms(Set<Int>)
    }

}
