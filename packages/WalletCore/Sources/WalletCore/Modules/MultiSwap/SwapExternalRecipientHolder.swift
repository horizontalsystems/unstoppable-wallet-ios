import Foundation

/// Shared owner of the external delivery address for swaps whose tokenOut the account can't
/// hold. The swap screen writes it from the pre-confirmation recipient page and the
/// confirmation handler writes it from the Set Recipient sheet; both read the same box, so a
/// recipient corrected on the confirmation screen survives leaving and re-entering it.
///
/// A reference type on purpose: the handler is built from a `SendData` value deep inside the
/// send flow and has no way back to the swap view model.
public final class SwapExternalRecipientHolder: @unchecked Sendable {
    private let lock = NSLock()
    private var _address: String?

    public init() {}

    public var address: String? {
        get { lock.withLock { _address } }
        set { lock.withLock { _address = newValue } }
    }
}
