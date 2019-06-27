struct Account {
    let name: String
    let type: AccountType
}

extension Account: Equatable {

    public static func ==(lhs: Account, rhs: Account) -> Bool {
        return lhs.name == rhs.name && lhs.type == rhs.type
    }

}
