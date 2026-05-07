import Foundation
import HsToolKit

final class SpamFilterChain {
    private var filters: [SpamFilter]
    private let logger: Logger?

    init(filters: [SpamFilter] = [], logger: Logger? = nil) {
        self.filters = filters
        self.logger = logger
    }

    @discardableResult
    func append(_ filter: SpamFilter) -> Self {
        filters.append(filter)
        return self
    }

    func evaluate(_ transaction: SpamTransactionInfo) -> SpamFilterResult? {
        for filter in filters {
            let result = filter.evaluate(transaction)

            switch result {
            case .ignore:
                continue
            case .spam, .trusted:
                return result
            }
        }

        return nil
    }
}
