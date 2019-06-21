import Foundation

enum BalanceSortType: String {
    case value
    case az
    case manual
}

struct BalancePresenterState {
    var sort: BalanceSortType = .manual
    var desc: Bool = false
}
