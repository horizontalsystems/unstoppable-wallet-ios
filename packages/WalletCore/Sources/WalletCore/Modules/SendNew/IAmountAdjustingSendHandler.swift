public protocol IAmountAdjustingSendHandler: AnyObject {
    /// Some handlers silently reduce the transfer amount to fit the balance. A caller that
    /// requires the amount to be sent EXACTLY as given sets this to false, and the handler
    /// must then report insufficient balance instead of adjusting.
    var allowsAmountAdjustment: Bool { get set }
}
