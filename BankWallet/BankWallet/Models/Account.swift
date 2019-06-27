struct Account {
    let name: String
    let type: AccountType
    let uniqueId: String
    let defaultSyncMode: SyncMode
}

extension Account: Equatable {

    public static func ==(lhs: Account, rhs: Account) -> Bool {
        return lhs.name == rhs.name && lhs.uniqueId == rhs.uniqueId
    }

}
