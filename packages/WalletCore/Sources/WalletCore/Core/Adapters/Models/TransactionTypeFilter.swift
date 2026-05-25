import Foundation

public enum TransactionTypeFilter: String, CaseIterable {
    case all, incoming, outgoing, swap, approve
}
