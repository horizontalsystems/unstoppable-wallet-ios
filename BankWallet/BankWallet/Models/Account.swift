struct Account {
    let id: String
    let name: String
    let type: AccountType
    var backedUp: Bool
    let defaultSyncMode: SyncMode
}

extension Account: Equatable {

    public static func ==(lhs: Account, rhs: Account) -> Bool {
        return lhs.id == rhs.id
    }

}
