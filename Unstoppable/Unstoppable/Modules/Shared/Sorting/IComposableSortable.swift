import Foundation

protocol IComposableSortable {
    associatedtype Context
    static func compare(_ lhs: Self, _ rhs: Self, by criterion: SortCriterion, context: Context) -> ComparisonResult
}

extension Array where Element: IComposableSortable {
    func sorted(by criteria: [SortCriterion], context: Element.Context) -> [Element] {
        sorted { lhs, rhs in
            for criterion in criteria {
                let result = Element.compare(lhs, rhs, by: criterion, context: context)
                if result != .orderedSame {
                    return result == .orderedAscending
                }
            }
            return false
        }
    }
}

extension Array where Element: IComposableSortable, Element.Context == Void {
    func sorted(by criteria: [SortCriterion]) -> [Element] {
        sorted(by: criteria, context: ())
    }
}
