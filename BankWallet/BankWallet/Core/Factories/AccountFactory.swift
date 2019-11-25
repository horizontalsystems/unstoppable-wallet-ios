import Foundation

class AccountFactory: IAccountFactory {

    func account(type: AccountType, origin: AccountOrigin, backedUp: Bool) -> Account {
        let id = UUID().uuidString

        return Account(
                id: id,
                name: id,
                type: type,
                origin: origin,
                backedUp: backedUp
        )
    }

}
