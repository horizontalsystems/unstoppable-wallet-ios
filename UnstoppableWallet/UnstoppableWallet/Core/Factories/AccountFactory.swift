import Foundation

class AccountFactory: IAccountFactory {

    func account(type: AccountType, origin: AccountOrigin, backedUp: Bool) -> Account {
        let id = UUID().uuidString
        let name = "Wallet 1" // todo: generate localized and ordered wallet name

        return Account(
                id: id,
                name: name,
                type: type,
                origin: origin,
                backedUp: backedUp
        )
    }

}
