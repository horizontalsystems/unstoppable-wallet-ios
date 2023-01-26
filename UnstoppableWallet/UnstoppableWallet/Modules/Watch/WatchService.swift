import Foundation

class WatchService {
    private let accountFactory: AccountFactory

    private(set) var name: String?

    init(accountFactory: AccountFactory) {
        self.accountFactory = accountFactory
    }

}

extension WatchService {

    var defaultAccountName: String {
        accountFactory.nextWatchAccountName
    }

    var resolvedName: String {
        let trimmedName = (name ?? defaultAccountName).trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedName
    }

    func set(name: String) {
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            self.name = nil
        } else {
            self.name = name
        }
    }

}
