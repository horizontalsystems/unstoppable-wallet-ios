class Account {
    let id: String
    var name: String
    let type: AccountType
    let origin: AccountOrigin
    var backedUp: Bool

    init(id: String, name: String, type: AccountType, origin: AccountOrigin, backedUp: Bool) {
        self.id = id
        self.name = name
        self.type = type
        self.origin = origin
        self.backedUp = backedUp
    }

}

extension Account: Hashable {

    public static func ==(lhs: Account, rhs: Account) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

}

enum AccountOrigin: String {
    case created
    case restored
}
