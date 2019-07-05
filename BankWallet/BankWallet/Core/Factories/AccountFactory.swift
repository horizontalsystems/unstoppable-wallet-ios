import Foundation

class AccountFactory: IAccountFactory {

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
