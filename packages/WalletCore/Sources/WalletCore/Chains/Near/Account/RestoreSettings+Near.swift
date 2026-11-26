import NearKit

extension RestoreSettings {
    /// The NEAR account a restored phrase opens instead of its implicit one. An id that is not a NEAR
    /// account (a hand-edited backup) is ignored, so the wallet still opens on the implicit account.
    var nearAccountId: String? {
        self[.nearAccountId].flatMap { NearKit.Kit.isValid(accountId: $0) ? $0 : nil }
    }
}
