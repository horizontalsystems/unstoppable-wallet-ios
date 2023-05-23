import Foundation
import Combine
import HsExtensions

class ICloudBackupTermsService {
    let account: Account
    let termCount = 2

    @PostPublished private(set) var state: State = .selectedTerms(Set())

    init(account: Account) {
        self.account = account
    }

}

extension ICloudBackupTermsService {

    // 1. Terms Screen
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
