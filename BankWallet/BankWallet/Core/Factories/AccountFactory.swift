import Foundation

class AccountFactory {

    func account(type: AccountType, backedUp: Bool, defaultSyncMode: SyncMode?) -> Account {
        let id = UUID().uuidString

        return Account(
                id: id,
                name: id,
                type: type,
                backedUp: backedUp,
                defaultSyncMode: defaultSyncMode
        )
    }

}
