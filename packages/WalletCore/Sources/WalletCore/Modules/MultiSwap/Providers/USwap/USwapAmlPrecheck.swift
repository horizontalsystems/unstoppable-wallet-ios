import Foundation

/// The AML address precheck is route-driven: a route carries `amlProviderId` when and only when it has
/// one, and the app passes the value verbatim to `GET /v3/check-addresses`. It checks the SENDER
/// addresses only — never the recipient, a refund address or a generated destination. No provider id
/// lives here.
enum USwapAmlPrecheck {
    static func isRequired(amlProviderId: String?) -> Bool {
        amlProviderId.map { !$0.isEmpty } ?? false
    }

    /// The sender addresses (the UTXOs or account that fund the deposit), trimmed, without duplicates,
    /// in the order given. Empty when the sender cannot be determined — the caller treats that as
    /// inconclusive, never as a pass.
    static func addresses(sender: [String]) -> [String] {
        var seen = Set<String>()
        var result = [String]()

        for address in sender {
            let trimmed = address.trimmingCharacters(in: .whitespacesAndNewlines)

            guard !trimmed.isEmpty, seen.insert(trimmed).inserted else {
                continue
            }

            result.append(trimmed)
        }

        return result
    }
}
