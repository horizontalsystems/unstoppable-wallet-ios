import Foundation
import HsToolKit

final class ZeroValueFilter: SpamFilter {
    var identifier: String { "zero_value_poisoning" }

    private let logger: Logger?

    init(logger: Logger? = nil) {
        self.logger = logger
    }

    func evaluate(_ transaction: SpamTransactionInfo) -> SpamFilterResult {
        guard !transaction.events.isEmpty else {
            return .ignore
        }

        guard !transaction.events.outgoing.isEmpty else {
            return .ignore
        }

        if transaction.events.outgoing.contains(where: \.value.zeroValue) {
            return .spam
        }

        return .ignore
    }
}
