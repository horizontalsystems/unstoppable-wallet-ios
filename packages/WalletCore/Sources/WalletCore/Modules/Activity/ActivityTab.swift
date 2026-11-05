import Foundation

enum ActivityTab: String, CaseIterable {
    case transfer
    case swap
    case privateSend = "private_send"
    case crossPay = "cross_pay"

    var title: String {
        "activity.tab.\(rawValue)".localized
    }

    /// nil for the on-chain transfer list, the swap record kinds for the other tabs
    var operations: [Swap.Operation]? {
        switch self {
        case .transfer: nil
        case .swap: [.swap, .splitSwap]
        case .privateSend: [.privateSend]
        case .crossPay: [.crossPay]
        }
    }

    var emptyText: String {
        "activity.empty.\(rawValue)".localized
    }
}
