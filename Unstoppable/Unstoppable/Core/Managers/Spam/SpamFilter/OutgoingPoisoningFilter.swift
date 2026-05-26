import Foundation
import HsToolKit
import WalletCore

final class OutgoingPoisoningFilter: SpamFilter {
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

        // if somebody transfer from your wallet some token, which you don't add as wallet (like phising token) mark it spam
        if transaction.events.outgoing.contains(where: { event in
            event.value.kind is RawAppValue || event.value.kind is Eip20TokenAppValue
        }) {
            return .spam
        }

        // if somebody transfer from your wallet some zero value eip20 token. Mark it spam
        if transaction.events.outgoing.contains(where: \.value.zeroValue) {
            return .spam
        }

        return .ignore
    }
}
