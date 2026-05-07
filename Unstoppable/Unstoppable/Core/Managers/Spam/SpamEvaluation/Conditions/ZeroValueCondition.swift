import Foundation
import HsToolKit

class ZeroValueCondition: SpamCondition {
    var identifier: String { "zero_value" }

    private let score: Int
    private let logger: Logger?

    init(score: Int = 4, logger: Logger? = nil) {
        self.score = score
        self.logger = logger
    }

    func evaluate(_ context: SpamEvaluationContext) -> Int {
        let hasZeroValueIncoming = context.transaction.events.incoming.contains { $0.value.zeroValue }

        if hasZeroValueIncoming {
            return score
        }

        return 0
    }
}
