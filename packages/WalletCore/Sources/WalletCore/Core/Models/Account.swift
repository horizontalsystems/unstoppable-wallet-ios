import Foundation

public class Account: Identifiable {
    public let id: String
    public var level: Int
    public var name: String
    public let type: AccountType
    public let origin: AccountOrigin
    public var backedUp: Bool
    public var fileBackedUp: Bool

    public init(id: String, level: Int, name: String, type: AccountType, origin: AccountOrigin, backedUp: Bool, fileBackedUp: Bool) {
        self.id = id
        self.level = level
        self.name = name
        self.type = type
        self.origin = origin
        self.backedUp = backedUp
        self.fileBackedUp = fileBackedUp
    }
}

extension Account: Hashable {
    public static func == (lhs: Account, rhs: Account) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

public enum AccountOrigin: String {
    case created
    case restored
}
