import Foundation

class RestoreService {
    private let accountFactory: AccountFactory

    var name: String = ""

    init(accountFactory: AccountFactory) {
        self.accountFactory = accountFactory
    }

}

extension RestoreService {

    var defaultAccountName: String {
        accountFactory.nextAccountName
    }

    var resolvedName: String {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedName.isEmpty ? defaultAccountName : trimmedName
    }

}
